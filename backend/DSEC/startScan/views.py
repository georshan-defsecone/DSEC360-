import os
import subprocess
import re
import shutil
from .database.oracle import generate_sql
from .database.Maria import  connection_maria
from .database.MSSQL import remote
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.http import JsonResponse, Http404
import os
import json

def database_config_audit(scan_data):
    print("[*] Entered database_config_audit()")

    # Normalize compliance and standard names
    compliance_name = (scan_data.get("complianceCategory") or "").strip().lower()
    standard = (scan_data.get("complianceSecurityStandard") or "").strip().lower()

    normalized_compliance = re.sub(r'[\W_]+', '', compliance_name)
    normalized_standard = re.sub(r'[\W_]+', '', standard)
    print(f"[DEBUG] normalized_compliance: {normalized_compliance}")
    unchecked_items = scan_data.get("uncheckedComplianceItems", [])

    if normalized_compliance == "oracle":
        try:
            base_dir = os.path.dirname(os.path.abspath(__file__))
            oracle_dir = os.path.join(base_dir,"database","oracle")
            csv_name = "data.csv"
            csv_path = os.path.join(oracle_dir, csv_name)
            sql_output = os.path.join(oracle_dir, "output.sql")
            result_csv=os.path.join(oracle_dir,"result.csv")

            if not os.path.exists(csv_path):
                print(f"[!] CSV input file not found: {csv_path}")
                return None

            # Step 1: Generate the SQL script
            queries = generate_sql.extract_db_queries(csv_path, unchecked_items)
            if not queries:
                print("[!] No queries extracted from CSV.")
                return None

            generate_sql.write_queries_to_file(queries, sql_output, unchecked_items)

            print(f"[+] SQL script generated at: {sql_output}")

            # Step 2: Choose execution method based on auditMethod
            audit_method = (scan_data.get("auditMethod") or "").strip().lower()
            print(audit_method)

            if audit_method == "remoteaccess":
                print("[*] Using remote access method.")
                generate_sql.execute_sql_script_remotely(sql_output, scan_data)
                return result_csv
            elif audit_method == "agent":
                print("[*] Using agent method.")
                return download_script(sql_output)
            else:
                print(f"[-] Unsupported audit method: {audit_method}")
                return None

        except Exception as e:
            print(f"[!] Exception running Oracle audit: {e}")
            return None

    elif normalized_compliance=="mariadb106" or normalized_compliance=="mariadb1011":
        try:
            print(f"[DEBUG] Running MariaDB audit for compliance: {normalized_compliance}")
            base_dir = os.path.dirname(os.path.abspath(__file__))
            Maria_dir = os.path.join(base_dir,"database","Maria")

            excluded_audit = scan_data.get("auditNames") or []
            user_name = scan_data.get("username")
            password_name = scan_data.get("password")
            host_name = scan_data.get("target")
            port_number = scan_data.get("port") or 3306
            domain_name = scan_data.get("domain") or ""
            db_access_method = scan_data.get("auditMethod")
            database_name=scan_data.get("database") or 'mysql'
            print(f"[DEBUG] excluded_audit: {excluded_audit}, user_name: {user_name},password:{password_name}, host_name: {host_name}, port_number: {port_number}, domain_name: {domain_name}, db_access_method: {db_access_method}")
            # Check which version of MariaDB to run

            if normalized_compliance == "mariadb106":
                print("testing mariadb connection for 10.6")
                input_csv_path = os.path.join(Maria_dir, "CIS_standard", "Queries", "MariaDB_10_6_query.csv")
                sql_commands = os.path.join(Maria_dir, "CIS_standard", "MariaDB_10_6_cis_query.sql")
                linux_file = os.path.join(Maria_dir, "CIS_standard", "MariaDB_10_6_linux_commands.sh")
                connection_maria.mariadb_connection(excluded_audit, user_name, password_name, host_name, port_number,database_name, domain_name, db_access_method, input_csv_path, sql_commands, linux_file,normalized_compliance)
                if db_access_method == "agent":
                    path_for_sql = os.path.join(Maria_dir, "CIS_standard", "MariaDB_10_6_cis_query.sql")
                    #path_for_linux = os.path.join(Maria_dir, "CIS_standard", "linux_commands.sh")
                    return download_script(path_for_sql)
            if normalized_compliance == "mariadb1011":
                input_csv_path = os.path.join(Maria_dir, "CIS_standard", "Queries", "MariaDB_10_11_query.csv")
                sql_commands = os.path.join(Maria_dir, "CIS_standard", "MariaDB_10_11_cis_query.sql")
                linux_file = os.path.join(Maria_dir, "CIS_standard", "MariaDB_10_11_linux_commands.sh")
                connection_maria.mariadb_connection(excluded_audit, user_name, password_name, host_name, port_number,database_name, domain_name, db_access_method, input_csv_path, sql_commands, linux_file,normalized_compliance)
                if db_access_method == "agent":
                    path_for_sql = os.path.join(Maria_dir, "CIS_standard", "MariaDB_10_11_cis_query.sql")
                    #path_for_linux = os.path.join(Maria_dir, "CIS_standard", "linux_commands.sh")
                    return download_script(path_for_sql)
        except Exception as e:
            print(f"[!] Exception running Oracle audit: {e}")
            return None
        
    # Check for MSSQL compliance
    elif normalized_compliance == "microsoftsqlserver2019" or normalized_compliance == "microsoftsqlserver2017" or normalized_compliance == "microsoftsqlserver2016" or normalized_compliance == "microsoftsqlserver2022":
        try:
            print("[*] Running MSSQL audit")
            #assining the initial file paths
            base_dir = os.path.dirname(os.path.abspath(__file__))
            mssql_dir = os.path.join(base_dir, "database", "MSSQL")
            #getting the values from the scan_data
            excluded_audit = scan_data.get("auditNames") or []
            user_name = scan_data.get("username")
            password_name = scan_data.get("password")
            host_name = scan_data.get("target")
            port_number = scan_data.get("port") or 1433
            domain_name = scan_data.get("domain") or ""
            db_access_method = scan_data.get("auditMethod")
            database_name=scan_data.get("database") or 'master'

            if normalized_compliance == "microsoftsqlserver2019":
                print("testing mssql connection for 2019")
                remote.mssql_connection(excluded_audit, user_name, password_name, host_name, port_number, database_name, domain_name, db_access_method, normalized_compliance)
                if db_access_method == "agent":
                    path_for_sql=os.path.join(mssql_dir,"CIS_standard","microsoft_sql_server_2019_cis_query.sql")
                    return download_script(path_for_sql)
                
            elif normalized_compliance == "microsoftsqlserver2017":
                remote.mssql_connection(excluded_audit, user_name, password_name, host_name, port_number, database_name, domain_name, db_access_method, normalized_compliance)
                if db_access_method == "agent":
                    path_for_sql=os.path.join(mssql_dir,"CIS_standard","microsoft_sql_server_2017_cis_query.sql")
                    return download_script(path_for_sql)
                
            elif normalized_compliance == "microsoftsqlserver2016":
                remote.mssql_connection(excluded_audit, user_name, password_name, host_name, port_number, database_name, domain_name, db_access_method, normalized_compliance)
                if db_access_method == "agent":
                    path_for_sql=os.path.join(mssql_dir,"CIS_standard","microsoft_sql_server_2016_cis_query.sql")
                    return download_script(path_for_sql)
                
            elif normalized_compliance == "microsoftsqlserver2022":
                remote.mssql_connection(excluded_audit, user_name, password_name, host_name, port_number, database_name, domain_name, db_access_method, normalized_compliance)
                if db_access_method == "agent":
                    path_for_sql=os.path.join(mssql_dir,"CIS_standard","microsoft_sql_server_2022_cis_query.sql")
                    return download_script(path_for_sql)
                

        except Exception as e:
            print(f"[!] Exception running MSSQL audit: {e}")
            return None
    else:
        print(f"[-] Unsupported compliance type: {normalized_compliance}")
        return None

