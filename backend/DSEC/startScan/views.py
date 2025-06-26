import os
import subprocess
import re
import shutil
from .Configuration_Audit.database.oracle import generate_sql
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.http import JsonResponse, Http404
import json
from .Configuration_Audit.Windows.generate_PowerShell import generate_script
from .Configuration_Audit.Windows.validate import validate_compliance
from .Configuration_Audit.Windows.Windows_Remote_exec.wmi import run_remote_audit, cleanup_remote_files

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
            oracle_dir = os.path.join(base_dir,"Configuration_Audit","database","oracle")
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


def windows_config_audit(scan_data):
    print("[*] Entered windows_config_audit()")
    base_dir = os.path.dirname(os.path.abspath(__file__))
    windows_dir = os.path.join(base_dir,"Configuration_Audit","Windows")
    
    # Get OS selection from scan_data 
    selected_os = (scan_data.get("complianceCategory"))
    audit_method = (scan_data.get("auditMethod")).strip().lower()

    try:
        # Dynamically find the query CSV
        queries_dir = os.path.join(base_dir,windows_dir, "Queries_Data")
        csv_name = (scan_data.get("complianceCategory") or "").strip() + ".csv"
        print(f"[DEBUG] Looking for CSV: {csv_name}")
        csv_path = os.path.join(queries_dir, csv_name)
        # Check if file exists
        if not os.path.exists(csv_path):
            print(f"[!] CSV file not found: {csv_path}")
            return None, None

        validate_dir = os.path.join(base_dir,windows_dir, "Validate_Data")
        validate_csv_name = (scan_data.get("complianceCategory") or "").strip() + "_Validate.csv"
        print(f"[DEBUG] Looking for validation CSV: {validate_csv_name}")
        if not validate_csv_name:
            print("[!] Validation CSV name is empty.")
            return None, None
        validate_csv_path = os.path.join(validate_dir, validate_csv_name)
        


        output_json_remote_path = f"C:\\Windows\\Temp\\{os.path.basename(csv_path).replace('.csv', '_output.json')}"
        output_json_local_path = os.path.join(base_dir,windows_dir, "Output", os.path.basename(csv_path).replace('.csv', '_output.json'))

        script_file_name = f"Generate_Script_{selected_os}.ps1"
        generate_script_path = os.path.join(base_dir, windows_dir, "Output", script_file_name)

        remote_script_path = "C:\\Windows\\Temp\\generate_script.ps1"

        excluded_queries = scan_data.get("uncheckedComplianceItems", [])


        if audit_method == "remoteaccess":
            username = scan_data.get("username")
            password = scan_data.get("password")
            target_ip = scan_data.get("target")
            
            # Generate PowerShell Script
            generate_script(csv_path, generate_script_path, output_json_remote_path, excluded_queries)
            print(f"[+] PowerShell script generated at: {generate_script_path}")
            
            final_json_path = run_remote_audit(username, password, target_ip, generate_script_path, output_json_local_path)
            print("[*] Remote audit completed.")

            secpol_file_path = "C:\\secpol.cfg"
            cleanup_remote_files(username, password, target_ip, remote_script_path, output_json_remote_path, secpol_file_path)

            json_base_name = os.path.splitext(os.path.basename(final_json_path))[0]
            output_validation_csv_path = os.path.join(base_dir,windows_dir, f"Output/{json_base_name}_validation_result.csv")

            validate_compliance(final_json_path, validate_csv_path, output_validation_csv_path)
            print("[*] Validation completed successfully.")

            return final_json_path, output_validation_csv_path
        
        elif audit_method == "agent":
            # Generate PowerShell Script for agent method
            generate_script(csv_path, generate_script_path, output_json_local_path, excluded_queries)
            print(f"[+] PowerShell script generated at: {generate_script_path}")
            print("[*] Using agent method.")
            script_path = download_script(generate_script_path)
            if not script_path:
                print("[-] Failed to download script for agent method.")
                return None, None
            
            # Return the script path and the expected output JSON path
            return script_path, output_json_local_path 
        
        else:
            print("[*] Local agent mode is not yet implemented.")
            return None, None
        
         
        
    except Exception as e:
            print(f"[!] Exception during Windows audit: {e}")
            return None, None



def download_script(script_path):
    print("[*] Entered download_script()")

    if not script_path or not os.path.isfile(script_path):
        print(f"[-] Script file not found: {script_path}")
        return None

    # Use the folder where the script is located
    script_dir = os.path.dirname(script_path)
    # Create 'downloads' folder in the same location
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
