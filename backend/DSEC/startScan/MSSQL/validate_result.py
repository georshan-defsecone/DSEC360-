import json
import csv
import ast
import argparse
import sys
import re


def check_manual_condition(setting_str, result_from_a):
    setting_str = setting_str.strip()

    if setting_str.lower() == "manual":
        return "Manual"

    if setting_str.lower().startswith("manual "):
        condition_expr = setting_str[7:].strip()

        # Strip quotes if any
        if (condition_expr.startswith('"') and condition_expr.endswith('"')) or \
           (condition_expr.startswith("'") and condition_expr.endswith("'")):
            condition_expr = condition_expr[1:-1].strip()

        # Strip quotes around variable names like "AuditLevel"
        condition_expr = re.sub(r'["\']([a-zA-Z_][a-zA-Z0-9_]*)["\']', r'\1', condition_expr)

        # Replace single '=' with '==', but skip '!=', '<=', '>='
        condition_expr = re.sub(r'(?<![<>!=])=(?!=)', '==', condition_expr)


        # Find all variable tokens: words that are not Python keywords like 'or', 'and', etc.
        python_keywords = {'and', 'or', 'not', 'in', 'is', 'True', 'False', 'None'}
        tokens = set(re.findall(r'\b[a-zA-Z_][a-zA-Z0-9_]*\b', condition_expr))
        tokens = tokens - python_keywords

        # Replace tokens with their actual values from result_from_a
        def safe_quote(val):
            if isinstance(val, str):
                # Strip any existing quotes to avoid double quoting
                val_stripped = val.strip('\'"')
                return f"'{val_stripped}'"
            else:
                return str(val)

        for token in tokens:
            val = None
            if isinstance(result_from_a, list) and len(result_from_a) == 1 and isinstance(result_from_a[0], dict):
                val = result_from_a[0].get(token)
            elif isinstance(result_from_a, dict):
                val = result_from_a.get(token)

            if val is None:
                # Unknown token treated as string literal with quotes
                val_repr = safe_quote(token)
            else:
                val_repr = safe_quote(val)

            pattern = r'\b' + re.escape(token) + r'\b'
            condition_expr = re.sub(pattern, val_repr, condition_expr)



        # Now condition_expr should be a valid Python expression, evaluate it safely
        try:
            print(f"[DEBUG] Final expression to evaluate: {condition_expr}")
            result = eval(condition_expr)
            return "Pass" if result else "Fail"
        except Exception as e:
            print(f"Manual condition evaluation error: {e}")
            return "Fail"

    return "Manual"

# ─────────────────────────────────────────────
# Argument Parser Setup
# ─────────────────────────────────────────────
parser = argparse.ArgumentParser(description="Validate JSON results against CSV definitions.")
parser.add_argument("json_file", help="Path to the result JSON file.")
parser.add_argument("csv_file", help="Path to the validation CSV file.")
parser.add_argument("output_file", nargs="?", default="final_result.csv", help="Path to the output CSV file (default: final_result.csv).")

args = parser.parse_args()

# ─────────────────────────────────────────────
# Read the JSON file
# ─────────────────────────────────────────────
try:
    with open(args.json_file, "r", encoding="utf-8") as file:
        json_data = json.load(file)
except Exception as e:
    print(f"Error reading JSON file: {e}")
    sys.exit(1)

# Convert None values to string "null"
for item in json_data:
    if item["Result"] is None:
        item["Result"] = "null"

# ─────────────────────────────────────────────
# Load the CSV validation data
# ─────────────────────────────────────────────
csv_data = []
try:
    with open(args.csv_file, newline='', encoding="utf-8") as csvfile:
        reader = csv.DictReader(csvfile)
        reader.fieldnames = [name.lstrip('\ufeff') for name in reader.fieldnames]
        csv_data = [row for row in reader]
except UnicodeDecodeError:
    with open(args.csv_file, newline='', encoding="cp1252") as csvfile:
        reader = csv.DictReader(csvfile)
        reader.fieldnames = [name.lstrip('\ufeff') for name in reader.fieldnames]
        csv_data = [row for row in reader]

# ─────────────────────────────────────────────
# Create a lookup from name to result
# ─────────────────────────────────────────────
a_lookup = {}
for item in json_data:
    name = item.get("Name")
    if name in a_lookup:
        print(f"Warning: Duplicate entry found for Name: {name}")
    a_lookup[name] = item.get("Result", "null")

# Normalize a_lookup values by stripping quotes if string
for k, v in a_lookup.items():
    if isinstance(v, str):
        a_lookup[k] = v.strip('\'"')

# ─────────────────────────────────────────────
# Utility Functions
# ─────────────────────────────────────────────
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
        try:
            if obj.isdigit():
                return int(obj)
            return obj.lower()
        except:
            return obj
    return obj

# ─────────────────────────────────────────────
# Prepare final result
# ─────────────────────────────────────────────
final_result = []

for item in csv_data:
    if "Name" not in item or not item["Name"].strip():
        print("Skipping row without valid 'Name':", item)
        continue

    name = item["Name"]
    new_entry = item.copy()
    result_from_a = a_lookup.get(name, "null")
    settings_raw = item.get("Settings", "").strip()

    if settings_raw.lower().startswith("manual"):
        status = check_manual_condition(settings_raw, result_from_a)
        new_entry["Status"] = status
        new_entry["CurrentSetting"] = None if status == "Pass" else result_from_a
    else:
        try:
            if settings_raw.lower() in ["null", "\"null\"", ""]:
                if stringify(result_from_a) == "null":
                    new_entry["Status"] = "Pass"
                    new_entry["CurrentSetting"] = None
                else:
                    new_entry["Status"] = "Fail"
                    new_entry["CurrentSetting"] = result_from_a
            else:
                settings_dict = ast.literal_eval("{" + settings_raw + "}")
                try:
                    parsed_result = ast.literal_eval(result_from_a)
                except Exception:
                    parsed_result = result_from_a

                if isinstance(parsed_result, list) and len(parsed_result) == 1:
                    parsed_result = parsed_result[0]

                parsed_result = normalize(parsed_result)
                settings_dict = normalize(settings_dict)

                if parsed_result == settings_dict:
                    new_entry["Status"] = "Pass"
                    new_entry["CurrentSetting"] = None
                else:
                    new_entry["Status"] = "Fail"
                    new_entry["CurrentSetting"] = result_from_a
        except Exception as e:
            print(f"Error parsing settings for {name}: {e}")
            new_entry["Status"] = "Fail"
            new_entry["CurrentSetting"] = result_from_a

    if new_entry["Status"] in ["Fail", "Manual"]:
        new_entry["Remediation"] = item.get("Remediation", "")
    else:
        new_entry["Remediation"] = ""

    final_result.append(new_entry)

# ─────────────────────────────────────────────
# Write to output CSV
# ─────────────────────────────────────────────
fieldnames = ["Name", "Description", "Settings", "Status", "CurrentSetting", "Remediation"]

for entry in final_result:
    for key in fieldnames:
        if key not in entry:
            entry[key] = None

try:
    with open(args.output_file, "w", newline='', encoding="utf-8") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(final_result)
    print(f"✔️ Final result written to '{args.output_file}'")
except Exception as e:
    print(f"Error writing output CSV: {e}")
    sys.exit(1)