# startScan/utils.py 
# This function downloads the SQL script to a specific location

def download_script(script_path):
    print("[*] Entered download_script()")

    if not script_path or not os.path.isfile(script_path):
        print(f"[-] SQL script file not found: {script_path}")
        return None

    # Use the folder where the script is located
    script_dir = os.path.dirname(script_path)
    download_dir = os.path.join(script_dir, "downloads")
    os.makedirs(download_dir, exist_ok=True)

    dest_path = os.path.join(download_dir, os.path.basename(script_path))

    try:
        shutil.copy(script_path, dest_path)
        print(f"[+] Script copied to download location: {dest_path}")
        return dest_path
    except Exception as e:
        print(f"[!] Failed to copy script for download: {e}")
        return None

    

@api_view(['GET'])
@permission_classes([AllowAny])
def get_json_file(request, filename):
    """
    Returns the content of a JSON file located in a specific directory
    based on the filename passed via the URL.
    """
    json_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'database', 'oracle')
    json_path = os.path.join(json_dir, f'{filename}.json')

    if not os.path.exists(json_path):
        return Response({'error': 'File not found'}, status=404)

    try:
        with open(json_path, 'r') as f:
            data = json.load(f)
        return Response(data)
    except json.JSONDecodeError:
        return Response({'error': 'Invalid JSON file'}, status=400)