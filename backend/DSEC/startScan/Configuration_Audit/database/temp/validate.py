import sys
import json
import csv
import os
import chardet
import re

# Detect file encoding
def detect_encoding(file_path):
    with open(file_path, 'rb') as f:
        rawdata = f.read(4096)
    result = chardet.detect(rawdata)
    return result['encoding'] or 'utf-8'

# Load JSON file with UTF-8 and fallback to UTF-8 with BOM
def load_json(json_path):
    if os.path.getsize(json_path) == 0:
        raise ValueError("JSON file is empty.")

    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (UnicodeDecodeError, json.JSONDecodeError):
        with open(json_path, 'r', encoding='utf-8-sig') as f:
            return json.load(f)

# Load CSV file
def load_csv(csv_path):
    encoding = detect_encoding(csv_path)
    with open(csv_path, 'r', encoding=encoding) as f:
        reader = csv.DictReader(f)
        return list(reader)

# Normalize CSV Name to match JSON format
def normalize_name(name):
    name = re.sub(r'[^A-Za-z0-9]', '_', name)   # Replace non-alphanum with _
    name = re.sub(r'_+', '_', name)             # Collapse multiple underscores
    return name.strip('_') + '_'                # Strip trailing _ and add one

# Build lookup: JSON Name -> result
def build_result_lookup(json_data):
    lookup = {}
    for item in json_data:
        name = item.get('Name')
        result = item.get('Result') or item.get('result')
        if name and result is not None:
            normalized = normalize_name(name)
            lookup[normalized] = result
    #print(lookup)  #This create an dict with the normalized names as keys and the results as values
    return lookup

# Match CSV row to JSON result and compare settings
def get_setting_value(row, result_lookup):
    csv_name = row.get('Name', '').strip()
    normalized_name = normalize_name(csv_name)
    csv_setting = row.get('Settings', '').strip()
    json_result_raw = result_lookup.get(normalized_name, '')

    # Handle AND (&&)
    if '&&' in csv_setting:
        conditions = [cond.strip() for cond in csv_setting.split('&&')]
        for cond in conditions:
            if not check_condition(cond, json_result_raw, csv_name):
                return 'FAIL'
        return 'PASS'
    # Handle OR (||)
    elif '||' in csv_setting:
        conditions = [cond.strip() for cond in csv_setting.split('||')]
        for cond in conditions:
            if check_condition(cond, json_result_raw, csv_name):
                return 'PASS'
        return 'FAIL'
    # Single condition
    else:
        return 'PASS' if check_condition(csv_setting, json_result_raw, csv_name) else 'FAIL'

