import os
import json
import csv
import requests
import time

from datetime import datetime
from collections import Counter, defaultdict
# === Config ===
VT_API_KEY = "1dabfd5ff3f905101b1fe45a41c8a00a93185bedd696c03418dcefd8add2cd53" 
current_dir = os.getcwd()
JSON_FILE = os.path.join(current_dir, "IOCoutput.json")
CSV_FILE = os.path.join(current_dir, "validation_results.csv")
# Ensure the JSON file exists
if not os.path.exists(JSON_FILE):
    print(f"Error: JSON file '{JSON_FILE}' not found.")
    exit()


# === VirusTotal API check ===
def check_virustotal(hash_value):
    url = f"https://www.virustotal.com/api/v3/files/{hash_value}"
    headers = {"x-apikey": VT_API_KEY}
    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        data = response.json()
        malicious = data["data"]["attributes"]["last_analysis_stats"]["malicious"]

        # Extract vendor names that flagged as malicious
        analysis_results = data["data"]["attributes"]["last_analysis_results"]
        malicious_vendors = [vendor for vendor, result in analysis_results.items() if result["category"] == "malicious"]
        vendors_str = ", ".join(malicious_vendors) if malicious_vendors else "None"

        return "Pass" if malicious == 0 else "Fail", malicious, vendors_str

    elif response.status_code == 404:
        return "Hash Not Found", 0, "N/A"
    else:
        return f"API Error ({response.status_code})", 0, "N/A"


# === Validation Functions ===

def validate_generic(entries, key_name='Name', checked_hashes=None):
    if checked_hashes is None:
        checked_hashes = {}

    results = []
    for entry in entries:
        file_name = entry.get(key_name) or entry.get("FileName") or "Unknown File"
        file_hash = entry.get("Hash") or entry.get("SHA256Hash") or ""

        if not file_hash or file_hash in ["File Not Found", "N/A", "", "Hash Error"]:
            results.append([file_name, file_hash, "Missing or Invalid Hash", 0, ""])
            continue

        # Reuse result if hash already checked
        if file_hash in checked_hashes:
            print(f"Reusing result for: {file_name} → {file_hash}")
            status, malicious, vendors = checked_hashes[file_hash]
        else:
            print(f"Checking: {file_name} → {file_hash}")
            status, malicious, vendors = check_virustotal(file_hash)
            checked_hashes[file_hash] = (status, malicious, vendors)
            time.sleep(10)

        results.append([file_name, file_hash, status, malicious, vendors])

    return results

def validate_services(entries):
    return validate_generic(entries, key_name='DisplayName')

def validate_services_permissions(entries):
    results = []
    for entry in entries:
        file_name = entry.get("DisplayName") or entry.get("Name") or "Unknown Service"
        file_hash = entry.get("Hash") or entry.get("SHA256Hash") or ""
        everyone_write = entry.get("EveryoneWriteAccess", "Unknown")

        if everyone_write == "Yes":
            status = "Fail"
        elif everyone_write == "No":
            status = "Pass"
        else:
            status = "Unknown"

        if not file_hash or file_hash in ["File Not Found", "N/A", "", "Hash Error"]:
            results.append([file_name, file_hash, "Missing or Invalid Hash", 0, everyone_write])
            continue

        print(f"Checking: {file_name} → {file_hash}")
        vt_status, malicious, vendors = check_virustotal(file_hash)
        final_status = status if vt_status == "Pass" else "Fail"
        results.append([file_name, file_hash, final_status, malicious, vendors])
        time.sleep(10)
    return results

