import csv
import sys
import os
import re


def add_aliases_to_query(query):
    # Add aliases to aggregates if missing
    query = re.sub(r'\bCOUNT\(\*\)(?!\s+AS)', 'COUNT(*) AS Count', query, flags=re.IGNORECASE)
    query = re.sub(r'\bMAX\(([^)]+)\)(?!\s+AS)', r'MAX(\1) AS MaxValue', query, flags=re.IGNORECASE)
    query = re.sub(r'\bMIN\(([^)]+)\)(?!\s+AS)', r'MIN(\1) AS MinValue', query, flags=re.IGNORECASE)
    query = re.sub(r'\bSUM\(([^)]+)\)(?!\s+AS)', r'SUM(\1) AS SumValue', query, flags=re.IGNORECASE)

    def process_select_clause(select_clause):
        # Split on commas, then process each field individually
        parts = [p.strip() for p in select_clause.split(',')]

        processed_parts = []
        for part in parts:
            # Skip if already CAST or aliased
            if re.search(r'\bCAST\s*\(', part, re.IGNORECASE) or re.search(r'\bAS\b', part, re.IGNORECASE):
                processed_parts.append(part)
            else:
                # Match is_* fields (with optional table alias like b.)
                m = re.match(r'^([\w]+\.)?(is_\w+)$', part.strip())
                if m:
                    table_prefix = m.group(1) or ''
                    field_name = m.group(2)
                    casted = f'CAST({table_prefix}{field_name} AS INT) AS {field_name}'
                    processed_parts.append(casted)
                else:
                    processed_parts.append(part)

        return ', '.join(processed_parts)

    # Replace SELECT ... FROM block
    def replace_select_block(match):
        select_kw = match.group(1)
        select_body = match.group(2)
        from_kw = match.group(3)

        processed_body = process_select_clause(select_body)
        return f"{select_kw}{processed_body}{from_kw}"

    # Apply only to SELECT ... FROM (one clause at a time)
    updated_query = re.sub(
        r'(SELECT\s+)(.*?)(\s+FROM)',
        replace_select_block,
        query,
        flags=re.IGNORECASE | re.DOTALL
    )

    return updated_query
def generate_mssql_work(excluding_names, input_csv_path, output_sql_path):
    excluding_names = set(excluding_names)
    input_csv = input_csv_path
    base_name = os.path.splitext(os.path.basename(input_csv))[0]

    output_sql = output_sql_path  # 👈 use the full path from argument
    print(f"Generating SQL script at: {output_sql}")

    # ---------------------------------------
    # Helper function to alias aggregate functions
    # ---------------------------------------


    # ---------------------------------------
    # Initialize query containers
    # ---------------------------------------
    # Initialize query containers
    select_queries = []
    use_select_queries = []
    declare_queries = []
    # ---------------------------------------
    # Read and parse the CSV input
    # ---------------------------------------
    with open(input_csv, newline='', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        reader.fieldnames = [name.lstrip('\ufeff') for name in reader.fieldnames]
        for row in reader:
            check_name = row.get('Name', '').strip()
            query = row.get('Query', '').strip()
            print(check_name)
            
            if check_name in excluding_names:
                continue

            if not check_name or not query:
                continue

            # Remove "GO" and trailing semicolons
            query = re.sub(r'\bGO\b', '', query, flags=re.IGNORECASE).strip().rstrip(';')

            upper_query = query.upper()

            # Classify queries
            if upper_query.startswith("DECLARE"):
                # Split out DECLARE and remaining block
                declare_match = re.findall(r'(DECLARE.+?;)(.*)', query, flags=re.IGNORECASE | re.DOTALL)
                if declare_match:
                    declare_stmt, remaining = declare_match[0]
                    declare_queries.append((check_name, declare_stmt.strip(), remaining.strip()))
            elif upper_query.startswith("SELECT"):
                select_queries.append((check_name, query))
            elif upper_query.startswith("USE"):
                parts = re.split(r'\bSELECT\b', query, flags=re.IGNORECASE)
                if len(parts) == 2:
                    use_stmt = parts[0].strip()
                    select_stmt = "SELECT " + parts[1].strip()
                    use_select_queries.append((check_name, use_stmt, select_stmt))

    # ---------------------------------------
    # Write the final SQL script
    # ---------------------------------------
    with open(output_sql, 'w', encoding='utf-8') as sqlfile:
        sqlfile.write("SET TEXTSIZE 2147483647;\n")
        sqlfile.write("DECLARE @results TABLE (\n")
        sqlfile.write("    Name NVARCHAR(255),\n")
        sqlfile.write("    Result NVARCHAR(MAX)\n")
        sqlfile.write(");\n\n")

        # SELECT-only queries
        for check_name, query in select_queries:
            escaped_name = check_name.replace("'", "''")
            query = add_aliases_to_query(query)

            sqlfile.write(f"INSERT INTO @results (Name, Result)\n")
            sqlfile.write(f"SELECT '{escaped_name}', (\n")
            sqlfile.write(f"    SELECT * FROM (\n        {query}\n    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES\n")
            sqlfile.write(");\n\n")

        # USE + SELECT queries
        for check_name, use_stmt, select_stmt in use_select_queries:
            escaped_name = check_name.replace("'", "''")
            select_stmt = add_aliases_to_query(select_stmt)

            sqlfile.write(f"{use_stmt};\n")
            sqlfile.write(f"INSERT INTO @results (Name, Result)\n")
            sqlfile.write(f"SELECT '{escaped_name}', (\n")
            sqlfile.write(f"    SELECT * FROM (\n        {select_stmt}\n    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES\n")
            sqlfile.write(");\n\n")

        # DECLARE + EXEC + SELECT queries
        for check_name, declare_stmt, remaining_block in declare_queries:
            escaped_name = check_name.replace("'", "''")
            # Attempt to extract final SELECT statement
            select_match = re.search(r'(SELECT.+)', remaining_block, flags=re.IGNORECASE | re.DOTALL)
            if select_match:
                final_select = select_match.group(1).strip().rstrip(';')
                pre_exec_part = remaining_block.replace(select_match.group(1), '').strip()

                sqlfile.write(f"{declare_stmt}\n")
                if pre_exec_part:
                    sqlfile.write(f"{pre_exec_part}\n")
                sqlfile.write(f"INSERT INTO @results (Name, Result)\n")
                sqlfile.write(f"SELECT '{escaped_name}', (\n")
                sqlfile.write(f"    SELECT * FROM (\n        {final_select}\n    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES\n")
                sqlfile.write(");\n\n")

        # Final output
        sqlfile.write("SELECT Name, ISNULL(JSON_QUERY(Result), 'null') AS Result FROM @results FOR JSON PATH;\n")
        

    print(f"[+] JSON-style SQL script generated: {output_sql}")
    print("[+] Run with: ")
    print(f"       sqlcmd -S DESKTOP-03IUT02\\SQLEXPRESS -E -i {output_sql} -h -1 -y 8000 -o {output_sql}")