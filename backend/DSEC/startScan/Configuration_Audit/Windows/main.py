import generate_PowerShell as generate_script
import validate as validate_compliance
from Windows_Remote_exec.wmi import run_remote_audit, cleanup_remote_files
import os


# Example CSV paths based on OS
csv_query_paths = {
    "win10": "Queries_Data/Microsoft_Windows_10_Stand-alone_v3.0.0.csv",
    "win11": "Queries_Data/Microsoft_Windows_11_Stand-alone_v3.0.0.csv"
}

validate_input_paths = {
    "win10": "Validate_Data/Microsoft_Windows_10_Stand-alone_v3.0.0_Validate.csv",
    "win11": "Validate_Data/Microsoft_Windows_11_Stand-alone_v3.0.0_Validate.csv"
}

# You can control OS type from user input or a config
selected_os = "win10" 

# Output JSON path mapping based on OS
output_json_paths = {
    "win10": {
        "remote": "C:\\Windows\\Temp\\Microsoft_Windows_10_Stand_output.json",
        "local": "Output/Microsoft_Windows_10_Stand_output.json"
    },
    "win11": {
        "remote": "C:\\Windows\\Temp\\Microsoft_Windows_11_Stand_output.json",
        "local": "Output/Microsoft_Windows_11_Stand_output.json"
    }
} 

# Pass the CSV path
csv_query_path = csv_query_paths[selected_os]

#local csv genrate path
generate_script_path = "Output/generate_script.ps1"

# remote script path
remote_script_path = "C:\\Windows\\Temp\\generate_script.ps1"

# This is the remote path
output_json_remote_path = output_json_paths[selected_os]["remote"]

# This is the local path where the file will be saved
output_json_local_path = output_json_paths[selected_os]["local"]

# Define excluded queries if any (can be an empty list for now)
excluded_queries = [
"1.1.1 (L1) Ensure 'Enforce password history' is set to '24 or more password(s)' (Automated)",
"1.1.2 (L1) Ensure 'Maximum password age' is set to '365 or fewer days, but not 0' (Automated)"
]

# Agent/Remote info (can be "Agent" or "remote")
audit_method = "remote"  # Example: can pass "remote" if needed

# 🔹 Generate PowerShell Script
generate_script.generate_script(csv_query_path, generate_script_path, output_json_remote_path, excluded_queries, audit_method)

if audit_method == "remote":
    # WMI Remote Execution
    username = "Welcome"
    password = "P@ssw0rd@123"
    target_ip = "10.90.121.24"

    local_script_path = generate_script_path
    local_output_path = output_json_local_path

    final_json_path = run_remote_audit(username, password, target_ip, local_script_path, local_output_path)
    print("[*] Remote audit completed.")
    
    # clean up paths
    secpol_file_path = "C:\\secpol.cfg" 
    cleanup_remote_files(username, password, target_ip, remote_script_path, output_json_remote_path, secpol_file_path)
    
    # validation steps
    validate_csv_path = validate_input_paths[selected_os]  # Get the correct validation CSV
    json_base_name = os.path.splitext(os.path.basename(final_json_path))[0]
    output_validation_csv_path = f"Output/{json_base_name}_validation_result.csv"  # Where the result will be saved
    # Run validation
    validate_compliance.validate_compliance(final_json_path, validate_csv_path, output_validation_csv_path)


else:
    print("[*] Local agent mode is not yet implemented.")