def validate_suspicious_directory(entries):
    results = []
    for entry in entries:
        file_name = entry.get("Name") or "Unknown File"
        file_hash = entry.get("Hash") or ""

        signature_status = entry.get("SignatureStatus")
        if signature_status == 1:
            signature_result = "Signed"
        else:
            signature_result = "Unsigned"

        if not file_hash or file_hash in ["File Not Found", "N/A", "", "Hash Error"]:
            results.append([file_name, file_hash, "Missing or Invalid Hash", 0, f"SignatureStatus: {signature_status}"])
            continue

        print(f"Checking: {file_name} → {file_hash}")
        vt_status, malicious, vendors = check_virustotal(file_hash)

        # Correct decision logic
        if vt_status == "Malicious":
            final_status = "Fail"
        elif vt_status == "Clean":
            final_status = "Pass"
        elif vt_status == "Hash Not Found":
            final_status = "Unknown (Hash Not Found)"
        else:
            final_status = f"({vt_status})"

        results.append([file_name, file_hash, final_status, malicious, vendors])
        time.sleep(10)
    return results

def validate_vba_settings(entries):
    results = []
    for entry in entries:
        app = entry.get("Application") or "Unknown App"
        office_version = entry.get("OfficeVersion") or "Unknown Version"
        setting_desc = entry.get("SettingDescription") or ""

        # JSON example shows empty dict for SettingDescription, need to handle this
        if isinstance(setting_desc, dict):
            desc_str = "Unknown Setting"
        else:
            desc_str = str(setting_desc)

        if "Enable all macros" in desc_str:
            status = "Fail"
        else:
            status = "Pass"

        results.append([f"{app} {office_version}", "", status, 0, desc_str])
    return results

def validate_startup_files(entries):
    return validate_generic(entries, key_name='EntryName')

def validate_lolbins(entries):
    results = []
    for entry in entries:
        file_name = entry.get("LOLBin") or "Unknown LOLBin"
        directories = entry.get("Directories") or "Not Found"
        status = entry.get("Status") or "No"

        if status == "Yes":
            validation_status = "Fail"
        else:
            validation_status = "Pass"

        results.append([file_name, "", validation_status, 0, directories])
    
    return results

def validate_config_files(entries):
    results = []
    checked_hashes = {}  # Avoid duplicate VT lookups

    for entry in entries:
        file_name = entry.get("FileName", "Unknown File")
        file_hash = entry.get("HashSHA256") or entry.get("Hash") or ""
        permissions = entry.get("Permissions", "")

        # Flag if 'Everyone' or BUILTIN\Users has write/modify/fullcontrol
        lowered = permissions.lower()
        if "everyone:" in lowered or ("builtin\\users" in lowered and any(p in lowered for p in ["write", "modify", "fullcontrol"])):
            final_status = "Fail"
            malicious = "N/A"
            notes = "Insecure Permissions (Everyone/Users Write)"
            results.append([file_name, file_hash, final_status, malicious, notes])
            continue

        # Check for missing/invalid hash
        if not file_hash or file_hash in ["File Not Found", "N/A", "", "Hash Error"]:
            results.append([file_name, file_hash, "Missing or Invalid Hash", 0, ""])
            continue

        # Reuse result if already checked
        if file_hash in checked_hashes:
            status, malicious, vendors = checked_hashes[file_hash]
            print(f"Reusing result for: {file_name} → {file_hash}")
        else:
            print(f"Checking Config File: {file_name} → {file_hash}")
            status, malicious, vendors = check_virustotal(file_hash)
            checked_hashes[file_hash] = (status, malicious, vendors)
            time.sleep(10)

        final_status = "Pass" if status == "Pass" else "Fail"
        results.append([file_name, file_hash, final_status, malicious, vendors])

    return results

def validate_user_accounts(entries):
    results = []
    privileged_levels = set()
    trusted_admins = set()

    # First pass: find baseline admin privilege(s)
    for entry in entries:
        username = entry.get("Username", "")
        description = entry.get("Description", "")
        privileges = entry.get("Privileges", "")

        if "administering" in description.lower():
            privileged_levels.add(privileges.strip().lower())
            trusted_admins.add(username.lower())

    # Second pass: validate all users
    for entry in entries:
        username = entry.get("Username", "")
        fullname = entry.get("FullName", "")
        privileges = entry.get("Privileges", "")
        privilege_clean = privileges.strip().lower()

        if username.lower() not in trusted_admins and privilege_clean in privileged_levels:
            status = "Fail"
            notes = "User has elevated privileges similar to admin"
        else:
            status = "Pass"
            notes = ""

        results.append([username, fullname, privileges, status, notes])

    return results

