import sys
import csv
import re
import os
import oracledb
import getpass
from . import oraclevalidate
import importlib

def normalize(s):
    return ''.join(c for c in s.lower() if c.isalnum())

def is_null_like(s):
    return s is None or s.strip().lower() == 'null' or s.strip() == ''

def remove_aliases_in_where_clause(query):
    pattern = re.compile(r'(where\b.*?)(order\s+by\b|group\s+by\b|$)', re.IGNORECASE | re.DOTALL)

    def remove_aliases(where_clause):
        return re.sub(r'\s+AS\s+\w+', '', where_clause, flags=re.IGNORECASE)

    def replacer(match):
        where_part = remove_aliases(match.group(1))
        return where_part + match.group(2)

    return pattern.sub(replacer, query)

def add_missing_aliases(query):
    query = re.sub(r'\bUPPER\s*\(\s*VALUE\s*\)(?!\s+AS\s+\w+)', 'UPPER(VALUE) AS value', query, flags=re.IGNORECASE)
    query = re.sub(r'\bUPPER\s*\(\s*V\.VALUE\s*\)(?!\s+AS\s+\w+)', 'UPPER(V.VALUE) AS value', query, flags=re.IGNORECASE)

    def is_standalone_decode(text, i):
        return text[i:i+6].upper() == 'DECODE' and (i == 0 or not (text[i-1].isalnum() or text[i-1] == '_'))

    def fix_decode_aliases(text):
        result, i, depth = [], 0, 0
        while i < len(text):
            if text[i] == '(':
                depth += 1
                result.append(text[i])
                i += 1
                continue
            elif text[i] == ')':
                depth -= 1
                result.append(text[i])
                i += 1
                continue
            if is_standalone_decode(text, i) and depth == 0:
                decode_start = i
                i += 6
                while i < len(text) and text[i].isspace():
                    i += 1
                if i >= len(text) or text[i] != '(':
                    result.append('DECODE')
                    continue
                i += 1
                inner_depth = 1
                decode_body = ['DECODE(']
                while i < len(text) and inner_depth > 0:
                    if text[i] == '(':
                        inner_depth += 1
                    elif text[i] == ')':
                        inner_depth -= 1
                    decode_body.append(text[i])
                    i += 1
                full_decode = ''.join(decode_body)
                after_decode = text[i:]
                if not re.match(r'^\s+AS\s+db_name\b', after_decode, re.IGNORECASE) and not re.match(r'^\s*=', after_decode):
                    after_candidate = after_decode.lstrip()
                    next_word_match = re.match(r'^(\w+)', after_candidate)
                    next_word = next_word_match.group(1).upper() if next_word_match else ''
                    if next_word in ('FROM', ')', '') or not next_word.isidentifier():
                        full_decode += ' AS db_name'
                result.append(full_decode)
                continue
            else:
                result.append(text[i])
                i += 1
        return ''.join(result)

    query = fix_decode_aliases(query)

    # --- START: Added fix for CTE union alias error ---
    # This section specifically targets queries with CTEs like DIRECT_PRIVS and INDIRECT_PRIVS
    # that are later UNIONed. It now ONLY adds an alias for the 'HOW_GRANTED' column.
    if 'DIRECT_PRIVS AS' in query and 'INDIRECT_PRIVS AS' in query and 'HOW_GRANTED' in query:
        # Define a pattern for the SELECT list in DIRECT_PRIVS that is missing an alias for the literal string.
        direct_privs_pattern = re.compile(
            r"(DIRECT_PRIVS\s+AS\s+\(\s*SELECT\s+DISTINCT\s+)(.*?)(,'Direct Grant')",
            re.IGNORECASE | re.DOTALL
        )
        # The replacement string adds ONLY the 'AS HOW_GRANTED' alias to the literal string.
        direct_privs_replacement = r"\1\2\3 AS HOW_GRANTED"
        # Use a function for replacement to avoid altering already correct queries
        def direct_repl(match):
            # Only add alias if it's not already there
            if not re.search(r"AS\s+HOW_GRANTED", match.group(0), re.IGNORECASE):
                return match.group(1) + match.group(2) + match.group(3) + " AS HOW_GRANTED"
            return match.group(0) # Return original match if alias exists
        
        # A more precise pattern to avoid accidentally matching too much
        direct_privs_pattern = re.compile(
            r"(DIRECT_PRIVS\s+AS\s+\(\s*SELECT\s+DISTINCT\s+CON_ID_TO_CON_NAME\(CON_ID\),\s*GRANTEE,\s*GRANTED_ROLE,\s*)('Direct Grant')",
            re.IGNORECASE | re.DOTALL
        )
        direct_privs_replacement = r"\1\2 AS HOW_GRANTED"
        query = direct_privs_pattern.sub(direct_privs_replacement, query)


        # Define a similar pattern for the INDIRECT_PRIVS CTE.
        indirect_privs_pattern = re.compile(
            r"(INDIRECT_PRIVS\s+AS\s+\(\s*SELECT\s+DISTINCT\s+CON_ID_TO_CON_NAME\(CON_ID\),\s*GRANTEE,\s*GRANTED_ROLE,\s*)('Privileges Through Role')",
            re.IGNORECASE | re.DOTALL
        )
        # The replacement string adds ONLY the 'AS HOW_GRANTED' alias.
        indirect_privs_replacement = r"\1\2 AS HOW_GRANTED"
        query = indirect_privs_pattern.sub(indirect_privs_replacement, query)
    # --- END: Added fix for CTE union alias error ---

    query = remove_aliases_in_where_clause(query)
    return query

