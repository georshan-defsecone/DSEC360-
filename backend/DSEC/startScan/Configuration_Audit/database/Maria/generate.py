import sys
from collections import defaultdict
import csv
import re
import csv

def normalize(s):
    """Normalize a string for column matching: lowercase, remove non-alphanumeric."""
    return ''.join(c for c in s.lower() if c.isalnum())
def read_csv_file(file_path, required_keys, patterns):
    """
    Reads the CSV file and matches required headers using patterns.
    Returns:
      - reader: list of row dictionaries
      - col_map: mapping from required_key -> actual CSV header
    """
    for encoding in ['utf-8-sig', 'utf-8']:
        try:
            with open(file_path, newline='', encoding=encoding) as f:
                reader = list(csv.DictReader(f))
                if not reader:
                    return None, {}

                # Normalize and build column map
                header_row = reader[0].keys()
                col_map = {}
                normalized_headers = {normalize(h): h for h in header_row}

                for key, pattern_list in patterns.items():
                    for p in pattern_list:
                        norm_p = normalize(p)
                        if norm_p in normalized_headers:
                            col_map[key] = normalized_headers[norm_p]
                            break

                # Check if all required keys are found
                if all(key in col_map for key in required_keys):
                    return reader, col_map
                else:
                    print(f"Missing required columns: {[k for k in required_keys if k not in col_map]}")
                    return None, {}
        except UnicodeDecodeError:
            continue
    return None, {}

def normalize(s):
    """Normalize a string for column matching: lowercase, remove non-alphanumeric."""
    return ''.join(c for c in s.lower() if c.isalnum())

def read_csv_file_for_db_query(file_path):
    """
    Reads a CSV file and returns:
    - reader: list of dictionaries representing each row
    - col_map: mapping of 'name', 'query', 'execution_target' to actual CSV column names
    Handles spacing, formatting issues, and encoding differences.
    """
    required_keys = ['name', 'query', 'execution_target']
    patterns = {
        'name': ['name'],
        'query': ['query'],
        'execution_target': ['executiontarget', 'execution_target']
    }

    for encoding in ['utf-8-sig', 'utf-8']:
        try:
            with open(file_path, 'r', encoding=encoding) as f:
                reader = csv.DictReader(f)
                if not reader.fieldnames:
                    print("CSV file has no headers.")
                    return None, {}

                print("Normalized headers for debugging:")
                col_map = {}
                for col in reader.fieldnames:
                    norm = normalize(col)
                    for key in required_keys:
                        if any(pat == norm for pat in patterns[key]):
                            col_map[key] = col

                if not all(k in col_map for k in required_keys):
                    print(f"\nCSV missing required columns. Required: {required_keys}, Found: {list(col_map.keys())}")
                    return None, {}

                return list(reader), col_map

        except UnicodeDecodeError:
            continue

    print("Could not read the CSV file with utf-8 or utf-8-sig encoding.")
    return None, {}


def extract_db_queries_remote(file_path):
    """
    Extracts queries where execution_target is 'db_query' or 'db_and_terminal'
    Returns a list of (safe_name, query)
    """

    reader, col_map = read_csv_file_for_db_query(file_path)
    if not reader:
        return []

    queries = []
    for row in reader:
        exec_target = row.get(col_map['execution_target'], '')
        exec_target_clean = ''.join(c for c in exec_target if c.isprintable() and not c.isspace()).lower()

        if exec_target_clean in ('db_query'):
            name = row.get(col_map['name'], '').strip()
            query = row.get(col_map['query'], '').strip()

            if query and name:
                safe_name = re.sub(r'\W+', '_', name)
                queries.append((safe_name, query))

    return queries


def extract_db_queries(file_path):
    """
    Extracts queries where execution_target is 'db_query' or 'db_and_terminal'
    Returns a list of (safe_name, query)
    """

    reader, col_map = read_csv_file_for_db_query(file_path)
    if not reader:
        return []

    queries = []
    for row in reader:
        exec_target = row.get(col_map['execution_target'], '')
        exec_target_clean = ''.join(c for c in exec_target if c.isprintable() and not c.isspace()).lower()

        if exec_target_clean in ('db_query', 'db_and_terminal'):
            name = row.get(col_map['name'], '').strip()
            query = row.get(col_map['query'], '').strip()

            if query and name:
                safe_name = re.sub(r'\W+', '_', name)
                queries.append((safe_name, query))

    return queries

