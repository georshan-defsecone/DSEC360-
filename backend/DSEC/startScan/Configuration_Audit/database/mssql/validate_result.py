import json
import csv
import re
import ast
import pandas as pd
from collections import defaultdict

# ──────────────────────────────
# Manual condition evaluator
# ──────────────────────────────
def check_manual_condition(setting_str, result_from_a):
    setting_str = setting_str.strip()

    if setting_str.lower() == "manual":
        return "Manual"

    if setting_str.lower().startswith("manual "):
        condition_expr = setting_str[7:].strip()

        if (condition_expr.startswith('"') and condition_expr.endswith('"')) or \
           (condition_expr.startswith("'") and condition_expr.endswith("'")):
            condition_expr = condition_expr[1:-1].strip()

        condition_expr = re.sub(r'["\']([a-zA-Z_][a-zA-Z0-9_]*)["\']', r'\1', condition_expr)
        condition_expr = re.sub(r'(?<![<>!=])=(?!=)', '==', condition_expr)

        python_keywords = {'and', 'or', 'not', 'in', 'is', 'True', 'False', 'None'}
        tokens = set(re.findall(r'\b[a-zA-Z_][a-zA-Z0-9_]*\b', condition_expr)) - python_keywords

        def safe_quote(val):
            if isinstance(val, str):
                return f"'{val.strip('\'\"')}'"
            return str(val)

        for token in tokens:
            val = None
            if isinstance(result_from_a, list) and len(result_from_a) == 1 and isinstance(result_from_a[0], dict):
                val = result_from_a[0].get(token)
            elif isinstance(result_from_a, dict):
                val = result_from_a.get(token)

            val_repr = safe_quote(token if val is None else val)
            condition_expr = re.sub(r'\b' + re.escape(token) + r'\b', val_repr, condition_expr)

        try:
            result = eval(condition_expr)
            return "Pass" if result else "Fail"
        except Exception as e:
            print(f"Manual condition evaluation error: {e}")
            return "Fail"

    return "Manual"

# ──────────────────────────────
# Utility functions
# ──────────────────────────────
def stringify(value):
    if isinstance(value, str):
        return value
    if value is None:
        return "null"
    return json.dumps(value, sort_keys=True)

