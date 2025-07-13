import os
import json
import csv
import requests
import time

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

def validate_download_directory(entries):
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


# === Mapping Check Names to Validation Functions ===
validation_map = {
    "Current Running Process Signed": validate_generic,
    "Current Running Service Signed": validate_services,
    "Check the service Everyone Permission": validate_services_permissions,
    "Download Directory": validate_download_directory,
    "Visual Basic for Applications": validate_vba_settings,
    "Startup files": validate_startup_files,
    "Living off the Land": validate_lolbins,
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

# === Process each block ===
final_results = []

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
    for res in block_results:
        final_results.append([check_name] + res)

# === CSV Headers Mapping ===

csv_headers_map = {
    "Current Running Process Signed": ["IOC_Control", "Process Name", "Hash", "Status", "Malicious Count", "Vendors Name"],

    "Current Running Service Signed": ["IOC_Control", "Service Name", "Hash", "Status", "Malicious Count", "Vendors Name"],

    "Check the service Everyone Write Permission": ["IOC_Control", "Service Name", "Hash", "Status", "Malicious Count", "Everyone Access"],

    "Download Directory": ["IOC_Control", "File Name", "Hash", "Status", "Malicious Count", "Signature Status"],

    "Visual Basic for Applications": ["IOC_Control", "File Name", "Status","Setting Description"],

    "Startup files": ["IOC_Control", "File Name", "Hash", "Status", "Malicious Count", "Vendors Name"],

    "Living off the Land": ["IOC_Control", "File Name", "Status"],

    "default": ["IOC_Control", "File Name", "Hash", "Status", "Malicious Count", "Vendors Name"]

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