def handle_multiple_query_rows(file_path, excluded_names):
    """
    Combines 'query' and 'other_query' into one using UNION ALL if 'execution_target' is 'multiple_query'.
    Converts SHOW and SELECT @@ queries into SELECT form.
    Returns list of (safe_name, combined_query).
    """
    required_keys = ['name', 'query', 'other_query', 'execution_target']
    patterns = {
        'name': ['name'],
        'query': ['query'],
        'other_query': ['otherquery', 'other_query'],
        'execution_target': ['executiontarget', 'execution_target']
    }

    reader, col_map = read_csv_file(file_path, required_keys, patterns)
    if not reader:
        return []

    combined_query_rows = []

    for row in reader:
        exec_target = row.get(col_map['execution_target'], '').strip().lower().replace(" ", "")
        if exec_target != 'multiple_query':
            continue

        name = row.get(col_map['name'], '').strip()
        print(name)
        if name in excluded_names:
            continue
        query_1 = row.get(col_map['query'], '').strip().rstrip(';')
        query_2 = row.get(col_map['other_query'], '').strip().rstrip(';')

        queries = []
        for q in [query_1, query_2]:
            q = q.strip().rstrip(';')
            q_clean = re.sub(r'\s+', ' ', q)

            # Match SELECT @@variable and convert to SHOW VARIABLES form
            match = re.match(r"select\s+@@(\w+)", q_clean, re.IGNORECASE)
            if match:
                var_name = match.group(1)
                queries.append(f"SHOW VARIABLES WHERE Variable_name = '{var_name}'")
            elif q_clean.lower().startswith("show"):
                converted = convert_show_to_select(q_clean)
                if converted.startswith("SELECT"):
                    queries.append(converted)
            elif q_clean.lower().startswith("select"):
                queries.append(q_clean)
        # Deduplicate while preserving order
        unique_queries = list(dict.fromkeys(queries))
        if name and unique_queries:
            combined = "\nUNION ALL\n".join(unique_queries)
            safe_name = re.sub(r'\W+', '_', name)
            combined_query_rows.append((safe_name, combined))
    return combined_query_rows


def extract_linux_commands(file_path):
    linux_commands = []
    db_and_terminal_commands = []
    for encoding in ['utf-8-sig', 'utf-8']:
        try:
            with open(file_path, 'r', encoding=encoding) as f:
                reader = csv.DictReader(f)
                col_map = {}
                for col in reader.fieldnames:
                    norm = normalize(col)
                    if 'name' in norm and 'command' not in norm:
                        col_map['name'] = col
                    elif 'linuxcommand' in norm or 'linux_command' in norm:
                        col_map['linux_command'] = col
                    elif 'executiontarget' in norm or 'execution_target' in norm:
                        col_map['execution_target'] = col

                if not all(k in col_map for k in ('name', 'linux_command', 'execution_target')):
                    print("CSV does not contain required columns (name, linux_command, execution_target).")
                    return [], []

                for row in reader:
                    exec_target = row.get(col_map['execution_target'], '')
                    exec_target_clean = ''.join(c for c in exec_target if c.isprintable() and not c.isspace()).lower()
                    name = row.get(col_map['name'], '').strip()
                    command = row.get(col_map['linux_command'], '').strip()
                    if name and command:
                        safe_name = re.sub(r'\W+', '_', name)
                        if exec_target_clean == 'linux_terminal':
                            linux_commands.append((safe_name, command))
                        elif exec_target_clean == 'db_and_terminal':
                            db_and_terminal_commands.append((safe_name, command))
                return linux_commands, db_and_terminal_commands
        except UnicodeDecodeError:
            continue
    print("Could not read the CSV file with utf-8 or utf-8-sig encoding.")
    return [], []

def convert_show_to_select(show_query: str) -> str:
    # Remove trailing semicolon and strip
    show_query_clean = show_query.strip().rstrip(';')
    show_query_lower = show_query_clean.lower()

    # Pattern: SHOW [GLOBAL] VARIABLES WHERE VARIABLE_NAME = '...'
    match = re.match(
        r"show\s+(global\s+)?variables\s+where\s+variable_name\s*=\s*['\"]?([\w\d_]+)['\"]?",
        show_query_clean, re.IGNORECASE)
    if match:
        var_name = match.group(2)
        return f"SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME = '{var_name}'"

    # Pattern: SHOW [GLOBAL] VARIABLES LIKE '...'
    match = re.match(
        r"show\s+(global\s+)?variables\s+like\s+['\"]?([\w\d_%]+)['\"]?",
        show_query_clean, re.IGNORECASE)
    if match:
        pattern = match.group(2)
        return f"SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME LIKE '{pattern}'"

    # Pattern: SHOW STATUS LIKE '...'
    match = re.match(
        r"show\s+status\s+like\s+['\"]?([\w\d_%]+)['\"]?",
        show_query_clean, re.IGNORECASE)
    if match:
        pattern = match.group(1)
        return f"SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_status WHERE VARIABLE_NAME LIKE '{pattern}'"

    if show_query_lower.startswith("show tables"):
        return "SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE()"
    if show_query_lower.startswith("show databases"):
        return "SELECT schema_name FROM information_schema.schemata"
    if show_query_lower.startswith("show processlist"):
        return "SELECT * FROM information_schema.processlist"
    if show_query_lower.startswith("show plugins"):
        return "SELECT VARIABLE_NAME,VARIABLE_VALUE FROM information_schema.plugins"


    return "-- Unsupported SHOW query"

