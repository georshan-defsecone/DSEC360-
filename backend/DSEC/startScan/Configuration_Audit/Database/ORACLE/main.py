import sys
import json
from generate_sql import extract_db_queries, write_queries_to_file, execute_sql_script_remotely
from backend.DSEC.startScan.Configuration_Audit.Database.ORACLE.oraclevalidate import load_csv, validate

def main():
    # === Step 1: Input setup ===
    input_csv = "input.csv"
    output_sql = "generated_script.sql"
    check_csv = "check.csv"
    output_json = "output.json"
    result_csv = "result.csv"
    unchecked_items = []  # You can populate this if needed

    # === Step 2: Generate queries from input.csv ===
    queries = extract_db_queries(input_csv, unchecked_items)
    if not queries:
        print("❌ No valid queries found. Exiting.")
        sys.exit(1)

    write_queries_to_file(queries, output_sql, unchecked_items)
    print(f"\n✅ SQL script written to {output_sql}")

    # === Step 3: Ask how to run ===
    mode = input("Run SQL script remotely now? Enter 'yes' or 'no': ").strip().lower()
    if mode == 'yes':
        connection_info = {
            "target": input("DB host: ").strip(),
            "port": input("Port (default 1521): ").strip() or "1521",
            "service_name": input("Service name: ").strip(),
            "username": input("DB username: ").strip(),
            "password": input("DB password: ").strip()
        }
        execute_sql_script_remotely(output_sql, connection_info)
    else:
        print(f"\n📋 Please run '{output_sql}' manually using SQL*Plus or another Oracle tool.")
        input(f"Press Enter once you have generated '{output_json}' manually...")

    # === Step 4: Validate the results ===
    print("\n🔎 Validating results...")
    expected_rules = load_csv(check_csv)
    validate(output_json, expected_rules, result_csv)

if __name__ == "__main__":
    main()
