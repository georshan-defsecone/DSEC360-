import os
import sys
import csv
import re
import oracledb
import getpass
from .Configuration_Audit.Database.ORACLE import oraclevalidate
from .Configuration_Audit.Database.MARIA import connection_maria,validate,generate_maria
from .Configuration_Audit.Database.MSSQL import remote,validate_result,generate
import importlib
from fabric import Connection, Config
import os

def oracle_connection(sql_file, connection_info, output_json_path, result_csv_path):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    check_csv_path = os.path.join(script_dir, "Configuration_Audit", "Database", "ORACLE", "CIS", "Validators", "check.csv")
    print("the result path for testing ",result_csv_path)

    host = connection_info.get("target", "")
    port = connection_info.get("port", "1521")
    service_name = connection_info.get("service_name", "")
    user = connection_info.get("username", "")
    password = connection_info.get("password", "")

    dsn = f"{host}:{port}/{service_name}"
    print(f"Connecting to DSN: {dsn}")

    all_output_lines = []

    try:
        with oracledb.connect(user=user, password=password, dsn=dsn) as connection:
            with connection.cursor() as cursor:
                cursor.callproc("dbms_output.enable")
                print(f"\n📤 Executing {sql_file} on remote Oracle DB...\n")
                with open(sql_file, 'r') as f:
                    statement = ""
                    for line in f:
                        stripped = line.strip()
                        if stripped.upper().startswith("SET SERVEROUTPUT") or stripped.startswith("--"):
                            continue
                        if stripped == "/" and statement.strip():
                            try:
                                cursor.execute(statement)
                                while True:
                                    line_arr = cursor.arrayvar(str, 100)
                                    numlines = cursor.var(int)
                                    numlines.setvalue(0, 100)
                                    cursor.callproc("dbms_output.get_lines", [line_arr, numlines])
                                    lines = line_arr.getvalue()
                                    for line in lines:
                                        if line:
                                            print(line)
                                            all_output_lines.append(line)
                                    if numlines.getvalue() < 100:
                                        break
                            except Exception as e:
                                print(f"❌ Error executing block:\n{statement}\n--> {e}")
                            statement = ""
                        else:
                            statement += line
                print("\n✅ Execution completed.")

        if all_output_lines:
            with open(output_json_path, "w", encoding="utf-8", errors="replace") as out_json:
                out_json.write("[\n" + ",\n".join(all_output_lines) + "\n]\n")
            print(f"📝 JSON output written to {output_json_path}")

            
            print("🧪 Running validate.validate(...) directly...")
            expected = oraclevalidate.load_csv(check_csv_path)
            oraclevalidate.validate(output_json_path, expected, result_csv_path)
            print(f"✅ Validation completed and written to {result_csv_path}")
        else:
            print("⚠️ No output captured from DBMS_OUTPUT.")
    except Exception as e:
        print(f"\n❌ Failed to connect or execute SQL: {e}")


def mariadb_connection(result_csv,excluded_audit, user_name, password_name, host_name, port_number,
                      database_name, domain_name, db_access_method,maria_db_csv_path,sql_commands,linux_file,normalized_compliance):
    name=[]
    for i in excluded_audit:
        temp=connection_maria.convert_title_to_check_name(i)
        name.append(temp)
    print(f"Converted name: {name}")

    if db_access_method == "remoteAccess":
        
        generate_maria.generate_mariadb_work_remote(name,maria_db_csv_path,sql_commands)
        port_number=int(port_number) if port_number else 3306  

        conn = connection_maria.connect(
            user=user_name,
            password=password_name,
            host=host_name,
            port=port_number,
            database=database_name,
            domain=domain_name
        )

        if conn:
            base_dir = os.path.dirname(os.path.abspath(__file__))
            print(f"Base directory: {base_dir}")
            if normalized_compliance == "mariadb106":
                script_path = os.path.join(base_dir,"Configuration_Audit","Database","MARIA","CIS", "MariaDB_10_6_cis_query.sql")
                json_path = os.path.join(base_dir,"Configuration_Audit","Database","MARIA","CIS", "mariaDB_10_6_query_result.json")
                json_data = connection_maria.run_script_and_save_json(conn, script_path, json_path)
            elif normalized_compliance == "mariadb1011":
                script_path = os.path.join(base_dir,"Configuration_Audit","Database","MARIA","CIS", "MariaDB_10_11_cis_query.sql")
                json_path = os.path.join(base_dir,"Configuration_Audit","Database","MARIA", "CIS", "mariaDB_10_11_query_result.json")
                json_data = connection_maria.run_script_and_save_json(conn, script_path, json_path)

            conn.close()
            print(json_data)
            if json_data:
                # Add these file paths (or pass them from above)
                if normalized_compliance== "mariadb106":
                    validate_csv = os.path.join(base_dir,"Configuration_Audit","Database","MARIA", "CIS","Validators","MariaDB_10_6_validate.csv")
                    json_path= os.path.join(base_dir,"Configuration_Audit","Database","MARIA", "CIS", "mariaDB_10_6_query_result.json")  # ⬅️ adjust filename as needed
                    report_csv = result_csv
                elif normalized_compliance == "mariadb1011":
                    validate_csv = os.path.join(base_dir,"Configuration_Audit","Database","MARIA", "CIS","Validators","MariaDB_10_11_validate.csv")
                    json_path= os.path.join(base_dir,"Configuration_Audit","Database","MARIA", "CIS", "mariaDB_10_11_query_result.json")
                    report_csv = result_csv
                     # ⬅️ adjust filename as needed
                validate.validate_maria_db(json_path, validate_csv, report_csv)


    elif db_access_method == "agent":
        generate_maria.generate_mariadb_work(name,maria_db_csv_path,sql_commands,linux_file)
        # Add local execution logic if needed


