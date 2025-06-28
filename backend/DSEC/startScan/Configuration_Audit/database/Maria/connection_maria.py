import sys
import mariadb
import json
import os
from .generate import generate_mariadb_work_remote
from .generate import generate_mariadb_work
from .validate import validate_maria_db

def connect(user, password, host, port, database, domain=None):
    try:
        full_user = f"{domain}\\{user}" if domain else user
        conn = mariadb.connect(
            user=full_user,
            password=password,
            host=host,
            port=port,
            database=database,
            autocommit=True
        )
        print("✅ Connected to MariaDB as", full_user)
        return conn
    except mariadb.Error as e:
        print(f"❌ Connection Error: {e}")
        return None

def run_script_and_save_json(conn, script_path, json_path):
    print(f"Running script: {script_path}")
    cursor = conn.cursor()
    try:
        with open(script_path, 'r') as f:
            query = f.read()

        cursor.execute(query)
        row = cursor.fetchone()

        if row and row[0]:
            json_data = json.loads(row[0])
            with open(json_path, 'w', encoding='utf-8') as out_file:
                json.dump(json_data, out_file, indent=4)
            print(f"✅ JSON saved to {json_path}")
            return json_data  # ✅ Return parsed JSON
        else:
            print("⚠️ No JSON output returned.")
            return None
    except Exception as e:
        print(f"❌ Error running script: {e}")
        return None
    finally:
        cursor.close()
import os

def get_base_dir(override=None):
    if override and os.path.isdir(override):
        return os.path.abspath(override)  # user-defined, valid directory
    try:
        return os.path.dirname(os.path.abspath(__file__))  # script directory
    except NameError:
        return os.getcwd()  # fallback for environments like Jupyter



def mariadb_connection(name, user_name, password_name, host_name, port_number,
                      database_name, domain_name, db_access_method,maria_db_csv_path,sql_commands,linux_file,normalized_compliance):
    if db_access_method == "remoteAccess":
        
        generate_mariadb_work_remote(name,maria_db_csv_path,sql_commands)

        conn = connect(
            user=user_name,
            password=password_name,
            host=host_name,
            port=port_number,
            database=database_name,
            domain=domain_name
        )

        if conn:
            base_dir = get_base_dir()
            if normalized_compliance == "mariadb106":
                script_path = os.path.join(base_dir,"CIS_standard", "MariaDB_10_6_cis_query.sql")
                json_path = os.path.join(base_dir, "CIS_standard", "mariaDB_10_6_query_result.json")
                json_data = run_script_and_save_json(conn, script_path, json_path)
            elif normalized_compliance == "mariadb1011":
                script_path = os.path.join(base_dir,"CIS_standard", "MariaDB_10_11_cis_query.sql")
                json_path = os.path.join(base_dir, "CIS_standard", "mariaDB_10_11_query_result.json")
                json_data = run_script_and_save_json(conn, script_path, json_path)

            conn.close()
            print(json_data)
            if json_data:
                # Add these file paths (or pass them from above)
                if normalized_compliance== "mariadb106":
                    validate_csv = os.path.join(base_dir, "CIS_standard","Validators","MariaDB_10_6_validate.csv")
                    json_path= os.path.join(base_dir, "CIS_standard", "mariaDB_10_6_query_result.json")  # ⬅️ adjust filename as needed
                    report_csv = os.path.join(base_dir, "CIS_standard","MariaDB_10_6_report.csv")
                elif normalized_compliance == "mariadb1011":
                    validate_csv = os.path.join(base_dir, "CIS_standard","Validators","MariaDB_10_11_validate.csv")
                    json_path= os.path.join(base_dir, "CIS_standard", "mariaDB_10_11_query_result.json") 
                    report_csv = os.path.join(base_dir, "CIS_standard","MariaDB_10_11_report.csv")
                     # ⬅️ adjust filename as needed
                validate_maria_db(json_path, validate_csv, report_csv)


    elif db_access_method == "agent":
        generate_mariadb_work(name,maria_db_csv_path,sql_commands,linux_file)
        # Add local execution logic if needed


# ✅ Support command-line usage
if __name__ == "__main__":
    # Default values
    name = ['1_3_Disable_MariaDB_Command_History_Automated_']
    user_name = "root"
    password_name = "rohinth"
    host_name = "192.168.147.57"
    port_number = 3306
    database_name = "mysql"
    domain_name = ""
    db_access_method = "remote"
    
    base_dir=get_base_dir()  # Get the base directory dynamically
    maria_db=os.path.join(base_dir,"CIS_standard","Queries","query_MariaDB_10_6.csv")
    sql_commands=os.path.join(base_dir,"CIS_standard","script.sql")
    linux_file=os.path.join(base_dir,"CIS_standard","linux_commands.sh")

    if db_access_method == "remote":
        generate_mariadb_work_remote(name,maria_db,sql_commands)

        conn = connect(
            user=user_name,
            password=password_name,
            host=host_name,
            port=port_number,
            database=database_name,
            domain=domain_name
        )

        if conn:
            sql_commands= os.path.join(base_dir, "CIS_standard", "script.sql")
            json_data=run_script_and_save_json(conn, sql_commands)
            conn.close()
            if json_data:
                # Add these file paths (or pass them from above)
                base_dir=os.path.dirname(os.path.abspath(__file__))
                validate_csv = os.path.join(base_dir, "CIS_standard","Validators","validate_MariaDB_10_6.csv")  # ⬅️ adjust filename as needed
                report_csv = os.path.join(base_dir, "CIS_standard","report.csv")
                json_data= os.path.join(base_dir, "CIS_standard", "query_result.json")  # ⬅️ adjust filename as needed

                # json_data=os.path.join(base_dir, "CIS_standard","json_data.json")           # ⬅️ adjust filename as needed
                validate_maria_db(json_data, validate_csv, report_csv)


    elif db_access_method == "agent":
        generate_mariadb_work(name,maria_db,sql_commands,linux_file)

    # Get output file from command-line (optional)
    