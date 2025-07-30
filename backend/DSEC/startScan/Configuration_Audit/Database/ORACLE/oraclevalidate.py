import sys
import csv
import re
import os

# Mock oracledb and getpass if they are not essential for the core logic
try:
    import oracledb
except ImportError:
    print("Warning: 'oracledb' module not found. Using a mock.")
    oracledb = None

try:
    import getpass
except ImportError:
    print("Warning: 'getpass' module not found. Using a mock.")
    getpass = None


def normalize(s):
    """Normalizes a string by making it lowercase and alphanumeric."""
    return ''.join(c for c in s.lower() if c.isalnum())

def is_null_like(s):
    """Checks if a string is None, empty, or 'null'."""
    return s is None or s.strip().lower() == 'null' or s.strip() == ''

def add_missing_aliases(query):
    """
    Correctly and robustly adds required column aliases to a SQL query string.

    This function is purely additive. It scans for specific column names or
    literal strings and adds an alias ONLY if one does not already exist.
    It will never remove or modify an existing alias from your source query.
    """
    if not query:
        return query

    # This regex finds the standalone word 'PRIVILEGE' and replaces it with
    # 'PRIVILEGE AS GRANTED_PRIVILEGE'. The `(?!\s+AS\s+GRANTED_PRIVILEGE)` part
    # is a negative lookahead that ensures the replacement only happens if
    # the alias is not already present, thus preserving your original aliases.
    query = re.sub(
        r'\bPRIVILEGE\b(?!\s+AS\s+GRANTED_PRIVILEGE)',
        'PRIVILEGE AS GRANTED_PRIVILEGE',
        query,
        flags=re.IGNORECASE
    )
    
    # This does the same for 'GRANTED_ROLE'.
    query = re.sub(
        r'\bGRANTED_ROLE\b(?!\s+AS\s+GRANTED_PRIVILEGE)',
        'GRANTED_ROLE AS GRANTED_PRIVILEGE',
        query,
        flags=re.IGNORECASE
    )

    # This regex finds the literal string 'Direct Grant' and adds 'AS HOW_GRANTED'.
    # The negative lookahead `(?!\s+AS\s+HOW_GRANTED)` ensures it only runs if
    # the alias is missing, preserving your original aliases.
    query = re.sub(
        r"('Direct Grant'|\"Direct Grant\")(?!\s+AS\s+HOW_GRANTED)",
        r"\1 AS HOW_GRANTED",
        query,
        flags=re.IGNORECASE
    )
    
    # This does the same for 'Privileges Through Role'.
    query = re.sub(
        r"('Privileges Through Role'|\"Privileges Through Role\")(?!\s+AS\s+HOW_GRANTED)",
        r"\1 AS HOW_GRANTED",
        query,
        flags=re.IGNORECASE
    )
    
    return query

def extract_db_queries(file_path, unchecked_items=None):
    """Extracts and processes queries from the input CSV file."""
    if unchecked_items is None:
        unchecked_items = []
    unchecked_normalized = {re.sub(r'[^\w]+', '_', name).lower() for name in unchecked_items}
    queries = []
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return []
    
    # Try different encodings to open the CSV file
    for encoding in ['utf-8-sig', 'utf-8', 'latin-1']:
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
                
                # Map CSV headers to our expected keys
                for col in reader.fieldnames:
                    norm_col = normalize(col)
                    for key, candidates in expected_keys.items():
                        if norm_col in candidates:
                            col_map[key] = col
                
                if not all(k in col_map for k in ['name', 'query', 'execution_target']):
                    print(f"CSV missing required columns (name, query, execution_target). Found: {reader.fieldnames}")
                    return []

                for row in reader:
                    exec_target = row.get(col_map.get('execution_target'), '').strip()
                    if exec_target.lower() != 'db_query':
                        continue

                    name = row.get(col_map.get('name'), '').strip()
                    
                    # *** FIX: Cleanse input strings to remove non-standard whitespace ***
                    # The CSV file contains non-breaking spaces (U+00A0) which break the regex matching.
                    # This replaces them and other weird whitespace with a standard space.
                    def clean_string(s):
                        if s is None:
                            return None
                        # Replace non-breaking spaces and collapse all whitespace to single spaces
                        s_no_nbsp = s.replace(u'\xa0', ' ')
                        return re.sub(r'\s+', ' ', s_no_nbsp).strip()

                    query_text = clean_string(row.get(col_map.get('query'), ''))
                    multitenant = clean_string(row.get(col_map.get('multitenant'), ''))
                    nonmultitenant = clean_string(row.get(col_map.get('nonmultitenant'), ''))

                    safe_name = re.sub(r'[^\w]+', '_', name)
                    if safe_name.lower() in unchecked_normalized:
                        continue
                    
                    # Process all potential query strings to add missing aliases
                    processed_query = add_missing_aliases(query_text.rstrip(';'))
                    processed_mt = add_missing_aliases(multitenant.rstrip(';')) if not is_null_like(multitenant) else None
                    processed_nmt = add_missing_aliases(nonmultitenant.rstrip(';')) if not is_null_like(nonmultitenant) else None

                    is_common_query = is_null_like(multitenant) and is_null_like(nonmultitenant)

                    queries.append({
                        'name': safe_name,
                        'common': processed_query if is_common_query else None,
                        'multitenant': processed_mt,
                        'nonmultitenant': processed_nmt
                    })
            return queries # Successfully processed the file
        except (UnicodeDecodeError, Exception) as e:
            print(f"Failed to process {file_path} with encoding {encoding}: {e}")
            continue
    
    print("Could not read or process the CSV file with any of the attempted encodings.")
    return []

