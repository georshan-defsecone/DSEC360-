import os
import sys
import csv
import re
import oracledb
import getpass
from .Configuration_Audit.database.ORACLE import validate
from .Configuration_Audit.database.maria import connection_maria,validate,generate
from .Configuration_Audit.database.mssql import remote,validate_result,generate
import importlib
from fabric import Connection, Config
import os

def oracle_connection(sql_file, connection_info):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_json_path = os.path.join(script_dir,"Configuration_Audit","database","ORACLE","CIS","output.json")
    check_csv_path = os.path.join(script_dir,"Configuration_Audit","database","ORACLE","CIS","Validators","check.csv")
    result_csv_path = os.path.join(script_dir,"Configuration_Audit","database","ORACLE","CIS","result.csv")
    print(result_csv_path)

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
                with open(sql_file, 'r', encoding='utf-8') as f:
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
            with open(output_json_path, "w", encoding="utf-8") as out_json:
                out_json.write("[\n" + ",\n".join(all_output_lines) + "\n]\n")
            print(f"📝 JSON output written to {output_json_path}")

            try:
                print("🧪 Running validate.validate(...) directly...")
                expected = validate.load_csv(check_csv_path)
                validate.validate(output_json_path, expected, result_csv_path)
                print(f"✅ Validation completed and written to {result_csv_path}")
            except Exception as e:
                print(f"❌ Error during validation: {e}")
        else:
            print("⚠️ No output captured from DBMS_OUTPUT.")
    except Exception as e:
        print(f"\n❌ Failed to connect or execute SQL: {e}")


def mariadb_connection(excluded_audit, user_name, password_name, host_name, port_number,
                      database_name, domain_name, db_access_method,maria_db_csv_path,sql_commands,linux_file,normalized_compliance):
    name=[]
    for i in excluded_audit:
        temp=connection_maria.convert_title_to_check_name(i)
        name.append(temp)
    print(f"Converted name: {name}")

    if db_access_method == "remoteAccess":
        
        generate.generate_mariadb_work_remote(name,maria_db_csv_path,sql_commands)
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
                script_path = os.path.join(base_dir,"Configuration_Audit","database","maria","CIS", "MariaDB_10_6_cis_query.sql")
                json_path = os.path.join(base_dir,"Configuration_Audit","database","maria","CIS", "mariaDB_10_6_query_result.json")
                json_data = connection_maria.remote.run_script_and_save_json(conn, script_path, json_path)
            elif normalized_compliance == "mariadb1011":
                script_path = os.path.join(base_dir,"Configuration_Audit","database","maria","CIS", "MariaDB_10_11_cis_query.sql")
                json_path = os.path.join(base_dir,"Configuration_Audit","database","maria", "CIS", "mariaDB_10_11_query_result.json")
                json_data = connection_maria.remote.run_script_and_save_json(conn, script_path, json_path)

            conn.close()
            print(json_data)
            if json_data:
                # Add these file paths (or pass them from above)
                if normalized_compliance== "mariadb106":
                    validate_csv = os.path.join(base_dir,"Configuration_Audit","database","maria", "CIS","Validators","MariaDB_10_6_validate.csv")
                    json_path= os.path.join(base_dir,"Configuration_Audit","database","maria", "CIS", "mariaDB_10_6_query_result.json")  # ⬅️ adjust filename as needed
                    report_csv = os.path.join(base_dir,"Configuration_Audit","database","maria" ,"CIS","MariaDB_10_6_report.csv")
                elif normalized_compliance == "mariadb1011":
                    validate_csv = os.path.join(base_dir,"Configuration_Audit","database","maria", "CIS","Validators","MariaDB_10_11_validate.csv")
                    json_path= os.path.join(base_dir,"Configuration_Audit","database","maria", "CIS", "mariaDB_10_11_query_result.json")
                    report_csv = os.path.join(base_dir, "Configuration_Audit","database","maria","CIS","MariaDB_10_11_report.csv")
                     # ⬅️ adjust filename as needed
                validate.validate_maria_db(json_path, validate_csv, report_csv)


    elif db_access_method == "agent":
        connection_maria.generate_mariadb_work(name,maria_db_csv_path,sql_commands,linux_file)
        # Add local execution logic if needed