def check_condition(csv_setting, json_setting, csv_name):
    result = None

    if csv_setting.startswith('equals:'):
        expected = csv_setting[len('equals:'):].strip()
        if json_setting is None or str(json_setting).strip() == '':
            result = json_setting is None or str(json_setting).strip() == '' == expected
        else:
            if isinstance(json_setting, list) and json_setting and isinstance(json_setting[0], dict):
                json_setting = json_setting[0]
                if ':' in expected:
                    key, val = expected.split(':', 1)
                    json_key_value = json_setting.get(key.strip())
                    result = str(json_key_value) == val.strip()
                else:
                    # No key specified, compare all values in the dict
                    result = any(str(v) == expected for v in json_setting.values())
            else:
                if ':' in expected:
                    key, val = expected.split(':', 1)
                    if isinstance(json_setting, dict):
                        json_key_value = json_setting.get(key.strip())
                        result = str(json_key_value) == val.strip()
                    else:
                        result = str(json_setting) == val.strip()
                else:
                    result = str(json_setting) == expected

    elif csv_setting.startswith('endswith:'):
        expected = csv_setting[len('endswith:'):].strip()
        if json_setting is None or str(json_setting).strip() == '':
            result = False
        else:
            if isinstance(json_setting, list) and json_setting and isinstance(json_setting[0], dict):
                json_setting = json_setting[0]
                # You can specify the key to check, e.g., endswith:VARIABLE_VALUE:.log
                if ':' in expected:
                    key, suffix = expected.split(':', 1)
                    value = json_setting.get(key.strip(), '')
                    result = str(value).endswith(suffix.strip())
                else:
                    # If no key specified, check all values in the dict
                    result = any(str(v).endswith(expected) for v in json_setting.values())
            else:
                result = str(json_setting).endswith(expected)

    elif csv_setting.startswith('startswith:'):
        expected = csv_setting[len('startswith:'):].strip()
        if json_setting is None or str(json_setting).strip() == '':
            result = False
        else:
            if isinstance(json_setting, list) and json_setting and isinstance(json_setting[0], dict):
                json_setting = json_setting[0]
                # You can specify the key to check, e.g., startswith:VARIABLE_VALUE:log
                if ':' in expected:
                    key, prefix = expected.split(':', 1)
                    value = json_setting.get(key.strip(), '')
                    result = str(value).startswith(prefix.strip())
                else:
                    # If no key specified, check all values in the dict
                    result = any(str(v).startswith(expected) for v in json_setting.values())
            else:
                result = str(json_setting).startswith(expected)

    elif csv_setting.startswith('notequals:'):
        expected = csv_setting[len('notequals:'):].strip()
        if json_setting is None or str(json_setting).strip() == '':
            result = expected != ''
        else:
            if isinstance(json_setting, list) and json_setting and isinstance(json_setting[0], dict):
                json_setting = json_setting[0]
                key, sep, val = expected.partition(':')
                if sep:  # If ':' found
                    json_key_value = json_setting.get(key.strip())
                    result = str(json_key_value) != val.strip()
                else:
                    result = str(json_setting) != expected
            else:
                result = str(json_setting) != expected

    elif csv_setting.startswith('greaterthan:'):
        expected = csv_setting[len('greaterthan:'):].strip()
        try:
            if isinstance(json_setting, list) and json_setting and isinstance(json_setting[0], dict):
                json_setting = json_setting[0]
                # You can specify the key to check, e.g., greaterthan:VARIABLE_VALUE:100
                if ':' in expected:
                    key, threshold = expected.split(':', 1)
                    value = json_setting.get(key.strip(), '')
                    result = float(value) > float(threshold.strip())
                else:
                    # If no key specified, check all numeric values in the dict
                    result = any(float(v) > float(expected) for v in json_setting.values() if str(v).replace('.', '', 1).isdigit())
            else:
                result = float(json_setting) > float(expected)
        except Exception:
            result = False

    elif csv_setting.startswith('notcontains:'):
        expected = csv_setting[len('notcontains:'):].strip()
        if json_setting is None or str(json_setting).strip() == '':
            result = True
        else:
            if isinstance(json_setting, list) and json_setting and isinstance(json_setting[0], dict):
                json_setting = json_setting[0]
                if ':' in expected:
                    key, substring = expected.split(':', 1)
                    value = json_setting.get(key.strip(), '')
                    # Split by comma and strip spaces for exact protocol match
                    protocols = [v.strip() for v in str(value).split(',')]
                    result = substring.strip() not in protocols
                else:
                    result = all(expected not in str(v) for v in json_setting.values())
            else:
                # Split by comma for exact protocol match
                protocols = [v.strip() for v in str(json_setting).split(',')]
                result = expected not in protocols
    
    elif csv_setting.startswith('check_all'):
        excepted = csv_setting[len('check_all:'):].strip()
        if ':' in excepted:
            key, threshold = excepted.split(':', 1)
        all_values = [item.get(key) for item in json_setting]
        result = all(val == threshold for val in all_values)

    elif csv_setting.startswith('third:'):
        expected = csv_setting[len('third:'):].strip()
        if json_setting is None or str(json_setting).strip() == '':
            result = False
        else:
            # If it's a dict, try to get the value field, else use the string directly
            if isinstance(json_setting, list) and json_setting and isinstance(json_setting[0], dict):
                json_setting = json_setting[0]
                # You can specify the key to check, e.g., third:value:mysql
                if ':' in expected:
                    key, val = expected.split(':', 1)
                    value = json_setting.get(key.strip(), '')
                else:
                    # Default to 'value' key if not specified
                    value = json_setting.get('value', '')
                    val = expected
            elif isinstance(json_setting, dict):
                value = json_setting.get('value', '')
                val = expected
            else:
                value = str(json_setting)
                val = expected

            parts = str(value).split()
            # Check if there are at least 3 fields
            if len(parts) >= 3:
                result = parts[2] == val.strip()
            else:
                result = False

    elif csv_setting.startswith('fourth:'):
        expected = csv_setting[len('fourth:'):].strip()
        if json_setting is None or str(json_setting).strip() == '':
            result = False
        else:
            # If it's a dict, try to get the value field, else use the string directly
            if isinstance(json_setting, list) and json_setting and isinstance(json_setting[0], dict):
                json_setting = json_setting[0]
                # You can specify the key to check, e.g., fourth:value:mysql
                if ':' in expected:
                    key, val = expected.split(':', 1)
                    value = json_setting.get(key.strip(), '')
                else:
                    # Default to 'value' key if not specified
                    value = json_setting.get('value', '')
                    val = expected
            elif isinstance(json_setting, dict):
                value = json_setting.get('value', '')
                val = expected
            else:
                value = str(json_setting)
                val = expected

            parts = str(value).split()
            # Check if there are at least 4 fields
            if len(parts) >= 4:
                result = parts[3] == val.strip()
            else:
                result = False
    elif csv_setting.startswith('contains:'):
        expected = csv_setting[len('contains:'):].strip()
        if json_setting is None or str(json_setting).strip() == '':
            result = False
        else:
            if isinstance(json_setting, list) and json_setting and isinstance(json_setting[0], dict):
                json_setting = json_setting[0]
                # You can specify the key to check, e.g., contains:VARIABLE_VALUE:mysql
                if ':' in expected:
                    key, substring = expected.split(':', 1)
                    value = json_setting.get(key.strip(), '')
                    result = substring.strip() in str(value)
                else:
                    # If no key specified, check all values in the dict
                    result = any(expected in str(v) for v in json_setting.values())
            else:
                result = expected in str(json_setting)

    elif csv_setting.startswith('notstartswith:'):
        expected = csv_setting[len('notstartswith:'):].strip()
        if json_setting is None or str(json_setting).strip() == '':
            result = True
        else:
            if isinstance(json_setting, list) and json_setting and isinstance(json_setting[0], dict):
                json_setting = json_setting[0]
                # You can specify the key to check, e.g., notstartswith:VARIABLE_VALUE:foo
                if ':' in expected:
                    key, prefix = expected.split(':', 1)
                    value = json_setting.get(key.strip(), '')
                    result = not str(value).startswith(prefix.strip())
                else:
                    # If no key specified, check all values in the dict
                    result = all(not str(v).startswith(expected) for v in json_setting.values())
            else:
                result = not str(json_setting).startswith(expected)
    elif csv_setting.startswith('randomcheck'):
        expected = csv_setting[len('randomcheck:'):].strip()
        result = True
        if json_setting is None or str(json_setting).strip() == '':
            result = False
        else:
            if isinstance(json_setting, list) and json_setting and isinstance(json_setting[0], dict):
                if ':' in expected:
                    key_str, prefix_str = expected.split(':', 1)
                    key_list = [k.strip() for k in key_str.split(',')]
                    prefix_list = [p.strip() for p in prefix_str.split(',')]
                    for name, exp_val in zip(key_list, prefix_list):
                        actual = next((item.get('VARIABLE_VALUE') for item in json_setting if item.get('VARIABLE_NAME') == name), None)
                        if actual != exp_val:
                            print(f"Mismatch for {name}: expected {exp_val}, got {actual}")
                            result = False
                            break
            else:
                result = False
    elif csv_setting.startswith('LOCAL_INFILE'):
        # Extract version and local_infile value
        db_version_str = next((item['VARIABLE_VALUE'] for item in json_setting if item['VARIABLE_NAME'] == 'VERSION'), None)
        local_infile = next((item['VARIABLE_VALUE'] for item in json_setting if item['VARIABLE_NAME'] == 'LOCAL_INFILE'), None)

        # Clean and split version
        version_part = db_version_str.split('-')[0]  # e.g., '10.6.22'
        major, minor, patch = map(int, version_part.split('.'))

        # Compare with 10.2.0 manually
        is_new_version = (major > 10) or (major == 10 and minor > 2) or (major == 10 and minor == 2 and patch >= 0)

        # Audit logic
        if is_new_version:
            result=True
        else:
            if local_infile.upper() in ['OFF', '0']:
                result=True
            else:
                result=False
            
    elif csv_setting.startswith('ENCRYPTION'):
        
        # Separate the variable entries and the keyword dictionary
        *variables, keyword_dict = json_setting

        # Condition 1: All VARIABLE_VALUEs must be 'ON' or '1'
        all_values_valid = all(
            v.get('VARIABLE_VALUE', '').strip().upper() in ['ON', '1']
            for v in variables
        )

        # Condition 2: Each keyword must appear somewhere in any VARIABLE_NAME or VARIABLE_VALUE
        def keyword_found(keyword):
            keyword_upper = keyword.upper()
            return any(
                keyword_upper in v.get('VARIABLE_NAME', '').upper() or
                keyword_upper in v.get('VARIABLE_VALUE', '').upper()
                for v in variables
            )

        all_keywords_present = all(keyword_found(k) for k in keyword_dict)

        # Final result
        result = all_values_valid and all_keywords_present

            # Iterate over all items in the Result list
    elif csv_setting.startswith('PASSWORD'):

        # Convert to dict
        plugin_status = {item['PLUGIN_NAME']: item['PLUGIN_STATUS'] for item in json_setting}

        # 1. Check strict_password_validation = ON
        strict_ok = plugin_status.get('STRICT_PASSWORD_VALIDATION', '').strip().upper() == 'ON'

        # 2. Check simple_password_check_minimal_length ≥ 14
        try:
            min_len_val = int(plugin_status.get('SIMPLE_PASSWORD_CHECK_MINIMAL_LENGTH', '0'))
            min_len_ok = min_len_val >= 14
        except ValueError:
            min_len_ok = False

        # 3. Check cracklib_password_check_dictionary is valid path
        dict_path = plugin_status.get('CRACKLIB_PASSWORD_CHECK_DICTIONARY', '')
        dict_ok = os.path.isfile(dict_path)

        # Final result
        result = strict_ok and min_len_ok and dict_ok
        # This would come from MariaDB SHOW VARIABLES, mocked here:
        
    #print(f"Checking '{csv_name}': '{json_setting}' {csv_setting} => {result}")
    return result