def conditional_plsql_block(name, common, mt, nmt):
    """Generates a PL/SQL block for a given query."""
    def escape_sql(s): 
        if not s:
            return s
        return s.replace("'", "''")

    name_literal = escape_sql(name)

    # Special handling for a specific query
    if name_literal == '2_2_1_Ensure_AUDIT_SYS_OPERATIONS_Is_Set_to_TRUE_Scored_':
        return f"""
DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
BEGIN
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
        JSON_OBJECT( 'name' VALUE '{name_literal}', 'results' VALUE 'ERROR: ' || SQLERRM )
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
  v_is_cdb VARCHAR2(10);
BEGIN
  SELECT cdb INTO v_is_cdb FROM v$database;

  BEGIN
"""
    if mt or nmt:
        mt_query = escape_sql(mt) if mt else "SELECT 'Multitenant query not defined.' AS error_msg FROM dual"
        nmt_query = escape_sql(nmt) if nmt else "SELECT 'Non-multitenant query not defined.' AS error_msg FROM dual"
        block += f"""    IF v_is_cdb = 'YES' THEN
      v_sql := q'[
        SELECT JSON_OBJECT( 'name' VALUE '{name_literal}', 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*)))
        FROM ( {mt_query} )
      ]';
    ELSE
      v_sql := q'[
        SELECT JSON_OBJECT( 'name' VALUE '{name_literal}', 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*)))
        FROM ( {nmt_query} )
      ]';
    END IF;
"""
    elif common:
        common_query = escape_sql(common)
        block += f"""    v_sql := q'[
      SELECT JSON_OBJECT( 'name' VALUE '{name_literal}', 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*)))
      FROM ( {common_query} )
    ]';
"""
    else:
        block += f"""    v_json := JSON_OBJECT( 'name' VALUE '{name_literal}', 'results' VALUE 'No valid query defined.' );
    DBMS_OUTPUT.PUT_LINE(v_json);
    RETURN;
"""
    if common or mt or nmt:
        block += f"""
    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    
    IF v_json IS NULL OR LENGTH(v_json) < 3 THEN
        v_json := JSON_OBJECT('name' VALUE '{name_literal}', 'results' VALUE JSON_ARRAY());
    END IF;

    DBMS_OUTPUT.PUT_LINE(v_json);
"""
    block += f"""  EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE(JSON_OBJECT('name' VALUE '{name_literal}', 'results' VALUE JSON_ARRAY()));
    WHEN OTHERS THEN
      IF v_cursor%ISOPEN THEN
        CLOSE v_cursor;
      END IF;
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT( 'name' VALUE '{name_literal}', 'results' VALUE 'ERROR: ' || SQLERRM )
      );
  END;
END;
/
"""
    return block

def write_queries_to_file(queries, output_file, unchecked_items=None):
    """Writes the generated PL/SQL blocks to the output file."""
    if unchecked_items is None:
        unchecked_items = []
    unchecked_normalized = {re.sub(r'[^\w]+', '_', name).lower() for name in unchecked_items}
    with open(output_file, 'w', encoding='utf-8') as sqlfile:
        sqlfile.write("-- Generated Oracle SQL script with JSON output and dynamic SQL error handling\n\n")
        sqlfile.write("SET SERVEROUTPUT ON SIZE UNLIMITED;\n")
        sqlfile.write("SET FEEDBACK OFF;\n\n")
        for q in queries:
            if q['name'].lower() in unchecked_normalized:
                print(f"[-] Skipping unchecked item: {q['name']}")
                continue
            sqlfile.write(conditional_plsql_block(q['name'], q['common'], q['multitenant'], q['nonmultitenant']))
            sqlfile.write("\n")

def main():
    """Main function to drive the script."""
    if len(sys.argv) < 3:
        print("Usage: python generate_sql.py <input.csv> <output.sql>")
        sys.exit(1)
    input_csv = sys.argv[1]
    output_sql = sys.argv[2]

    queries = extract_db_queries(input_csv)
    if not queries:
        print("No queries extracted or error reading CSV. Exiting.")
        sys.exit(1)

    write_queries_to_file(queries, output_sql)
    print(f"✅ SQL script written to {output_sql}")

    try:
        mode = input("Run mode? Enter 'remote' or 'agent': ").strip().lower()
        if mode == 'remote':
            print("Please run via import and pass connection_info as JSON.")
        elif mode == 'agent':
            print(f"📁 Please transfer '{output_sql}' to the agent machine and run it locally using SQL*Plus or another Oracle client.")
        else:
            print("❌ Invalid mode selected. Please choose either 'remote' or 'agent'.")
    except EOFError:
        print("\nNo input for run mode provided. Script generation complete.")

if __name__ == "__main__":
    main()
