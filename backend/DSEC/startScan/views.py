import os
import subprocess
import re
import shutil
from .database.oracle import generate_sql

def database_config_audit(scan_data):
    print("[*] Entered database_config_audit()")

    # Normalize compliance and standard names
    compliance_name = (scan_data.get("complianceCategory") or "").strip().lower()
    standard = (scan_data.get("complianceSecurityStandard") or "").strip().lower()

    normalized_compliance = re.sub(r'[\W_]+', '', compliance_name)
    normalized_standard = re.sub(r'[\W_]+', '', standard)
    print(f"[DEBUG] normalized_compliance: {normalized_compliance}")

    if normalized_compliance == "oracledatabase12cbenchmarkv300":
        try:
            base_dir = os.path.dirname(os.path.abspath(__file__))
            oracle_dir = os.path.join(base_dir,"database","oracle")
            csv_name = "data.csv"
            csv_path = os.path.join(oracle_dir, csv_name)
            sql_output = os.path.join(oracle_dir, "output.sql")

            if not os.path.exists(csv_path):
                print(f"[!] CSV input file not found: {csv_path}")
                return None

            # Step 1: Generate the SQL script
            queries = generate_sql.extract_db_queries(csv_path)
            if not queries:
                print("[!] No queries extracted from CSV.")
                return None

            generate_sql.write_queries_to_file(queries, sql_output)
            print(f"[+] SQL script generated at: {sql_output}")

            # Step 2: Choose execution method based on auditMethod
            audit_method = (scan_data.get("auditMethod") or "").strip().lower()
            print(audit_method)

            if audit_method == "remoteaccess":
                print("[*] Using remote access method.")
                generate_sql.execute_sql_script_remotely(sql_output, scan_data)
                return sql_output
            elif audit_method == "agent":
                print("[*] Using agent method.")
                return download_script(sql_output)
            else:
                print(f"[-] Unsupported audit method: {audit_method}")
                return None

        except Exception as e:
            print(f"[!] Exception running Oracle audit: {e}")
            return None

    else:
        print(f"[-] Unsupported compliance type: {normalized_compliance}")
        return None


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