def normalize(obj):
    if isinstance(obj, dict):
        return {k: normalize(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [normalize(i) for i in obj]
    elif isinstance(obj, str):
        return int(obj) if obj.isdigit() else obj.lower()
    return obj

def flatten_value(val):
    if isinstance(val, dict):
        return ", ".join(f"{k}:{flatten_value(v)}" for k, v in val.items())
    elif isinstance(val, list):
        return ", ".join(flatten_value(v) for v in val)
    elif val is None:
        return "null"
    return str(val)

# ──────────────────────────────
# Special audit rule
# ──────────────────────────────
def handle_backup_encryption(current_setting, remediation_in):
    data_str = current_setting.replace('\n', '').strip()
    pairs = [pair.strip() for pair in data_str.split(',') if pair.strip()]
    result = []

    for i in range(0, len(pairs), 3):
        group = pairs[i:i+3]
        record = {}
        for item in group:
            if ':' in item:
                key, val = item.split(':', 1)
                val = val.strip().lower()
                val = None if val == 'null' else val == 'true' if val == 'true' else val == 'false' if val == 'false' else val
                record[key.strip()] = val
        result.append(record)

    def group_backup_sets(data):
        grouped = defaultdict(list)
        for item in data:
            key = (item.get('server_name'), item.get('database_name'))
            grouped[key].append(item.get('backup_set_id'))
        return [{'server_name': k[0], 'database_name': k[1], 'backup_set_id': v} for k, v in grouped.items()]

    unencrypted = group_backup_sets(result)
    return ("PASS", "") if not unencrypted else ("FAIL", remediation_in), unencrypted

# ──────────────────────────────
# Core logic
# ──────────────────────────────
def validate_mssql(json_path, csv_path, output_path):
    try:
        with open(json_path, "r", encoding="utf-8") as f:
            json_data = json.load(f)
        for item in json_data:
            if item["Result"] is None:
                item["Result"] = "NULL"
    except Exception as e:
        print(f"❌ Error reading JSON: {e}")
        return

    try:
        with open(csv_path, newline='', encoding="utf-8") as f:
            reader = csv.DictReader(f)
            # Normalize field names
            reader.fieldnames = [field.strip().lstrip('\ufeff') for field in reader.fieldnames]
            csv_data = list(reader)
    except UnicodeDecodeError:
        with open(csv_path, newline='', encoding="cp1252") as f:
            reader = csv.DictReader(f)
            reader.fieldnames = [field.strip().lstrip('\ufeff') for field in reader.fieldnames]
            csv_data = list(reader)

    # Clean up column names (handle BOM and strip)

    a_lookup = {}
    for item in json_data:
        name = item.get("Name")
        a_lookup[name] = item.get("Result", "null")
    for k, v in a_lookup.items():
        if isinstance(v, str):
            a_lookup[k] = v.strip('\'"')

    final_result = []
    for item in csv_data:
        name = item.get("Name", "").strip()
        if not name:
            continue

        result_from_a = a_lookup.get(name, "null")
        settings_raw = item.get("Settings", "").strip()
        entry = item.copy()

        if settings_raw.lower().startswith("manual"):
            entry["Result"] = check_manual_condition(settings_raw, result_from_a).upper()
        else:
            try:
                if settings_raw.lower() in ["null", "\"null\"", ""]:
                    entry["Result"] = "PASS" if stringify(result_from_a) == "NULL" else "FAIL"
                else:
                    expected = ast.literal_eval("{" + settings_raw + "}")
                    actual = ast.literal_eval(result_from_a) if isinstance(result_from_a, str) else result_from_a
                    if isinstance(actual, list) and len(actual) == 1:
                        actual = actual[0]
                    entry["Result"] = "PASS" if normalize(actual) == normalize(expected) else "FAIL"
            except Exception:
                entry["Result"] = "FAIL"

        entry["CurrentSetting"] = flatten_value(result_from_a)
        entry["Remediation"] = item.get("Remediation", "") if entry["Result"] in ["FAIL", "MANUAL"] else ""

        if "value_configured" in entry["CurrentSetting"] or "value_in_use" in entry["CurrentSetting"]:
            entry["CurrentSetting"] = re.sub(r'\bname\s*:\s*[^,]+,?\s*', '', entry["CurrentSetting"]).strip(" ,")

        final_result.append(entry)

    df = pd.DataFrame(final_result)
    df["CIS.NO"] = df["Name"].apply(lambda x: re.match(r'^\d+(\.\d+)*', str(x)).group() if re.match(r'^\d+(\.\d+)*', str(x)) else "")
    df["Name"] = df["Name"].str.replace(r'^\d+(\.\d+)*\s*', '', regex=True)
    df["Name"] = df["Name"].str.replace(r'\s*\((Manual|Automated)\)\s*$', '', regex=True)

    # Special logic
    audit_name = "Ensure Database Backups are Encrypted"
    for idx, row in df[df["Name"].str.strip() == audit_name].iterrows():
        (result, remediation), setting = handle_backup_encryption(row["CurrentSetting"], row["Remediation"])
        df.at[idx, "Result"] = result
        df.at[idx, "CurrentSetting"] = setting
        df.at[idx, "Remediation"] = remediation

    df.rename(columns={"Name": "Subject","CurrentSetting":"Current Setting","Result":"Status"}, inplace=True)
    fieldnames = ["CIS.NO", "Subject", "Description", "Current Setting", "Status", "Remediation"]
    for field in fieldnames:
        if field not in df.columns:
            df[field] = None

    df = df[fieldnames]
    out_file = output_path.replace(".csv", "_final.csv")

    try:
        df.to_csv(out_file, index=False, encoding='utf-8')
        print(f"✅ CSV generated: {out_file}")
    except Exception as e:
        print(f"❌ Error writing CSV: {e}")
