import pyodbc
import json
import os
from .generate import generate_mssql_work
from .validate_result import validate_mssql  # Your custom module

# # 🔧 Work item names to generate
# excluding_names = []
# input_csv_path = os.path.join(os.path.dirname(__file__), "CIS_standard", "Queries", "query_2019.csv")
# output_sql_path = os.path.join(os.path.dirname(__file__), "CIS_standard", "script.sql")
# generate_mssql_work(excluding_names, input_csv_path, output_sql_path)
# output_sql_path = os.path.join(os.path.dirname(__file__), "CIS_standard", "result.json")
# validate_csv_path = os.path.join(os.path.dirname(__file__), "CIS_standard","Result_Validators","validate_result_2019.csv")
# output_csv_path = os.path.join(os.path.dirname(__file__), "CIS_standard", "script_final.csv")
# validate_mssql(output_sql_path,validate_csv_path,output_csv_path)


def connect(user, password, host, port, database):
    """
    Connects to MSSQL Server using pyodbc.
    """
    try:
        conn_str = (
            f"DRIVER={{SQL Server}};"
            f"SERVER={host},{port};"
            f"DATABASE={database};"
            f"UID={user};"
            f"PWD={password};"
            f"TrustServerCertificate=Yes;"
        )
        conn = pyodbc.connect(conn_str)
        print("✅ Connected to MSSQL via pyodbc as", user)
        return conn
    except Exception as e:
        print(f"❌ Connection Error: {e}")
        return None
def run_script_and_save_json(conn, script_path, json_path):
    cursor = conn.cursor()
    json_found = False  # <-- Track success

    try:
        with open(script_path, 'r', encoding='utf-8') as f:
            query = f.read()

        cursor.execute(query)
        result_index = 0

        while True:
            try:
                if cursor.description:
                    columns = [desc[0] for desc in cursor.description]
                    print(f"📌 Columns: {columns}")
                    rows = cursor.fetchall()
                    print(f"🔢 Rows: {len(rows)}")

                    combined = ''.join(row[0] for row in rows if isinstance(row[0], str)).strip()

                    if combined.startswith('{') or combined.startswith('['):
                        try:
                            json_data = json.loads(combined)
                            with open(json_path, 'w', encoding='utf-8') as out_file:
                                json.dump(json_data, out_file, indent=4)
                            print(f"✅ JSON saved to {json_path}")
                            json_found = True
                            break
                        except json.JSONDecodeError as e:
                            print(f"❌ JSON Decode Error: {e}")
                            with open("query_result_raw.json", 'w', encoding='utf-8') as err_file:
                                err_file.write(combined)
                            print("⚠️ Raw output saved to query_result_raw.json for inspection.")

            except Exception as e:
                print(f"❌ Error processing Result Set #{result_index + 1}: {e}")

            result_index += 1
            if not cursor.nextset():
                break

        if not json_found:
            print("⚠️ No valid JSON output found in any result set.")

    except Exception as e:
        print(f"❌ Error running script: {e}")
    finally:
        cursor.close()

    return json_found  # ✅ Return success flag



if __name__ == "__main__":
    name = ['1_3_Disable_MariaDB_Command_History_Automated_']
    user_name = "rohinth"
    password_name = "rohinth"
    host_name = "192.168.112.168"
    port_number = 1433
    database_name = "master"
    domain_name = ""
    db_access_method = "remote"
    
    base_dir=os.path.dirname(os.path.abspath(__file__))
    maria_db=os.path.join(base_dir,"CIS_standard","Queries","query_MariaDB_10_6.csv")
    sql_commands=os.path.join(base_dir,"script.sql")


    if db_access_method == "remote":
        generate_mssql_work(name)

        conn = connect(
            user=user_name,
            password=password_name,
            host=host_name,
            port=port_number,
            database=database_name
        )

        if conn:
            json_path= os.path.join(base_dir, "CIS_standard", "result_.json")
            script_path= os.path.join(base_dir, "script.sql")
            json_data=run_script_and_save_json(conn, script_path, json_path)
            conn.close()

    elif db_access_method == "agent":
        generate_mssql_work(name)
        # Add agent-based logic here if needed

