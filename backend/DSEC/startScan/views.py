import os
import subprocess
import re
import shutil

def get_config_script(compliance_name, standard):
    # Normalize inputs
    normalized_compliance = re.sub(r'[\W_]+', '', compliance_name or "").lower()
    normalized_standard = re.sub(r'[\W_]+', '', standard or "").lower()

    if normalized_compliance == "mssql2019":
        # Paths
        base_dir = os.path.dirname(os.path.abspath(__file__))
        queries_dir = os.path.join(base_dir, "MSSQL", "Queries")
        original_csv = os.path.join(queries_dir, "query_2019.csv")
        renamed_csv = os.path.join(queries_dir, f"{normalized_compliance}_{normalized_standard}.csv")
        script_path = os.path.join(base_dir, "MSSQL", "generate_sql.py")

        # Use existing renamed file, or rename original if needed
        if os.path.exists(renamed_csv):
            print(f"[+] Found existing CSV: {renamed_csv}")
        elif os.path.exists(original_csv):
            os.rename(original_csv, renamed_csv)
            print(f"[+] Renamed {original_csv} to {renamed_csv}")
        else:
            print(f"[!] Neither original nor renamed CSV exists.")
            return None

        # Execute SQL generation script
        try:
            result = subprocess.run(
                ["python", script_path, renamed_csv],
                check=True,
                capture_output=True,
                text=True,
                cwd=os.path.dirname(script_path)
            )
            print(result.stdout)
        except subprocess.CalledProcessError as e:
            print(f"[!] Error executing generate_sql.py: {e.stderr}")
            return None

        # Return .sql output path
        sql_output_path = os.path.splitext(renamed_csv)[0] + ".sql"
        return sql_output_path

    return None


# startScan/utils.py



def download_script(script_path):
    print("[*] Entered download_script()")

    if not script_path or not os.path.isfile(script_path):
        print(f"[-] SQL script file not found: {script_path}")
        return None

    download_dir = os.path.join(os.path.dirname(script_path), "downloads")
    os.makedirs(download_dir, exist_ok=True)

    dest_path = os.path.join(download_dir, os.path.basename(script_path))

    try:
        shutil.copy(script_path, dest_path)
        print(f"[+] Script copied to download location: {dest_path}")
        return dest_path
    except Exception as e:
        print(f"[!] Failed to copy script for download: {e}")
        return None
