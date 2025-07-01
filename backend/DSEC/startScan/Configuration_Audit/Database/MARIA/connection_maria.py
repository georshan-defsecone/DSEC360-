import sys
import json
import os
import re
from .generate import generate_mariadb_work_remote
from .generate import generate_mariadb_work
from .validate import validate_maria_db

import pymysql

def connect(user, password, host, port, database, domain=None):
    try:
        full_user = f"{domain}\\{user}" if domain else user
        conn = pymysql.connect(
            user=full_user,
            password=password,
            host=host,
            port=port,
            database=database,
            autocommit=True
        )
        print("✅ Connected to MariaDB via PyMySQL as", full_user)
        return conn
    except pymysql.MySQLError as e:
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

def convert_title_to_check_name(title: str) -> str:
        # Extract number (e.g., 1.2 or 2.1.5) and rest of the title
        match = re.match(r"(\d+(?:\.\d+)*)(?:\s+)(.+?)\s*\(Automated\)", title)
        if not match:
            return None  # invalid format

        number_part = match.group(1).replace('.', '_')  # 1.2 -> 1_2
        text_part = match.group(2)

        # Replace special chars with underscore-friendly equivalents
        text_part = re.sub(r"[^a-zA-Z0-9]", "_", text_part)
        text_part = re.sub(r"_+", "_", text_part).strip("_")

        return f"{number_part}_{text_part}_Automated_"

def mariadb_connection(excluded_audit, user_name, password_name, host_name, port_number,
                      database_name, domain_name, db_access_method,maria_db_csv_path,sql_commands,linux_file,normalized_compliance):
    name=[]
    for i in excluded_audit:
        temp=convert_title_to_check_name(i)
        name.append(temp)
    print(f"Converted name: {name}")

    if db_access_method == "remoteAccess":
        
        generate_mariadb_work_remote(name,maria_db_csv_path,sql_commands)
        port_number=int(port_number) if port_number else 3306  

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
            print(f"Base directory: {base_dir}")
            if normalized_compliance == "mariadb106":
                script_path = os.path.join(base_dir,"CIS", "MariaDB_10_6_cis_query.sql")
                json_path = os.path.join(base_dir, "CIS", "mariaDB_10_6_query_result.json")
                json_data = run_script_and_save_json(conn, script_path, json_path)
            elif normalized_compliance == "mariadb1011":
                script_path = os.path.join(base_dir,"CIS", "MariaDB_10_11_cis_query.sql")
                json_path = os.path.join(base_dir, "CIS", "mariaDB_10_11_query_result.json")
                json_data = run_script_and_save_json(conn, script_path, json_path)

            conn.close()
            print(json_data)
            if json_data:
                # Add these file paths (or pass them from above)
                if normalized_compliance== "mariadb106":
                    validate_csv = os.path.join(base_dir, "CIS","Validators","MariaDB_10_6_validate.csv")
                    json_path= os.path.join(base_dir, "CIS", "mariaDB_10_6_query_result.json")  # ⬅️ adjust filename as needed
                    report_csv = os.path.join(base_dir, "CIS","MariaDB_10_6_report.csv")
                elif normalized_compliance == "mariadb1011":
                    validate_csv = os.path.join(base_dir, "CIS","Validators","MariaDB_10_11_validate.csv")
                    json_path= os.path.join(base_dir, "CIS", "mariaDB_10_11_query_result.json")
                    report_csv = os.path.join(base_dir, "CIS","MariaDB_10_11_report.csv")
                     # ⬅️ adjust filename as needed
                validate_maria_db(json_path, validate_csv, report_csv)


    elif db_access_method == "agent":
        generate_mariadb_work(name,maria_db_csv_path,sql_commands,linux_file)
        # Add local execution logic if needed