def mssql_connection(result_csv,excluded_audit, user_name, password_name, host_name, port_number, database_name, domain_name, db_access_method, normalized_compliance):
    if db_access_method == "remoteAccess":
        name=excluded_audit
        if normalized_compliance == "microsoftsqlserver2019":
            maria_db_csv_path=os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL","CIS", "Queries", "microsoft_sql_server_2019_query.csv")
            sql_commands=os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL","CIS", "microsoft_sql_server_2019_cis_query.sql")
            generate.generate_mssql_work(name,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2017":
            maria_db_csv_path=os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL","CIS", "Queries", "microsoft_sql_server_2017_query.csv")
            sql_commands=os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL","CIS", "microsoft_sql_server_2017_cis_query.sql")
            generate.generate_mssql_work(name,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2016":
            maria_db_csv_path=os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL","CIS", "Queries", "microsoft_sql_server_2016_query.csv")
            sql_commands=os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL","CIS", "microsoft_sql_server_2016_cis_query.sql")
            generate.generate_mssql_work(name,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2022":
            maria_db_csv_path=os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL","CIS", "Queries", "microsoft_sql_server_2022_query.csv")
            sql_commands=os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL","CIS", "microsoft_sql_server_2022_cis_query.sql")
            generate.generate_mssql_work(name,maria_db_csv_path,sql_commands)

        conn = remote.connect(
            user=user_name,
            password=password_name,
            host=host_name,
            port=port_number,
            database=database_name
        )

        if conn:
            base_dir=os.path.dirname(os.path.abspath(__file__))
            if normalized_compliance == "microsoftsqlserver2019":
                json_path= os.path.join(base_dir,"Configuration_Audit","Database","MSSQL", "CIS", "microsoft_sql_server_2019_query_result.json")
                script_path= os.path.join(base_dir,"Configuration_Audit","Database","MSSQL","CIS", "microsoft_sql_server_2019_cis_query.sql")
                json_data=remote.run_script_and_save_json(conn, script_path, json_path)
                conn.close()
            if normalized_compliance == "microsoftsqlserver2017":
                json_path= os.path.join(base_dir,"Configuration_Audit","Database","MSSQL", "CIS", "microsoft_sql_server_2017_query_result.json")
                script_path= os.path.join(base_dir,"Configuration_Audit","Database","MSSQL","CIS", "microsoft_sql_server_2017_cis_query.sql")
                json_data=remote.run_script_and_save_json(conn, script_path, json_path)
                conn.close()
            if normalized_compliance == "microsoftsqlserver2016":       
                json_path= os.path.join(base_dir,"Configuration_Audit","Database","MSSQL", "CIS", "microsoft_sql_server_2016_query_result.json")
                script_path= os.path.join(base_dir,"Configuration_Audit","Database","MSSQL","CIS", "microsoft_sql_server_2016_cis_query.sql")
                json_data=remote.run_script_and_save_json(conn, script_path, json_path)
                conn.close()
            if normalized_compliance == "microsoftsqlserver2022":       
                json_path= os.path.join(base_dir,"Configuration_Audit","Database","MSSQL", "CIS", "microsoft_sql_server_2022_query_result.json")
                script_path= os.path.join(base_dir,"Configuration_Audit","Database","MSSQL","CIS", "microsoft_sql_server_2022_cis_query.sql")
                json_data=remote.run_script_and_save_json(conn, script_path, json_path)
                conn.close()
        print("Connection closed.")

        if json_data:
            print("validating mssql result")
            # Add these file paths (or pass them from above)
            base_dir=os.path.dirname(os.path.abspath(__file__))
            if normalized_compliance == "microsoftsqlserver2019":
                output_sql_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL", "CIS", "microsoft_sql_server_2019_query_result.json")
                validate_csv_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL", "CIS","Result_Validators","microsoft_sql_server_2019_validator.csv")
                output_csv_path = result_csv
                validate_result.validate_mssql(output_sql_path,validate_csv_path,output_csv_path)
            if normalized_compliance == "microsoftsqlserver2017":
                output_sql_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL", "CIS", "microsoft_sql_server_2017_query_result.json")
                validate_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL", "CIS","Result_Validators","microsoft_sql_server_2017_validator.csv")
                output_csv_path =result_csv
                validate_result.validate_mssql(output_sql_path,validate_csv_path,output_csv_path)
            if normalized_compliance == "microsoftsqlserver2016":       
                output_sql_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL", "CIS", "microsoft_sql_server_2016_query_result.json")
                validate_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL", "CIS","Result_Validators","microsoft_sql_server_2016_validator.csv")
                output_csv_path =result_csv
                validate_result.validate_mssql(output_sql_path,validate_csv_path,output_csv_path)
            if normalized_compliance == "microsoftsqlserver2022":
                output_sql_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL", "CIS", "microsoft_sql_server_2022_query_result.json")
                validate_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL", "CIS","Result_Validators","microsoft_sql_server_2022_validator.csv")
                output_csv_path =result_csv
                validate_result.validate_mssql(output_sql_path,validate_csv_path,output_csv_path)

    elif db_access_method == "agent":
        if normalized_compliance == "microsoftsqlserver2019":
            maria_db_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL", "CIS", "Queries", "microsoft_sql_server_2019_query.csv")
            sql_commands =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL","CIS", "microsoft_sql_server_2019_cis_query.sql")
            generate.generate_mssql_work(excluded_audit,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2017":
            maria_db_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL", "CIS", "Queries", "microsoft_sql_server_2017_query.csv")
            sql_commands =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL","CIS", "microsoft_sql_server_2017_cis_query.sql")
            generate.generate_mssql_work(excluded_audit,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2016":
            maria_db_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL", "CIS", "Queries", "microsoft_sql_server_2016_query.csv")
            sql_commands =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL","CIS", "microsoft_sql_server_2016_cis_query.sql")
            generate.generate_mssql_work(excluded_audit,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2022":
            maria_db_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL", "CIS", "Queries", "microsoft_sql_server_2022_query.csv")
            sql_commands =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","Database","MSSQL","CIS", "microsoft_sql_server_2022_cis_query.sql")
            generate.generate_mssql_work(excluded_audit,maria_db_csv_path,sql_commands)



# In remote.py
import os
from fabric import Connection, Config

def linux_connection(script_path, username, password, ip, port, remote_result_name, local_result_path):
    """
    Uploads and executes a script, then downloads the resulting JSON or TSV output.
    It returns the local path of the successfully downloaded file.
    """
    # Use the basename of the script for the remote path
    remote_script_path = f"/tmp/{os.path.basename(script_path)}"

    config = Config(overrides={"sudo": {"password": password}})
    conn = Connection(
        host=ip,
        user=username,
        port=port,
        connect_kwargs={
            "password": password,
            "allow_agent": False,
            "look_for_keys": False,
        },
        config=config
    )

    print(f"Uploading script: {script_path} → {remote_script_path}")
    conn.put(script_path, remote=remote_script_path)
    conn.run(f"chmod +x {remote_script_path}")

    print("Running script remotely with sudo...")
    result = conn.sudo(remote_script_path, pty=True)
    print("stdout:\n", result.stdout)
    print("stderr:\n", result.stderr)

    # --- Start of Modified Logic ---

    # Define potential remote and local paths for both JSON and TSV
    remote_json_path = f"/tmp/{remote_result_name}"
    remote_tsv_path = f"/tmp/{remote_result_name.replace('.json', '.tsv')}"

    local_json_path = local_result_path
    local_tsv_path = local_result_path.replace('.json', '.tsv')
    
    downloaded_file = None

    print("Attempting to download result file...")
    try:
        # 1. Attempt to download the JSON file first
        print(f"Trying to download {remote_json_path}...")
        conn.get(remote_json_path, local=local_json_path)
        print(f"Result saved to: {local_json_path}")
        downloaded_file = local_json_path
        conn.sudo(f"rm -f {remote_json_path}", pty=True) # Clean up the remote file
    except Exception:
        print(f"Could not download JSON file. Trying TSV instead.")
        try:
            # 2. If JSON fails, attempt to download the TSV file
            print(f"Trying to download {remote_tsv_path}...")
            conn.get(remote_tsv_path, local=local_tsv_path)
            print(f"Result saved to: {local_tsv_path}")
            downloaded_file = local_tsv_path
            conn.sudo(f"rm -f {remote_tsv_path}", pty=True) # Clean up the remote file
        except Exception as e2:
            print(f"Could not download TSV file either: {e2}")

    print("Cleaning up remote script...")
    conn.sudo(f"rm -f {remote_script_path}", pty=True)
    conn.close()
    
    # Return the path of the file that was found, or None
    return downloaded_file

    # --- End of Modified Logic ---