def extract_db_queries(file_path, unchecked_items=None):
    if unchecked_items is None:
        unchecked_items = []
    unchecked_normalized = {re.sub(r'[^\w]+', '_', name).lower() for name in unchecked_items}
    queries = []
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return []
    for encoding in ['utf-8-sig', 'utf-8']:
        try:
            with open(file_path, 'r', encoding=encoding, errors='replace') as f:
                reader = csv.DictReader(f)
                col_map = {}
                expected_keys = {
                    'name': ['name'],
                    'query': ['query'],
                    'execution_target': ['executiontarget', 'execution_target', 'execution target'],
                    'multitenant': ['multitenant'],
                    'nonmultitenant': ['nonmultitenant']
                }
                for col in reader.fieldnames:
                    norm_col = normalize(col)
                    for key, candidates in expected_keys.items():
                        if norm_col in candidates:
                            col_map[key] = col
                if not all(k in col_map for k in expected_keys):
                    print(f"CSV missing required columns. Found: {reader.fieldnames}")
                    print(f"Mapped: {col_map}")
                    return []
                for row in reader:
                    exec_target = row.get(col_map['execution_target'], '').strip()
                    if exec_target.lower() != 'db_query':
                        continue
                    name = row.get(col_map['name'], '').strip()
                    query = row.get(col_map['query'], '').strip().rstrip(';')
                    multitenant = row.get(col_map['multitenant'], '').strip()
                    nonmultitenant = row.get(col_map['nonmultitenant'], '').strip()

                    safe_name = re.sub(r'[^\w]+', '_', name)
                    if safe_name in unchecked_normalized:
                        continue

                    query = add_missing_aliases(query)
                    queries.append({
                        'name': safe_name,
                        'common': query if is_null_like(multitenant) and is_null_like(nonmultitenant) else None,
                        'multitenant': None if is_null_like(multitenant) else add_missing_aliases(multitenant.strip().rstrip(';')),
                        'nonmultitenant': None if is_null_like(nonmultitenant) else add_missing_aliases(nonmultitenant.strip().rstrip(';'))
                    })
            return queries
        except UnicodeDecodeError:
            print(f"Failed to decode {file_path} using encoding {encoding}")
            continue
    print("Could not read CSV file with utf-8 or utf-8-sig encoding.")
    return []

def conditional_plsql_block(name, common, mt, nmt):
    def escape_sql(s): return s.replace("'", "''")
    name_literal = escape_sql(name)
    if name_literal == '2_2_1_Ensure_AUDIT_SYS_OPERATIONS_Is_Set_to_TRUE_Scored_':
        return f"""
DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'#   
        SELECT JSON_OBJECT(
                   'name' VALUE '{name_literal}',
                   'results' VALUE JSON_ARRAYAGG(JSON_OBJECT('value' VALUE value))
                  )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME) = 'AUDIT_SYS_OPERATIONS'
        )
       #';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '{name_literal}',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/
"""
    block = f"""
DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
"""
    if mt or nmt:
        block += f"""     IF v_line = 'YES' THEN
      v_sql := q'[   
        SELECT JSON_OBJECT(
                   'name' VALUE '{name_literal}',
                   'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
                  )
        FROM (
          {mt if mt else "SELECT 'Multitenant query not defined.' AS error_msg FROM dual"}
        )
      ]';
    ELSE
      v_sql := q'[   
        SELECT JSON_OBJECT(
                   'name' VALUE '{name_literal}',
                   'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
                  )
        FROM (
          {nmt if nmt else "SELECT 'Non-multitenant query not defined.' AS error_msg FROM dual"}
        )
      ]';
    END IF;
"""
    elif common:
        block += f"""     v_sql := q'[   
        SELECT JSON_OBJECT(
                   'name' VALUE '{name_literal}',
                   'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
                  )
        FROM (
          {common}
        )
      ]';
"""
    else:
        block += f"""     v_json := JSON_OBJECT(
        'name' VALUE '{name_literal}',
        'results' VALUE 'No valid query defined.'
      );
      DBMS_OUTPUT.PUT_LINE(v_json);
      RETURN;
"""
    if common or mt or nmt:
        block += f"""
    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
"""
    block += f"""   EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '{name_literal}',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/
"""
    return block

def write_queries_to_file(queries, output_file, unchecked_items=None):
    if unchecked_items is None:
        unchecked_items = []
    unchecked_normalized = {re.sub(r'[^\w]+', '_', name).lower() for name in unchecked_items} 
    with open(output_file, 'w', encoding='utf-8') as sqlfile:
        sqlfile.write("-- Generated Oracle SQL script with JSON output and dynamic SQL error handling\n\n")
        sqlfile.write("SET SERVEROUTPUT ON SIZE UNLIMITED;\n\n")
        for q in queries:
            if q['name'].lower() in unchecked_normalized:
                print(f"[-] Skipping unchecked item: {q['name']}")
                continue
            sqlfile.write(conditional_plsql_block(q['name'], q['common'], q['multitenant'], q['nonmultitenant']))
            sqlfile.write("\n")

def main():
    if len(sys.argv) < 3:
        print("Usage: python generate_sql.py <input.csv> <output.sql>")
        sys.exit(1)
    input_csv = sys.argv[1]
    output_sql = sys.argv[2]
    queries = extract_db_queries(input_csv)
    if not queries:
        print("No queries found or error reading CSV.")
        sys.exit(1)
    write_queries_to_file(queries, output_sql)
    print(f"✅ SQL script written to {output_sql}")

    mode = input("Run mode? Enter 'remote' or 'agent': ").strip().lower()
    if mode == 'remote':
        print("Please run via import and pass connection_info as JSON.")
    elif mode == 'agent':
        print(f"📁 Please transfer '{output_sql}' to the agent machine and run it locally using SQL*Plus or another Oracle client.")
    else:
        print("❌ Invalid mode selected. Please choose either 'remote' or 'agent'.")

if __name__ == "__main__":
    main()