def add_aliases_to_query(query):
    # Add aliases to columns for SQL Server JSON output
    # This is a simple heuristic; you may want to improve it for complex queries
    return re.sub(r'(\w+)\s*,', r'\1 AS \1_alias,', query)

def write_queries_to_file(queries, output_file,excluded_names=None):
    with open(output_file, 'w', encoding='utf-8') as sqlfile:
        sqlfile.write("-- Generated SQL script with JSON output for MariaDB/MySQL\n\n")
        sqlfile.write("SELECT JSON_ARRAYAGG(JSON_OBJECT('Name', Name, 'Result', Result)) AS AllResults\nFROM (\n")
        union_queries = []
        for check_name, query in queries:
            escaped_name = check_name.replace("'", "''")
            # Convert SHOW queries to SELECT
            if query.strip().lower().startswith("show"):
                query = convert_show_to_select(query)
            print(check_name,excluded_names)
            if check_name in excluded_names:
                continue
            query = query.rstrip(';')
            select_match = re.match(r"select\s+(.*?)\s+from\s+", query, re.IGNORECASE | re.DOTALL)
            if select_match:
                columns = select_match.group(1)
                if columns.strip() == '*':
                    subquery = (
                        f"SELECT '{escaped_name}' AS Name,\n"
                        f"  (\n    SELECT JSON_ARRAYAGG(t) FROM ({query}) t\n  ) AS Result"
                    )
                else:
                    colnames = []
                    for col in columns.split(','):
                        col = col.strip()
                        if col.startswith('@@'):
                            alias = col.replace('@@', '')
                            query = query.replace(col, f"{col} AS {alias}")
                            colnames.append(alias)
                        elif ' as ' in col.lower():
                            alias = col.split(' as ')[-1].strip()
                            colnames.append(alias)
                        else:
                            colnames.append(col.split()[-1])
                    json_obj = "JSON_OBJECT(" + ", ".join([f"'{col}', {col}" for col in colnames]) + ")"
                    subquery = (
                        f"SELECT '{escaped_name}' AS Name,\n"
                        f"  (\n    SELECT JSON_ARRAYAGG({json_obj}) FROM ({query}) t\n  ) AS Result"
                    )
            else:
                subquery = (
                    f"SELECT '{escaped_name}' AS Name,\n"
                    f"  (\n    SELECT JSON_ARRAYAGG(JSON_OBJECT('value', value)) FROM ({query} AS value) t\n  ) AS Result"
                )
            union_queries.append(subquery)
        sqlfile.write("\nUNION ALL\n".join(union_queries))
        sqlfile.write("\n) results;\n")
