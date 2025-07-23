import csv
import json
import ast

def load_json(path):
    with open(path, "r", encoding="utf-8-sig") as f:
        return json.load(f)

def load_csv(path):
    try:
        with open(path, "r", encoding="utf-8-sig") as f:
            reader = csv.DictReader(f)
            return list(reader)
    except UnicodeDecodeError:
        with open(path, "r", encoding="cp1252") as f:  # fallback to Windows encoding
            reader = csv.DictReader(f)
            return list(reader)


def extract_audit_id(name):
    if not name or not isinstance(name, str):
        return ""
    parts = name.strip().split()
    return parts[0] if parts else ""

def try_convert(value):
    try:
        return int(value)
    except ValueError:
        try:
            return float(value)
        except ValueError:
            return str(value).strip()

def normalize_value(val):
    if isinstance(val, list):
        return set(str(v).strip() for v in val if v)
    elif isinstance(val, str) and ',' in val:
        return set(part.strip() for part in val.split(',') if part)
    else:
        return str(val).strip()
    
def remove_null_chars(value):
    if isinstance(value, str):
        return value.replace('\x00', '')
    elif isinstance(value, dict):
        return {k: remove_null_chars(v) for k, v in value.items()}
    elif isinstance(value, list):
        return [remove_null_chars(v) for v in value]
    else:
        return value


def evaluate_custom_condition(condition, result_dict):
    comparisons = []
    clause_results = []
    or_clauses = [clause.strip() for clause in condition.split("||")]

    for or_clause in or_clauses:
        and_clauses = [c.strip() for c in or_clause.split("&&")]
        and_results = []

        for clause in and_clauses:
            operator = None
            for op in ["==", "!=", ">=", "<=", ">", "<"]:
                if op in clause:
                    operator = op
                    break

            if operator:
                key, expected_raw = [x.strip().strip('"') for x in clause.split(operator)]
                actual_raw = result_dict.get(str(key), "N/A")

                actual_norm = normalize_value(actual_raw)
                expected_norm = normalize_value(expected_raw)

                if isinstance(actual_norm, set) and isinstance(expected_norm, set):
                    if operator == "==":
                        result = actual_norm == expected_norm
                    elif operator == "!=":
                        result = actual_norm != expected_norm
                    else:
                        result = False
                else:
                    try:
                        result = eval(f"try_convert(actual_norm) {operator} try_convert(expected_norm)")
                    except Exception:
                        result = False

                comparisons.append((key, actual_norm, operator, expected_norm, result))
                and_results.append(result)
            else:
                and_results.append(False)

        clause_results.append(all(and_results))

    return any(clause_results), comparisons

def stringify_current_settings(result_dict, map_str=None):
    if not map_str:
        return ", ".join(f"{k}: {v}" for k, v in result_dict.items())

    try:
        map_dict = ast.literal_eval(map_str)
        if not isinstance(map_dict, dict):
            raise ValueError("Parsed value is not a dictionary.")
    except Exception as e:
        print(f"âš ï¸  Failed to parse map string:\n{map_str}\nReason: {e}")
        return ", ".join(f"{k}: {v}" for k, v in result_dict.items())

    for label, condition_expr in map_dict.items():
        if isinstance(condition_expr, str) and any(op in condition_expr for op in ["==", "!=", ">", "<", "&&", "||"]):
            is_match, _ = evaluate_custom_condition(condition_expr, result_dict)
            if is_match:
                return label

    display_items = []
    for k, v in result_dict.items():
        v_str = str(v).strip()
        mapped_value = map_dict.get(v_str, v_str)
        display_items.append(f"{k}: {mapped_value}")
    return ", ".join(display_items)

def evaluate_compliance(json_data, csv_rules):
    results = []

    for rule in csv_rules:
        audit_name = rule["audit_name"]
        condition = rule["condition"]
        remediation = rule.get("remediation", "")
        map_str = rule.get("map", "")
        description = rule.get("description", "")
        cis_no = rule.get("CISNo", "")
        csv_audit_id = extract_audit_id(audit_name)

        csv_audit_id = rule.get("CISNo", "").strip()
        matched_entry = next(
            (entry for entry in json_data if entry.get("audit_name", "").startswith(csv_audit_id)),
            None
        )


        if not matched_entry:
            results.append( [cis_no,"Not Found", description, remediation, "Fail", audit_name])
            continue

        if ':' in condition:
            all_passed = True
            settings_details = []

            path_conditions = [c.strip() for c in condition.split(",") if c.strip()]
            cond_dict = {}
            for pc in path_conditions:
                if ':' in pc:
                    path, cond = pc.split(":", 1)
                    cond_dict[path.strip()] = cond.strip()

            result_data = matched_entry.get("result", {})

            if isinstance(result_data, dict):
                # Result is a dictionary, process directly
                for path, value in result_data.items():
                    settings = {}
                    try:
                        value_str = str(value)
                        for part in value_str.split(","):
                            if '=' in part:
                                k, v = part.split("=", 1)
                                settings[k.strip()] = v.strip()
                            else:
                                settings[path.strip()] = value_str.strip()
                    except Exception as e:
                        settings_details.append(f"{path}: Unreadable - {e}")
                        all_passed = False
                        continue

                    path_condition = cond_dict.get(path.strip())
                    if path_condition:
                        passed, _ = evaluate_custom_condition(path_condition, settings)
                    else:
                        passed = False

                    label = stringify_current_settings(settings, map_str)
                    settings_details.append(f"{path}: {label}")
                    if not passed:
                        all_passed = False

                status = "Pass" if all_passed else "Fail"
                current_settings = " | ".join(settings_details)
                results.append([cis_no, current_settings, description, remediation, status, audit_name])

            else:
                results.append([cis_no, "Unreadable result format", description, remediation, "Fail", audit_name])


        else:
            # Single condition processing
            result_data = matched_entry.get("result", {})
            if isinstance(result_data, dict):
                merged_result = result_data
            elif isinstance(result_data, list):
                merged_result = {}
                for item in result_data:
                    merged_result.update(item)
            else:
                merged_result = {}

            is_pass, _ = evaluate_custom_condition(condition, merged_result)
            status = "Pass" if is_pass else "Fail"
            current_settings = stringify_current_settings(merged_result, map_str)
            results.append([cis_no, current_settings, description, remediation, status, audit_name])

    return results


def write_csv(path, rows):
    with open(path, "w", newline='', encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["CIS.NO", "Current Settings","Description","Remediation","Status","Subject"])
        writer.writerows(rows)

# 🔁 MAIN FUNCTION (can be called from main.py)
def validate_compliance(json_path, input_csv_path, output_csv_path):
    json_data = load_json(json_path)
    csv_rules = load_csv(input_csv_path)
    json_data = remove_null_chars(json_data)
    output = evaluate_compliance(json_data, csv_rules)
    write_csv(output_csv_path, output)
    print(f"Compliance evaluation written to: {output_csv_path}")
