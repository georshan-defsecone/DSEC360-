import json
import csv
import os

def validateResult(json_path, csv_path, output_csv_path):
    # Load JSON results
    with open(json_path, "r", encoding="utf-8") as jf:
        json_data = json.load(jf)

    # Load metadata from the original CSV
    csv_data = {}
    with open(csv_path, "r", encoding="utf-8") as cf:
        reader = csv.DictReader(cf)
        for row in reader:
            audit_id = row["audit_id"].strip()
            csv_data[audit_id] = {
                "description": row["audit_description"].strip(),
                "remediation": row["audit_remediation"].strip()
            }

    # Enrich JSON with metadata
    for audit in json_data:
        audit_id = audit.get("audit_id")
        if audit_id in csv_data:
            audit["description"] = csv_data[audit_id]["description"]
            audit["remediation"] = csv_data[audit_id]["remediation"]
        else:
            audit["description"] = ""
            audit["remediation"] = ""

    # Prepare rows for CSV
    csv_rows = []
    for audit in json_data:
        status = audit.get("status", "").strip().upper()
        output = audit.get("output", "").strip()

        # Extract current settings based on ** PASS ** or ** FAIL **
        if "** FAIL **" in output:
            current_settings = output.split("** FAIL **", 1)[1].strip()
        elif "** PASS **" in output:
            current_settings = output.split("** PASS **", 1)[1].strip()
        else:
            current_settings = output  # fallback

        remediation = audit.get("remediation", "") if status == "FAIL" else ""

        csv_rows.append({
            "CIS.NO": audit.get("audit_id", ""),
            "Subject": audit.get("audit_name", ""),
            "Description": audit.get("description", ""),
            "Current Settings": current_settings,
            "Status": status,
            "Remediation": remediation
        })

    # Write to output CSV
    fieldnames = ["CIS.NO", "Subject", "Description", "Current Settings", "Status", "Remediation"]
    with open(output_csv_path, "w", encoding="utf-8", newline="") as out_csv:
        writer = csv.DictWriter(out_csv, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(csv_rows)

    print(f"✅ CSV with enriched audit results saved as: {output_csv_path}")