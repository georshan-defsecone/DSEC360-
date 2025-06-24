import os
import subprocess
import re
import shutil
from .database.oracle import generate_sql
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
            json_output = os.path.join(oracle_dir, "output.json")

            if not os.path.exists(csv_path):
                print(f"[!] CSV input file not found: {csv_path}")
                return None,None

            # Step 1: Generate the SQL script
            queries = generate_sql.extract_db_queries(csv_path, unchecked_items)
            if not queries:
                print("[!] No queries extracted from CSV.")
                return None,None

            generate_sql.write_queries_to_file(queries, sql_output, unchecked_items)

            print(f"[+] SQL script generated at: {sql_output}")

            # Step 2: Choose execution method based on auditMethod
            audit_method = (scan_data.get("auditMethod") or "").strip().lower()
            print(audit_method)

            if audit_method == "remoteaccess":
                print("[*] Using remote access method.")
                generate_sql.execute_sql_script_remotely(sql_output, scan_data)

                return result_csv,json_output
            elif audit_method == "agent":
                print("[*] Using agent method.")
                script_path= download_script(sql_output)
                return script_path, json_output
            else:
                print(f"[-] Unsupported audit method: {audit_method}")
                return None,None

        except Exception as e:
            print(f"[!] Exception running Oracle audit: {e}")
            return None,None

    else:
        print(f"[-] Unsupported compliance type: {normalized_compliance}")
        return None,None


# startScan/utils.py



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
