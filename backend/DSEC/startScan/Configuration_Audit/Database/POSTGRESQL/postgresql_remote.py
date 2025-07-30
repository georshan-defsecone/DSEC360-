import psycopg2
import json
import re

def execute_remote_sql(sql_filepath, scan_data, json_output_path):
    """
    Connects to a remote PostgreSQL database using details from a scan_data object,
    executes an SQL file, and writes the JSON output to a specified file.
    
    Args:
        sql_filepath: The path to the .sql file to be executed.
        scan_data: A dictionary containing connection and scan metadata.
        json_output_path: The path where the final JSON result file will be saved.
    """
    all_results = []
    
    # --- Extract connection details from the scan_data dictionary ---
    try:
        conn_details = {
            # Use the username as the database name if not otherwise specified, a common default.
            'dbname': scan_data.get('username', 'postgres'), 
            'user': scan_data.get('username'),
            'password': scan_data.get('password'),
            'host': scan_data.get('target'),
            'port': scan_data.get('port') or '5432' # Use default port if empty
        }
        
        # Validate that essential connection details are present
        if not all([conn_details['user'], conn_details['password'], conn_details['host']]):
            print("\nError: The scan_data object is missing essential connection details (username, password, target).")
            return

    except KeyError as e:
        print(f"\nError: The scan_data object is missing a required key: {e}")
        return

    try:
        # Establish the connection
        with psycopg2.connect(**conn_details) as conn:
            print(f"\nSuccessfully connected to {conn_details['host']}.")
            print(f"Executing queries from '{sql_filepath}'...")
            
            # Read the entire file and split by semicolon to handle each query separately
            with open(sql_filepath, 'r') as f:
                sql_script = f.read()
                queries = [q.strip() for q in sql_script.split(';') if q.strip()]

            # Execute each query individually
            for query in queries:
                full_query = query + ';'
                
                audit_name_match = re.search(r"json_build_object\('([^']*)'", full_query)
                audit_name = audit_name_match.group(1) if audit_name_match else "Unknown Query"
                
                with conn.cursor() as cur:
                    try:
                        cur.execute(full_query)
                        result = cur.fetchone()
                        if result:
                            all_results.append(result[0])
                    except psycopg2.Error as e:
                        conn.rollback()
                        error_message = e.pgerror.strip() if e.pgerror else str(e).strip()
                        error_output = {
                            audit_name: {
                                "status": "error",
                                "reason": error_message
                            }
                        }
                        all_results.append(error_output)
                        print(f"\n[!] Error executing audit: '{audit_name}'")
                        print(f"    Reason: {error_message}")

            print("\nExecution complete.")
            
    except FileNotFoundError:
        print(f"Error: The SQL file was not found at '{sql_filepath}'.")
        return
    except psycopg2.OperationalError as e:
        print(f"\nConnection Error: Could not connect to the database. Please check the details.")
        print(f"Details: {e}")
        return
    except Exception as e:
        print(f"\nAn unexpected error occurred during execution: {e}")
        return
        
    # --- Process and save the final results to the specified output file ---
    if all_results:
        final_json = {}
        for item in all_results:
            if item: # Ensure item is not None before updating
                final_json.update(item)

        try:
            with open(json_output_path, 'w') as f:
                json.dump(final_json, f, indent=4)
            print(f"\nSuccess! All results have been saved to '{json_output_path}'.")
        except IOError as e:
            print(f"\nError writing results to '{json_output_path}': {e}")
    else:
        print("\nExecution did not yield any results to save.")