def validate_powershell_history(entries):
    results = []
    for entry in entries:
        username = entry.get("Username", "Unknown")
        command = entry.get("Command", "")
        keyword = entry.get("MatchedKeyword", "")
        line_number = entry.get("LineNumber", "N/A")

        # Consider all matches risky
        status = "Fail"
        notes = f"Line {line_number} matched dangerous keyword: {keyword}"

        results.append([username, command, status])
    return results


def validate_windows_events(entries):
    results = []
    if isinstance(entries, list):
        entries = entries[0]  # extract the dict from the list wrapper
    windows_events = entries.get("Windows Events", entries)

    timestamp_to_dt = lambda ts: datetime.fromtimestamp(int(ts.strip("/Date()")) / 1000)

    # 1. User_Account_Creations: flag if multiple accounts created in short time
    user_creations = windows_events.get("User_Account_Creations", [])
    if isinstance(user_creations, dict):
        user_creations = [user_creations]
    
    if len(user_creations) > 3:
        results.append(["User_Account_Creations", f"{len(user_creations)} accounts created", "Fail"])
    else:
        results.append(["User_Account_Creations", f"{len(user_creations)} accounts created", "Pass"])

    # 2. File_Creation_Deletion_Events: flag if same file path deleted/created many times
    file_events = windows_events.get("File_Creation_Deletion_Events", [])
    path_counter = Counter()

    for evt in file_events:
        path = evt.get("Object", "")
        path_counter[path] += 1

    flagged_paths = [p for p, count in path_counter.items() if count >= 3]
    if flagged_paths:
        results.append(["File_Creation_Deletion_Events", f"High activity in: {', '.join(flagged_paths)}", "Fail"])
    else:
        results.append(["File_Creation_Deletion_Events", "No suspicious activity", "Pass"])

    # 3. BAT_File_Creation: if any BAT file created, flag it
    bat_creation = windows_events.get("BAT_File_Creation", {})
    if isinstance(bat_creation, dict):
        bat_creation = [bat_creation]

    if bat_creation:
        results.append(["BAT_File_Creation", "BAT file detected", "Fail"])
    else:
        results.append(["BAT_File_Creation", "No BAT files", "Pass"])

    # 4. Failed_Logon_Attempts: repeated failed attempts from same account or IP
    failed_logons = windows_events.get("Failed_Logon_Attempts", [])
    if isinstance(failed_logons, dict):
        failed_logons = [failed_logons]

    acc_counter = Counter()
    ip_counter = Counter()
    for evt in failed_logons:
        acc = evt.get("Account", "")
        ip = evt.get("IPAddress", "")
        acc_counter[acc] += 1
        ip_counter[ip] += 1

    flagged_accounts = [a for a, c in acc_counter.items() if c >= 5]
    flagged_ips = [ip for ip, c in ip_counter.items() if c >= 5]

    if flagged_accounts or flagged_ips:
        note = f"Accounts: {flagged_accounts}, IPs: {flagged_ips}"
        results.append(["Failed_Logon_Attempts", f"Repeated failed attempts → {note}", "Fail"])
    else:
        results.append(["Failed_Logon_Attempts", "No repeated failures", "Pass"])

    # 5. After_Hours_Logons: any logon after hours (e.g., before 8 AM or after 6 PM)
    after_hours = windows_events.get("After_Hours_Logons", [])
    suspicious_logons = []
    for evt in after_hours:
        dt = timestamp_to_dt(evt.get("TimeCreated", "0"))
        if dt.hour < 8 or dt.hour > 18:
            suspicious_logons.append(evt.get("UserName", "Unknown"))

    if suspicious_logons:
        users = ", ".join(set(suspicious_logons))
        results.append(["After_Hours_Logons", f"After-hours logons detected: {users}", "Fail"])
    else:
        results.append(["After_Hours_Logons", "No after-hours logons", "Pass"])

    # 6. Suspicious_Open_Ports: if open ports found during after-hours logons
    open_ports = windows_events.get("Suspicious_Open_Ports", [])
    if open_ports and suspicious_logons:
        results.append(["Suspicious_Open_Ports", "Open ports during after-hours logon", "Fail"])
    else:
        results.append(["Suspicious_Open_Ports", "No suspicious ports or logons", "Pass"])

    return results