import csv
import re

def format_key(name):
    # Convert name to match result_lookup key format
    return re.sub(r'\W+', '_', name).strip('_')

def write_filtered_csv(rows, output_path, result_lookup, included_names):
    fieldnames = ['CIS.NO', 'Subject', 'Description', 'Current Setting', 'Status', 'Remediation']

    with open(output_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()

        for row in rows:
            original_name = row.get('Name', '').strip()
            normalized_name = normalize_name(original_name)

            if normalized_name not in included_names:
                continue

            # Extract CIS number (e.g., 2.1.5)
            cis_match = re.match(r'^(\d+(?:\.\d+)+)', original_name)
            cis_no = cis_match.group(1) if cis_match else ''

            # Clean name
            name_without_cis = re.sub(r'^(\d+(?:\.\d+)+)\s*', '', original_name)
            name_cleaned = re.sub(r'\s*\(.*?\)', '', name_without_cis).strip()

            # Format key to match result_lookup
            for i in result_lookup.keys():
                if normalized_name == i:
                    current_setting = result_lookup[i]
                    break

            # Get current setting and result (same value)

            result = get_setting_value(row, result_lookup)

            # Remediation only if original result was "fail"
            remediation = row.get('Remediation', '') if result.strip().lower() == 'fail' else ''

            writer.writerow({
                'CIS.NO': cis_no,
                'Subject': name_cleaned,
                'Description': row.get('Description', ''),
                'Current Setting': current_setting,
                'Status': result,
                'Remediation': remediation
            })

def get_included_names(json_data):
    """
    Extracts the 'Name' field from each item in the JSON data.
    Returns a list of normalized names.
    """
    names = []
    for item in json_data:
        name = item.get('Name')
        if name:
            normalized_name = normalize_name(name)
            names.append(normalized_name)
    return names



def validate_maria_db(result_json,validate_csv,report_csv):

    json_file = result_json
    csv_file = validate_csv
    output_csv = report_csv

    try:
        json_data = load_json(json_file)
    except Exception as e:
        print(f"Error loading JSON: {e}")
        sys.exit(1)

    try:
        csv_data = load_csv(csv_file)
        getting_names=get_included_names(json_data)
        result_lookup = build_result_lookup(json_data)
        write_filtered_csv(csv_data, output_csv, result_lookup,getting_names)
    except Exception as e:
        print(f"Error processing CSV: {e}")
        sys.exit(1)



# Main function
def main():
    if len(sys.argv) != 4:
        print("Usage: python validate.py <file.json> <file.csv> <output.csv>")
        sys.exit(1)

    json_file = sys.argv[1]
    csv_file = sys.argv[2]
    output_csv = sys.argv[3]

    try:
        json_data = load_json(json_file)
    except Exception as e:
        print(f"Error loading JSON: {e}")
        sys.exit(1)

    try:
        csv_data = load_csv(csv_file)
        getting_names=get_included_names(json_data)
        result_lookup = build_result_lookup(json_data)
        write_filtered_csv(csv_data, output_csv, result_lookup,getting_names)
    except Exception as e:
        print(f"Error processing CSV: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
