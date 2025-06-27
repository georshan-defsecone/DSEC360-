import os
import subprocess
import re
import shutil
from .database.oracle import generate_sql
from .database.Maria import  connection_maria
from .database.MSSQL import remote
import zipfile
from .Configuration_Audit.database.oracle import generate_sql
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.http import JsonResponse, Http404
import json
import pandas as pd
import os
from openpyxl.styles import Font, PatternFill,Alignment
from openpyxl.utils import get_column_letter


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
                convert_csv_to_excel(result_csv)

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



def download_script(script_path, second_file_path=None):
    print("[*] Entered download_script()")

    # Check if the primary script exists
    if not script_path or not os.path.isfile(script_path):
        print(f"[-] Script file not found: {script_path}")
        return None

    # Get the directory of the script and prepare download directory
    script_dir = os.path.dirname(script_path)
    download_dir = os.path.join(script_dir, "downloads")
    os.makedirs(download_dir, exist_ok=True)

    # Case 1: Only one file to download (no compression)
    if second_file_path is None:
        dest_path = os.path.join(download_dir, os.path.basename(script_path))
        try:
            shutil.copy(script_path, dest_path)
            print(f"[+] Script copied to download location: {dest_path}")
            return dest_path
        except Exception as e:
            print(f"[!] Failed to copy script for download: {e}")
            return None

    # Case 2: Second file provided, compress both into a ZIP
    else:
        # Validate the second file
        if not os.path.isfile(second_file_path):
            print(f"[-] Second file not found: {second_file_path}")
            return None

        zip_filename = os.path.join(download_dir, "scripts_bundle.zip")
        try:
            with zipfile.ZipFile(zip_filename, 'w') as zipf:
                zipf.write(script_path, arcname=os.path.basename(script_path))
                zipf.write(second_file_path, arcname=os.path.basename(second_file_path))
            print(f"[+] Both files compressed into: {zip_filename}")
            return zip_filename
        except Exception as e:
            print(f"[!] Failed to create ZIP file: {e}")
            return None
    




def convert_csv_to_excel(csv_file_path, excel_file_path=None):
    """
    Converts a CSV file to an Excel (.xlsx) file with:
    - Dark blue header row
    - Green background for 'pass' in Status column
    - Red background for 'fail' in Status column
    - Centered alignment for all cells with wrapped text
    - Auto-sized columns and row heights to show full content

    Args:
        csv_file_path (str): Path to the input CSV file.
        excel_file_path (str, optional): Path to save the output Excel file.

    Returns:
        str: Path to the created Excel file.
    """
    import os
    import pandas as pd
    from openpyxl import load_workbook
    from openpyxl.styles import PatternFill, Font, Alignment
    from openpyxl.utils import get_column_letter

    if not os.path.exists(csv_file_path):
        raise FileNotFoundError(f"CSV file not found: {csv_file_path}")

    # Load CSV into a DataFrame
    df = pd.read_csv(csv_file_path)

    # Determine output file path
    if not excel_file_path:
        excel_file_path = os.path.splitext(csv_file_path)[0] + ".xlsx"

    # Write DataFrame to Excel (no formatting yet)
    df.to_excel(excel_file_path, index=False, engine='openpyxl')

    # Open the workbook and worksheet for formatting
    wb = load_workbook(excel_file_path)
    ws = wb.active

    # Define styles
    header_fill = PatternFill(start_color="FF0921D6", end_color="FF0921D6", fill_type="solid")
    header_font = Font(color="FFFFFF", bold=True)
    center_alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

    pass_fill = PatternFill(start_color="FF0DD609", end_color="FF0DD609", fill_type="solid")
    fail_fill = PatternFill(start_color="FFD60909", end_color="FFD60909", fill_type="solid")

    status_col_index = None

    # Format header row
    for col_num, cell in enumerate(ws[1], 1):
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = center_alignment

        if cell.value and str(cell.value).strip().lower() == "status":
            status_col_index = col_num

    # Format all data cells (centered alignment and wrap text)
    for row in ws.iter_rows(min_row=2):
        max_lines = 1
        for cell in row:
            cell.alignment = center_alignment
            if isinstance(cell.value, str):
                lines = cell.value.count('\n') + 1
                max_lines = max(max_lines, lines)
        ws.row_dimensions[row[0].row].height = max(15, 13.5 * max_lines)

    # Apply coloring to Status column values
    if status_col_index:
        for row in ws.iter_rows(min_row=2, min_col=status_col_index, max_col=status_col_index):
            for cell in row:
                value = str(cell.value).strip().lower()
                if value == "pass":
                    cell.fill = pass_fill
                elif value == "fail":
                    cell.fill = fail_fill

    # Auto-adjust column widths based on longest line in content
    col_widths = {}
    for row in ws.iter_rows():
        for cell in row:
            if cell.value:
                col_letter = get_column_letter(cell.column)
                value = str(cell.value)
                estimated_width = max(len(line) for line in value.split('\n'))
                col_widths[col_letter] = max(col_widths.get(col_letter, 0), estimated_width)

    for col_letter, width in col_widths.items():
        ws.column_dimensions[col_letter].width = min(width * 1.2, 100)  # scale width, cap at 100

    # Save the styled Excel file
    wb.save(excel_file_path)

    return excel_file_path




    

@api_view(['GET'])
@permission_classes([AllowAny])
def get_json_file(request, folder_path, filename):
    """
    Returns the content of a JSON file located in a dynamic folder structure.
    """
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Sanitize folder path to prevent directory traversal
    safe_folder_path = os.path.normpath(folder_path).replace('..', '')
    
    json_dir = os.path.join(base_dir, safe_folder_path)
    json_path = os.path.join(json_dir, f'{filename}.json')

    if not os.path.exists(json_path):
        return Response({'error': 'File not found'}, status=404)

    try:
        with open(json_path, 'r') as f:
            data = json.load(f)
        return Response(data)
    except json.JSONDecodeError:
        return Response({'error': 'Invalid JSON file'}, status=400)