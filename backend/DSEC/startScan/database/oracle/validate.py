import csv
import json
import sys
import re

def extract_audit_id_from_json_name(json_name):
    parts = json_name.strip('_').split('_')
    id_parts = []
    for part in parts:
        if part.isdigit():
            id_parts.append(part)
        else:
            break
    return '.'.join(id_parts) if len(id_parts) >= 2 else None

def extract_audit_id_from_csv_name(audit_name):
    match = re.match(r'^(\d+(?:\.\d+)+)', audit_name.strip())
    return match.group(1) if match else None

def load_csv(csv_file):
    expected_dict = {}
    with open(csv_file, newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            full_name = row['name'].strip()
            audit_id = extract_audit_id_from_csv_name(full_name)
            if not audit_id:
                continue
            expected_dict[audit_id] = {
                'audit_name': full_name,
                'expected_value': row['expected_value'].strip(),
                'comparison_type': row['comparison_type'].strip(),
                'field_to_check': row['field_to_check'].strip(),
                'description': row.get('description', '').strip()
            }
    return expected_dict

def validate(json_file, expected_dict, output_csv):
    with open(json_file) as f:
        try:
            json_objects = json.load(f)
        except json.JSONDecodeError:
            print("Failed to parse JSON file.")
            return

    results_csv = []
    seen_audit_ids = set()

    for data in json_objects:
        json_name = data.get('name', '').strip()
        audit_id = extract_audit_id_from_json_name(json_name)

        if not audit_id:
            msg = 'Could not extract audit ID'
            results_csv.append({
                'audit_name': json_name,
                'status': 'FAIL',
                'current_settings': msg,
                'description': ''
            })
            print(f"[FAIL] {json_name}: {msg}")
            continue

        seen_audit_ids.add(audit_id)
        expected_info = expected_dict.get(audit_id)
        if not expected_info:
            msg = f"No expected value found for audit ID: {audit_id}"
            results_csv.append({
                'audit_name': json_name,
                'status': 'FAIL',
                'current_settings': msg,
                'description': ''
            })
            print(f"[FAIL] {json_name}: {msg}")
            continue

        expected_value = expected_info['expected_value']
        comparison_type = expected_info['comparison_type']
        field_to_check = expected_info['field_to_check']
        audit_name = expected_info['audit_name']
        description = expected_info.get('description', '')

        results = data.get('results', None)

        if comparison_type == 'some_result':
            if results and isinstance(results, list) and len(results) > 0:
                msg = 'Results found (some_result case)'
                results_csv.append({
                    'audit_name': audit_name,
                    'status': 'PASS',
                    'current_settings': msg,
                    'description': description
                })
                print(f"[PASS] {audit_name}: {msg}")
            else:
                msg = 'No results found (some_result case)'
                results_csv.append({
                    'audit_name': audit_name,
                    'status': 'FAIL',
                    'current_settings': msg,
                    'description': description
                })
                print(f"[FAIL] {audit_name}: {msg}")
            continue

        if field_to_check.lower() == 'null':
            expected_is_null = expected_value.strip().lower() == 'null'
            if expected_is_null:
                if results is None or (isinstance(results, list) and len(results) == 0):
                    msg = 'Results are null or empty'
                    results_csv.append({'audit_name': audit_name, 'status': 'PASS', 'current_settings': msg, 'description': description})
                    print(f"[PASS] {audit_name}: {msg}")
                else:
                    msg = f"Expected null but got {results}"
                    results_csv.append({'audit_name': audit_name, 'status': 'FAIL', 'current_settings': msg, 'description': description})
                    print(f"[FAIL] {audit_name}: {msg}")
            else:
                if results is None or (isinstance(results, list) and len(results) == 0):
                    msg = "Expected value present but got null"
                    results_csv.append({'audit_name': audit_name, 'status': 'FAIL', 'current_settings': msg, 'description': description})
                    print(f"[FAIL] {audit_name}: {msg}")
                else:
                    msg = "Results present as expected"
                    results_csv.append({'audit_name': audit_name, 'status': 'PASS', 'current_settings': msg, 'description': description})
                    print(f"[PASS] {audit_name}: {msg}")
            continue

        if results is None:
            msg = "'results' is null"
            results_csv.append({'audit_name': audit_name, 'status': 'FAIL', 'current_settings': msg, 'description': description})
            print(f"[FAIL] {audit_name}: {msg}")
            continue
        if isinstance(results, str):
            results_csv.append({'audit_name': audit_name, 'status': 'FAIL', 'current_settings': results, 'description': description})
            print(f"[FAIL] {audit_name}: {results}")
            continue
        if not isinstance(results, list):
            msg = "Invalid type for 'results'"
            results_csv.append({'audit_name': audit_name, 'status': 'FAIL', 'current_settings': msg, 'description': description})
            print(f"[FAIL] {audit_name}: {msg}")
            continue

        all_passed = True
        fail_reasons = []

        for i, result in enumerate(results, 1):
            # 🔽 Case-insensitive field lookup
            actual_value = None
            for key, value in result.items():
                if key.lower() == field_to_check.lower():
                    actual_value = value
                    break

            if actual_value is None and expected_value.strip().lower() != 'null':
                fail_reasons.append(f"Row {i}: Missing field '{field_to_check}'")
                all_passed = False
                continue

            passed = compare_values(actual_value, expected_value, comparison_type)
            if not passed:
                fail_reasons.append(f"Row {i}: {field_to_check} = {actual_value} (Expected: {comparison_type} {expected_value})")
                all_passed = False

        if all_passed:
            msg = 'All checks passed'
            results_csv.append({'audit_name': audit_name, 'status': 'PASS', 'current_settings': msg, 'description': description})
            print(f"[PASS] {audit_name}: {msg}")
        else:
            msg = '; '.join(fail_reasons)
            results_csv.append({'audit_name': audit_name, 'status': 'FAIL', 'current_settings': msg, 'description': description})
            print(f"[FAIL] {audit_name}: {msg}")

    for audit_id, info in expected_dict.items():
        if audit_id not in seen_audit_ids:
            results_csv.append({
                'audit_name': info['audit_name'],
                'status': 'FAIL',
                'current_settings': 'Audit ID not found in JSON',
                'description': info.get('description', '')
            })
            print(f"[MISSING] {info['audit_name']}: Not found in JSON")

    with open(output_csv, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['audit_name', 'status', 'current_settings', 'description'])
        writer.writeheader()
        for row in results_csv:
            writer.writerow(row)

    print(f"\n✅ Validation report written to {output_csv}")

def compare_values(actual, expected, comp_type):
    try:
        expected_is_null = expected.strip().lower() == 'null'
        actual_is_null = actual is None

        if comp_type == 'equals':
            if expected_is_null:
                return actual_is_null
            return str(actual) == expected

        elif comp_type == 'in_list':
            if expected_is_null:
                return actual_is_null
            return str(actual) in [val.strip() for val in expected.split(',')]

        elif comp_type == 'max_value':
            if actual_is_null or expected_is_null:
                return False
            return float(actual) <= float(expected)

        elif comp_type == 'min_value':
            if actual_is_null or expected_is_null:
                return False
            return float(actual) >= float(expected)

        elif comp_type == 'contains':
            if expected_is_null or actual_is_null:
                return False
            return expected in str(actual)

        else:
            return False
    except Exception:
        return False

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python validate.py <check.csv> <out.json> <result.csv>")
        sys.exit(1)

    csv_path = sys.argv[1]
    json_path = sys.argv[2]
    result_csv = sys.argv[3]

    expected_rules = load_csv(csv_path)
    validate(json_path, expected_rules, result_csv)