# === Mapping Check Names to Validation Functions ===
validation_map = {
    "Current Running Process Signed": validate_generic,
    "Current Running Service Signed": validate_services,
    "Check the service Everyone Permission": validate_services_permissions,
    "Suspicious Directory": validate_suspicious_directory,
    "Visual Basic for Applications": validate_vba_settings,
    "Startup files": validate_startup_files,
    "Living off the Land": validate_lolbins,
    "Configuration Files": validate_config_files,
    "List all user accounts": validate_user_accounts,
    "PowerShell History" : validate_powershell_history,
    "Windows Events" : validate_windows_events


}

# === Load JSON file ===
if not os.path.exists(JSON_FILE):
    print("Error: JSON file not found.")
    exit()

with open(JSON_FILE, "r", encoding="utf-8-sig") as f:
    try:
        data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")
        exit()

# === CSV Headers Mapping ===

csv_headers_map = {
    "Current Running Process Signed": ["IOC_Control", "Process Name", "Hash", "Status", "Malicious Count", "Vendors Name"],

    "Current Running Service Signed": ["IOC_Control", "Service Name", "Hash", "Status", "Malicious Count", "Vendors Name"],

    "Check the service Everyone Write Permission": ["IOC_Control", "Service Name", "Hash", "Status", "Malicious Count", "Everyone Access"],

    "Suspicious Directory": ["IOC_Control", "File Name", "Hash", "Status", "Malicious Count", "Signature Status"],

    "Visual Basic for Applications": ["IOC_Control", "File Name", "Status","Setting Description"],

    "Startup files": ["IOC_Control", "File Name", "Hash", "Status", "Malicious Count", "Vendors Name"],

    "Living off the Land": ["IOC_Control", "File Name", "Status"],

    "Configuration Files": ["IOC_Control", "File Name", "Hash", "Status", "Malicious Count", "Everyone Access/Vendor Info"],

    "List all user accounts": ["IOC_Control", "Username", "Full Name", "Privileges", "Status", "Notes"],

    "PowerShell History": ["IOC_Control", "Username", "Command", "Status"],

    "Windows Events": ["IOC_Control", "Event Summary", "Status"],


    "default": ["IOC_Control","Username" "File Name", "Hash", "Status", "Malicious Count", "Vendors Name"]

}


# === Save to CSV ===
with open(CSV_FILE, "w", newline="", encoding="utf-8") as csvfile:
    writer = csv.writer(csvfile)

    for check_name, entries in data.items():
        print(f"\nProcessing: {check_name}")

        if isinstance(entries, dict):
            entries = [entries]

        if not isinstance(entries, list):
            print(f"Skipping '{check_name}' as it is not a list or dict.")
            continue

        validate_function = validation_map.get(check_name)
        if not validate_function:
            print(f"No validation function defined for '{check_name}'. Skipping.")
            continue

        block_results = validate_function(entries)

        # Determine header based on control
        headers = csv_headers_map.get(check_name, csv_headers_map["default"])
        
        writer.writerow(headers)

        # Write results based on the control type
        for res in block_results:
            if check_name == "Living off the Land":
                # Only IOC, File Name, Status
                row = [check_name, res[0], res[2]]
            else:
                # Full row: IOC, File Name, Hash, Status, Malicious Count, Vendors Name
                row = [check_name] + res
            writer.writerow(row)

        writer.writerow([])  # Empty row as separator

print(f"\nValidation complete. Results saved to: {CSV_FILE}")