def mssql_connection(excluded_audit, user_name, password_name, host_name, port_number, database_name, domain_name, db_access_method, csv_path, sql_output, normalized_compliance):
    if db_access_method == "remoteAccess":
        name=excluded_audit
        if normalized_compliance == "microsoftsqlserver2019":
            maria_db_csv_path=os.path.join(os.path.dirname(__file__), "CIS_standard", "Queries", "query_2019.csv")
            sql_commands=os.path.join(os.path.dirname(__file__),"CIS_standard", "output_2019.sql")
            generate_mssql_work(name,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2017":
            maria_db_csv_path=os.path.join(os.path.dirname(__file__), "CIS_standard", "Queries", "query_2017.csv")
            sql_commands=os.path.join(os.path.dirname(__file__),"CIS_standard", "output_2017.sql")
            generate_mssql_work(name,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2016":
            maria_db_csv_path=os.path.join(os.path.dirname(__file__), "CIS_standard", "Queries", "query_2016.csv")
            sql_commands=os.path.join(os.path.dirname(__file__),"CIS_standard", "output_2016.sql")
            generate_mssql_work(name,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2022":
            maria_db_csv_path=os.path.join(os.path.dirname(__file__), "CIS_standard", "Queries", "query_2022.csv")
            sql_commands=os.path.join(os.path.dirname(__file__),"CIS_standard", "output_2022.sql")
            generate_mssql_work(name,maria_db_csv_path,sql_commands)

        conn = connect(
            user=user_name,
            password=password_name,
            host=host_name,
            port=port_number,
            database=database_name
        )

        if conn:
            base_dir=os.path.dirname(os.path.abspath(__file__))
            if normalized_compliance == "microsoftsqlserver2019":
                json_path= os.path.join(base_dir, "CIS_standard", "result_2019.json")
                script_path= os.path.join(base_dir,"CIS_standard", "output_2019.sql")
                json_data=run_script_and_save_json(conn, script_path, json_path)
                conn.close()
            if normalized_compliance == "microsoftsqlserver2017":
                json_path= os.path.join(base_dir, "CIS_standard", "result_2017.json")
                script_path= os.path.join(base_dir,"CIS_standard", "output_2017.sql")
                json_data=run_script_and_save_json(conn, script_path, json_path)
                conn.close()
            if normalized_compliance == "microsoftsqlserver2016":       
                json_path= os.path.join(base_dir, "CIS_standard", "result_2016.json")
                script_path= os.path.join(base_dir,"CIS_standard", "output_2016.sql")
                json_data=run_script_and_save_json(conn, script_path, json_path)
                conn.close()
            if normalized_compliance == "microsoftsqlserver2022":       
                json_path= os.path.join(base_dir, "CIS_standard", "result_2022.json")
                script_path= os.path.join(base_dir,"CIS_standard", "output_2022.sql")
                json_data=run_script_and_save_json(conn, script_path, json_path)
                conn.close()
        print("Connection closed.")

        if json_data:
            print("validating mssql result")
            # Add these file paths (or pass them from above)
            base_dir=os.path.dirname(os.path.abspath(__file__))
            if normalized_compliance == "microsoftsqlserver2019":
                output_sql_path = os.path.join(os.path.dirname(__file__), "CIS_standard", "result_2019.json")
                validate_csv_path = os.path.join(os.path.dirname(__file__), "CIS_standard","Result_Validators","validate_result_2019.csv")
                output_csv_path = os.path.join(os.path.dirname(__file__), "CIS_standard", "script_final.csv")
                validate_mssql(output_sql_path,validate_csv_path,output_csv_path)
            if normalized_compliance == "microsoftsqlserver2017":
                output_sql_path = os.path.join(os.path.dirname(__file__), "CIS_standard", "result_2017.json")
                validate_csv_path = os.path.join(os.path.dirname(__file__), "CIS_standard","Result_Validators","validate_result_2017.csv")
                output_csv_path = os.path.join(os.path.dirname(__file__), "CIS_standard", "script_final.csv")
                validate_mssql(output_sql_path,validate_csv_path,output_csv_path)
            if normalized_compliance == "microsoftsqlserver2016":       
                output_sql_path = os.path.join(os.path.dirname(__file__), "CIS_standard", "result_2016.json")
                validate_csv_path = os.path.join(os.path.dirname(__file__), "CIS_standard","Result_Validators","validate_result_2016.csv")
                output_csv_path = os.path.join(os.path.dirname(__file__), "CIS_standard", "script_final.csv")
                validate_mssql(output_sql_path,validate_csv_path,output_csv_path)
            if normalized_compliance == "microsoftsqlserver2022":
                output_sql_path = os.path.join(os.path.dirname(__file__), "CIS_standard", "result_2022.json")
                validate_csv_path = os.path.join(os.path.dirname(__file__), "CIS_standard","Result_Validators","validate_result_2022.csv")
                output_csv_path = os.path.join(os.path.dirname(__file__), "CIS_standard", "script_final.csv")
                validate_mssql(output_sql_path,validate_csv_path,output_csv_path)

    elif db_access_method == "agent":
        if normalized_compliance == "microsoftsqlserver2019":
            maria_db_csv_path = os.path.join(os.path.dirname(__file__), "CIS_standard", "Queries", "query_2019.csv")
            sql_commands = os.path.join(os.path.dirname(__file__),"CIS_standard", "output_2019.sql")
            generate_mssql_work(excluded_audit,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2017":
            maria_db_csv_path = os.path.join(os.path.dirname(__file__), "CIS_standard", "Queries", "query_2017.csv")
            sql_commands = os.path.join(os.path.dirname(__file__),"CIS_standard", "output_2017.sql")
            generate_mssql_work(excluded_audit,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2016":
            maria_db_csv_path = os.path.join(os.path.dirname(__file__), "CIS_standard", "Queries", "query_2016.csv")
            sql_commands = os.path.join(os.path.dirname(__file__),"CIS_standard", "output_2016.sql")
            generate_mssql_work(excluded_audit,maria_db_csv_path,sql_commands)
        if normalized_compliance == "microsoftsqlserver2022":
            maria_db_csv_path = os.path.join(os.path.dirname(__file__), "CIS_standard", "Queries", "query_2022.csv")
            sql_commands = os.path.join(os.path.dirname(__file__),"CIS_standard", "output_2022.sql")
            generate_mssql_work(excluded_audit,maria_db_csv_path,sql_commands)
            # Add local execution logic if needed
            # Add local execution logic if needed
            # Add local execution logic if needed