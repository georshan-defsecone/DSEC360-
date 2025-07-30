import csv
import os
import stat
import re
import argparse
import json
# Import the updated remote execution function
from .postgresql_remote import execute_remote_sql

def transform_sql_to_json(sql_query, audit_name):
    """
    Transforms a standard SQL query into one that returns a JSON object,
    using the provided audit_name as the top-level key.
    """
    clean_query = sql_query.strip().rstrip(';')
    sanitized_audit_name = audit_name.replace("'", "''")

    # --- Pattern 1: Handle 'SHOW' commands ---
    show_match = re.match(r'show\s+([a-zA-Z_]+)', clean_query, re.IGNORECASE)
    if show_match:
        setting_name = show_match.group(1)
        return f"SELECT json_build_object('{sanitized_audit_name}', json_build_object('{setting_name}', current_setting('{setting_name}')));"

    # --- Pattern 2: Handle 'SELECT' commands ---
    if clean_query.lower().startswith('select'):
        return f"SELECT json_build_object('{sanitized_audit_name}', json_agg(t)) FROM ({clean_query}) AS t;"

    # --- Fallback for other commands ---
    return f"-- Original command for audit '{sanitized_audit_name}' (could not be converted to JSON output): {sql_query}"

def process_csv_file(filepath, sql_output_path, linux_output_path, unchecked_items=None):
    """
    Reads the input CSV, processes each row, and creates the appropriate
    linux or sql files at the specified paths. Skips any audits
    whose names are in the unchecked_items list.
    
    Args:
        filepath: The path to the input CSV file.
        sql_output_path: The full path for the generated SQL file.
        linux_output_path: The full path for the generated Linux script.
        unchecked_items: A list or set of audit names to skip.
    
    Returns:
        The path to the generated SQL file if successful, otherwise None.
    """
    if unchecked_items is None:
        unchecked_items = []

    try:
        # Ensure the parent directories for the output files exist
        os.makedirs(os.path.dirname(sql_output_path), exist_ok=True)
        os.makedirs(os.path.dirname(linux_output_path), exist_ok=True)

        print(f"\nGenerating SQL script at: {sql_output_path}")
        print(f"Generating Linux script at: {linux_output_path}")

        # Open both the SQL and the single Linux script files
        with open(sql_output_path, 'w') as sql_file, \
             open(linux_output_path, 'w') as linux_file:
            
            linux_file.write("#!/bin/bash\n\n")
            
            with open(filepath, mode='r', encoding='utf-8-sig') as csv_file:
                csv_reader = csv.DictReader(csv_file)
                
                required_columns = ['name', 'query', 'type']
                if not all(col in csv_reader.fieldnames for col in required_columns):
                    print(f"\nError: The CSV file must contain the following columns: {', '.join(required_columns)}.")
                    print(f"Detected columns: {csv_reader.fieldnames}")
                    return None

                for row in csv_reader:
                    audit_name = row.get('name', '').strip()

                    if audit_name in unchecked_items:
                        print(f"Skipping unchecked audit: {audit_name}")
                        continue

                    category = row.get('type', '').strip().lower()
                    command = row.get('query', '').strip()

                    if not command or not audit_name:
                        continue

                    if category == 'sql':
                        json_query = transform_sql_to_json(command, audit_name)
                        sql_file.write(json_query + "\n")

                    elif category == 'linux':
                        linux_file.write(f"# --- Audit: {audit_name} ---\n")
                        linux_file.write(command + "\n\n")
        
        os.chmod(linux_output_path, stat.S_IRWXU | stat.S_IRGRP | stat.S_IXGRP | stat.S_IROTH | stat.S_IXOTH)
        
        print(f"\nScript generation complete!")
        return sql_output_path

    except FileNotFoundError:
        print(f"\nError: The file '{filepath}' was not found.")
        return None
    except Exception as e:
        print(f"\nAn unexpected error occurred: {e}")
        return None

def main():
    """
    Main function for standalone execution. Parses arguments and handles execution mode.
    """
    parser = argparse.ArgumentParser(description="Process a CSV file to generate or remotely execute audit scripts.")
    parser.add_argument("filepath", help="The path to the input CSV file.")
    parser.add_argument("-d", "--output-dir", default=".", help="The directory where script folders will be generated (default: current directory).")
    args = parser.parse_args()
    
    print("--- PostgreSQL Audit Tool (Standalone Mode) ---")
    
    unchecked_audits = []

    # --- Construct full output paths for standalone use ---
    sql_dir = os.path.join(args.output_dir, 'sql_queries')
    linux_dir = os.path.join(args.output_dir, 'linux_scripts')
    sql_file_path = os.path.join(sql_dir, 'converted_queries.sql')
    linux_file_path = os.path.join(linux_dir, 'all_linux_audits.sh')

    mode = input("Select execution mode ('agent' or 'remote'): ").strip().lower()

    if mode == 'agent':
        print("\nSelected 'agent' mode.")
        process_csv_file(args.filepath, sql_file_path, linux_file_path, unchecked_audits)
        
    elif mode == 'remote':
        print("\nSelected 'remote' mode.")
        
        generated_sql_path = process_csv_file(args.filepath, sql_file_path, linux_file_path, unchecked_audits)
        
        if not generated_sql_path:
            print("Could not proceed with remote execution due to an error during script generation.")
            return
            
        print("\nPlease provide connection details for the remote scan:")
        target = input("Host (target IP address): ")
        username = input("Username: ")
        password = input("Password: ")
        port = input("Port (default is 5432): ")
        
        scan_data = {
            'target': target,
            'username': username,
            'password': password,
            'port': port or '5432'
        }
        
        json_output = 'remote_audit_results.json'
        execute_remote_sql(generated_sql_path, scan_data, json_output)

    else:
        print("Invalid mode selected. Please choose 'agent' or 'remote'.")

if __name__ == '__main__':
    main()