def mssql_connection(excluded_audit, user_name, password_name, host_name, port_number, database_name, domain_name, db_access_method, normalized_compliance):
    if db_access_method == "remoteAccess":
        name=excluded_audit
        if normalized_compliance == "microsoftsqlserver2019":
            maria_db_csv_path=os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql","CIS", "Queries", "microsoft_sql_server_2019_query.csv")
            sql_commands=os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql","CIS", "microsoft_sql_server_2019_cis_query.sql")
            generate.generate_mssql_work(name,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2017":
            maria_db_csv_path=os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql","CIS", "Queries", "microsoft_sql_server_2017_query.csv")
            sql_commands=os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql","CIS", "microsoft_sql_server_2017_cis_query.sql")
            generate.generate_mssql_work(name,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2016":
            maria_db_csv_path=os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql","CIS", "Queries", "microsoft_sql_server_2016_query.csv")
            sql_commands=os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql","CIS", "microsoft_sql_server_2016_cis_query.sql")
            generate.generate_mssql_work(name,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2022":
            maria_db_csv_path=os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql","CIS", "Queries", "microsoft_sql_server_2022_query.csv")
            sql_commands=os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql","CIS", "microsoft_sql_server_2022_cis_query.sql")
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
                json_path= os.path.join(base_dir,"Configuration_Audit","database","mssql", "CIS", "microsoft_sql_server_2019_query_result.json")
                script_path= os.path.join(base_dir,"Configuration_Audit","database","mssql","CIS", "microsoft_sql_server_2019_cis_query.sql")
                json_data=remote.run_script_and_save_json(conn, script_path, json_path)
                conn.close()
            if normalized_compliance == "microsoftsqlserver2017":
                json_path= os.path.join(base_dir,"Configuration_Audit","database","mssql", "CIS", "microsoft_sql_server_2017_query_result.json")
                script_path= os.path.join(base_dir,"Configuration_Audit","database","mssql","CIS", "microsoft_sql_server_2017_cis_query.sql")
                json_data=remote.run_script_and_save_json(conn, script_path, json_path)
                conn.close()
            if normalized_compliance == "microsoftsqlserver2016":       
                json_path= os.path.join(base_dir,"Configuration_Audit","database","mssql", "CIS", "microsoft_sql_server_2016_query_result.json")
                script_path= os.path.join(base_dir,"Configuration_Audit","database","mssql","CIS", "microsoft_sql_server_2016_cis_query.sql")
                json_data=remote.run_script_and_save_json(conn, script_path, json_path)
                conn.close()
            if normalized_compliance == "microsoftsqlserver2022":       
                json_path= os.path.join(base_dir,"Configuration_Audit","database","mssql", "CIS", "microsoft_sql_server_2022_query_result.json")
                script_path= os.path.join(base_dir,"Configuration_Audit","database","mssql","CIS", "microsoft_sql_server_2022_cis_query.sql")
                json_data=remote.run_script_and_save_json(conn, script_path, json_path)
                conn.close()
        print("Connection closed.")

        if json_data:
            print("validating mssql result")
            # Add these file paths (or pass them from above)
            base_dir=os.path.dirname(os.path.abspath(__file__))
            if normalized_compliance == "microsoftsqlserver2019":
                output_sql_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql", "CIS", "microsoft_sql_server_2019_query_result.json")
                validate_csv_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql", "CIS","Result_Validators","microsoft_sql_server_2019_validator.csv")
                output_csv_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql", "CIS", "microsoft_sql_server_2019_report.csv")
                validate_result.validate_mssql(output_sql_path,validate_csv_path,output_csv_path)
            if normalized_compliance == "microsoftsqlserver2017":
                output_sql_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql", "CIS", "microsoft_sql_server_2017_query_result.json")
                validate_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql", "CIS","Result_Validators","microsoft_sql_server_2017_validator.csv")
                output_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql", "CIS", "microsoft_sql_server_2017_report.csv")
                validate_result.validate_mssql(output_sql_path,validate_csv_path,output_csv_path)
            if normalized_compliance == "microsoftsqlserver2016":       
                output_sql_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql", "CIS", "microsoft_sql_server_2016_query_result.json")
                validate_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql", "CIS","Result_Validators","microsoft_sql_server_2016_validator.csv")
                output_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql", "CIS", "microsoft_sql_server_2016_report.csv")
                validate_result.validate_mssql(output_sql_path,validate_csv_path,output_csv_path)
            if normalized_compliance == "microsoftsqlserver2022":
                output_sql_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql", "CIS", "microsoft_sql_server_2022_query_result.json")
                validate_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql", "CIS","Result_Validators","microsoft_sql_server_2022_validator.csv")
                output_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql", "CIS", "microsoft_sql_server_2022_report.csv")
                validate_result.validate_mssql(output_sql_path,validate_csv_path,output_csv_path)

    elif db_access_method == "agent":
        if normalized_compliance == "microsoftsqlserver2019":
            maria_db_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql", "CIS", "Queries", "microsoft_sql_server_2019_query.csv")
            sql_commands =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql","CIS", "microsoft_sql_server_2019_cis_query.sql")
            generate.generate_mssql_work(excluded_audit,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2017":
            maria_db_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql", "CIS", "Queries", "microsoft_sql_server_2017_query.csv")
            sql_commands =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql","CIS", "microsoft_sql_server_2017_cis_query.sql")
            generate.generate_mssql_work(excluded_audit,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2016":
            maria_db_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql", "CIS", "Queries", "microsoft_sql_server_2016_query.csv")
            sql_commands =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql","CIS", "microsoft_sql_server_2016_cis_query.sql")
            generate.generate_mssql_work(excluded_audit,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2022":
            maria_db_csv_path =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql", "CIS", "Queries", "microsoft_sql_server_2022_query.csv")
            sql_commands =os.path.join(os.path.dirname(os.path.abspath(__file__)),"Configuration_Audit","database","mssql","CIS", "microsoft_sql_server_2022_cis_query.sql")
            generate.generate_mssql_work(excluded_audit,maria_db_csv_path,sql_commands)



def linux_connection(script_name, username, password, ip, port, result_name="results.json"):
    """
    Uploads and executes a local Bash audit script on a remote host using sudo,
    then downloads the resulting JSON output back to the local system.
    """

    remote_script_path=f"/tmp/{script_name}"
    remote_result_path=f"/tmp/{result_name}"
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    local_result_path=os.path.join(BASE_DIR, result_name)

    config = Config(overrides={"sudo":{"password":password}})
    conn = Connection(
        host=ip,
        user=username,
        port=port,
        connect_kwargs={"password":password},
        config=config
    )

    print(f"Uploading script: {script_name} → {remote_script_path}")
    conn.put(script_name, remote=remote_script_path)
    conn.run(f"chmod +x {remote_script_path}")

    print("Running script remotely with sudo...")
    result = conn.sudo(remote_script_path, pty=True)

    print("stdout:\n", result.stdout)
    print("stderr:\n", result.stderr)

    print("Downloading result JSON from remote...")
    conn.get(remote_result_path, local=local_result_path)
    print(f"Result saved to: {local_result_path}")

    print("Cleaning up remote files...")
    conn.sudo(f"rm -f {remote_script_path} {remote_result_path}", pty=True)

    conn.close()