def write_linux_script(linux_commands, db_and_terminal_commands, output_file, excluded_names):
    """
    Generates a bash script that:
    - Reads input JSON file from $1
    - Runs static linux_commands (no placeholders) and stores results
    - Runs dynamic db_and_terminal_commands (with placeholders) by substituting
      values from JSON and executing commands
    - Outputs final combined JSON array to final.json

    Args:
        linux_commands: list of (name, command) tuples without placeholders
        db_and_terminal_commands: list of (name, command) tuples with placeholders like {{VAR_NAME}}
        output_file: output bash script filename
    """
    with open(output_file, 'w', encoding='utf-8') as script:
        script.write("#!/bin/bash\n\n")

        # Usage check
        script.write("if [ $# -lt 1 ]; then\n")
        script.write('  echo "Usage: $0 <input.json>"\n')
        script.write("  exit 1\n")
        script.write("fi\n\n")

        script.write('input_file="$1"\n')
        script.write('output_file="final.json"\n\n')

        # Declare associative arrays
        script.write("declare -A json_map\n")
        script.write("declare -A db_commands\n\n")

        # Populate db_commands associative array with dynamic commands
        for name, cmd in db_and_terminal_commands:
            safe_name = name.replace('"', '\\"')
            safe_cmd = cmd.replace('"', '\\"')
            print(name, excluded_names)
            if name in excluded_names:
                continue
            script.write(f'db_commands["{safe_name}"]="{safe_cmd}"\n')

        script.write("\n")

        # Read JSON input into associative array json_map[name] = JSON item
        script.write('if [ -f "$input_file" ]; then\n')
        script.write('  while IFS= read -r item; do\n')
        script.write('    name=$(echo "$item" | jq -r \'.Name\')\n')
        script.write('    json_map["$name"]="$item"\n')
        script.write('  done < <(jq -c \'.[]\' "$input_file")\n')
        script.write("fi\n\n")

        # Run static Linux commands (no placeholders)
        for name, cmd in linux_commands:
            escaped_name = name.replace('"', '\\"')
            print(name)
            if name in excluded_names:
                continue
            script.write(f'result=$( {cmd} 2>&1 | sed \'s/"/\\\\\\"/g\' )\n')
            script.write(f'json_map["{escaped_name}"]="{{\\"Name\\": \\"{escaped_name}\\", \\"Result\\": [{{\\"VARIABLE_NAME\\": \\"Command\\", \\"VARIABLE_VALUE\\": \\"$result\\"}}]}}"\n\n')

        # Run dynamic commands with placeholder substitution
        script.write('for name in "${!db_commands[@]}"; do\n')
        script.write('  raw_entry="${json_map[$name]}"\n')
        script.write('  if [ -n "$raw_entry" ]; then\n')
        script.write('    cmd_template="${db_commands[$name]}"\n')
        script.write('    result_json=$(echo "$raw_entry" | jq -c \'.Result // empty | .[]\')\n')
        script.write('    if [ -z "$result_json" ]; then\n')
        script.write('      valid_substitution=false\n')
        script.write('    else\n')
        script.write('      valid_substitution=true\n')
        script.write('      for pair in $result_json; do\n')
        script.write('        var=$(echo "$pair" | jq -r \'.VARIABLE_NAME\')\n')
        script.write('        val=$(echo "$pair" | jq -r \'.VARIABLE_VALUE\')\n')
        script.write('        if [ "$val" = "null" ] || [ -z "$val" ]; then\n')
        script.write('          valid_substitution=false\n')
        script.write('          break\n')
        script.write('        fi\n')
        script.write(r'        cmd_template="${cmd_template//\{\{$var\}\}/$val}"' + '\n')
        script.write('      done\n')
        script.write('    fi\n')
        script.write('    if [ "$valid_substitution" = true ]; then\n')
        script.write('      result=$(eval "$cmd_template" 2>&1 | tr \'\\n\' \',\' | sed \'s/,$//\' | sed \'s/"/\\\\\\"/g\')\n')
        script.write('    else\n')
        script.write('      result="it is not enabled"\n')
        script.write('    fi\n')
        script.write('    json_map["$name"]="{\\"Name\\": \\"$name\\", \\"Result\\": [{\\"VARIABLE_NAME\\": \\"Command\\", \\"VARIABLE_VALUE\\": \\"$result\\"}]}"\n')
        script.write('  fi\n')
        script.write('done\n\n')

        # Prepare final JSON output array
        script.write('output_items=()\n')
        script.write('for item in "${json_map[@]}"; do\n')
        script.write('  output_items+=("$item")\n')
        script.write('done\n\n')

        script.write('printf "[\\n%s\\n]" "$(IFS=,; echo "${output_items[*]}")" > "$output_file"\n')

def generate_mariadb_work(excluded_audit_names,csv_path,sql_commands,linux_file):
    
    csv_file = csv_path
    output_file = sql_commands
    
    # Standard db_query and db_and_terminal rows
    queries = extract_db_queries(csv_file)


    # Additional: handle multiple_query rows
    multi_queries = handle_multiple_query_rows(csv_file, excluded_names=excluded_audit_names)
    queries.extend(multi_queries)
    excluded_names = excluded_audit_names
    print(excluded_names)
    if queries:
        write_queries_to_file(queries, output_file, excluded_names=excluded_names)
        print(f"Extracted {len(queries)} queries (including multiple_query) to {output_file}")
    else:
        print("No db_query queries found or required columns missing.")

    if linux_file!='':
        linux_script_file = linux_file
        linux_commands, db_and_terminal_commands = extract_linux_commands(csv_file)
        write_linux_script(linux_commands, db_and_terminal_commands, linux_script_file, excluded_names=excluded_names)
        print(f"Extracted {len(linux_commands)} linux commands to {linux_script_file}")


def generate_mariadb_work_remote(excluded_audit_names,csv_file,sql_file):
    
    csv_file = csv_file
    output_file = sql_file

    # Standard db_query and db_and_terminal rows
    queries = extract_db_queries_remote(csv_file)


    # Additional: handle multiple_query rows
    multi_queries = handle_multiple_query_rows(csv_file, excluded_names=excluded_audit_names)
    print(multi_queries)
    queries.extend(multi_queries)
    excluded_names = excluded_audit_names
    print(excluded_names)
    if queries:
        write_queries_to_file(queries, output_file, excluded_names=excluded_names)
        print(f"Extracted {len(queries)} queries (including multiple_query) to {output_file}")
    else:
        print("No db_query queries found or required columns missing.")
