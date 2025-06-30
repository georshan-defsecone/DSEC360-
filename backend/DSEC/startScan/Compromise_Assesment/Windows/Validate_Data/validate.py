
import os
import json
import csv
import requests
import time

# === Config ===
VT_API_KEY = "34185e2c9a97b391eadd42496e85f6222da0feed13c46a814699fa66bd3a8da0"
JSON_FILE = r"C:\Users\welcome\results_20250625-143704.json"
CSV_FILE = r"C:\Users\welcome\validation_results.csv"

# === VirusTotal API check ===
def check_virustotal(hash_value):
    url = f"https://www.virustotal.com/api/v3/files/{hash_value}"
    headers = {"x-apikey": VT_API_KEY}
    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        data = response.json()
        malicious = data["data"]["attributes"]["last_analysis_stats"]["malicious"]
        return "Pass" if malicious == 0 else "Fail"
    elif response.status_code == 404:
        return "Hash Not Found"
    else:
        return f"API Error ({response.status_code})"

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

# === Validate structure ===
if "Suspicious_Downloads" not in data:
    print("Error: 'Suspicious_Downloads' key not found in JSON.")
    exit()

# === Process each file entry ===
results = []

for entry in data["Suspicious_Downloads"]:
    file_name = entry.get("FileName", "")
    file_hash = entry.get("SHA256Hash", "")

    if not file_hash:
        results.append([file_name, "", "Missing Hash"])
        continue

    print(f"Checking: {file_name} → {file_hash}")
    status = check_virustotal(file_hash)
    results.append([file_name, file_hash, status])

    time.sleep(16)  # Throttle for free VT API (4 req/min)

# === Save to CSV ===
with open(CSV_FILE, "w", newline="", encoding="utf-8") as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(["FileName", "SHA256Hash", "Status"])
    writer.writerows(results)

print(f"\nValidation complete. Results saved to: {CSV_FILE}")