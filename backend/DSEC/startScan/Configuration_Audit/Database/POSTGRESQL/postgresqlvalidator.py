import csv
import json
import re
import argparse

def parse_version(version_str):
    """Parses a version string like 'TLSv1.3' or '11' into a comparable format."""
    parts = re.findall(r'(\d+)', version_str)
    return [int(p) for p in parts]

def validate_results(results_json_path, rules_csv_path, output_csv_path):
    """
    Compares audit results from a JSON file against a set of rules from a CSV file
    and generates a final validation report.
    """
    try:
        with open(results_json_path, 'r') as f:
            results_data = json.load(f)
    except FileNotFoundError:
        print(f"Error: The results file was not found at '{results_json_path}'")
        return
    except json.JSONDecodeError:
        print(f"Error: Could not decode the JSON from '{results_json_path}'. Make sure it's a valid JSON file.")
        return

    try:
        with open(rules_csv_path, 'r', encoding='utf-8-sig',errors="replace") as f:
            rules = list(csv.DictReader(f))
    except FileNotFoundError:
        print(f"Error: The validation rules file was not found at '{rules_csv_path}'")
        return

    final_report = []
    # Define the headers for the final CSV report
    headers = ['CIS.NO', 'Subject', 'Description', 'Current Settings', 'Status', 'Remediation']

    # Process each rule from the validation CSV
    for rule in rules:
        audit_name = rule.get('name', '').strip()
        field_to_check = rule.get('field_to_check', '').strip()
        comparison_type = rule.get('comparison_type', '').strip()
        expected_value = rule.get('expected_value', '').strip()
        remediation = rule.get('remediation', '').strip()

        if not audit_name:
            continue

        # Extract CIS number and Subject from the audit name
        match = re.match(r'^([\d\.]+)\s+(.*)', audit_name)
        cis_no, subject = (match.groups() if match else ('N/A', audit_name))
        
        status = 'FAIL'  # Default to FAIL
        
        if audit_name not in results_data:
            current_setting_str = "Audit not performed"
        else:
            audit_result = results_data.get(audit_name)

            if audit_result is None:
                current_setting_str = "null"
            # Handle audits that returned an error during execution
            elif isinstance(audit_result, dict) and audit_result.get('status') == 'error':
                current_setting_str = f"Error: {audit_result.get('reason', 'Unknown error')}"
            
            # This handles both single-value results and list results
            elif isinstance(audit_result, (dict, list)):
                item_to_validate = audit_result
                if isinstance(audit_result, list):
                    item_to_validate = audit_result[0] if len(audit_result) > 0 else None

                value_to_check = item_to_validate
                # If field_to_check is specified and is not '-', get the nested value
                if field_to_check and field_to_check != '-' and isinstance(item_to_validate, dict):
                    value_to_check = item_to_validate.get(field_to_check)

                current_setting_str = json.dumps(value_to_check) if value_to_check is not None else "null"

                # --- Main Comparison Logic ---
                if value_to_check is not None:
                    try:
                        if comparison_type == 'equals':
                            if str(value_to_check) == expected_value:
                                status = 'PASS'
                        
                        elif comparison_type == 'not_equals':
                            if str(value_to_check) != expected_value:
                                status = 'PASS'
                        
                        elif comparison_type == 'in_list':
                            # Split by comma, then strip whitespace and any surrounding quotes from each item.
                            expected_list = [item.strip().strip('\'"') for item in expected_value.split(',')]
                            if str(value_to_check) in expected_list:
                                status = 'PASS'
                            elif isinstance(value_to_check, list) and any(item in expected_list for item in value_to_check):
                                status = 'PASS'
                        
                        elif comparison_type == 'not_in_list':
                            # New comparison type to check if a value is NOT in a given list.
                            disallowed_list = [item.strip().strip('\'"') for item in expected_value.split(',')]
                            if str(value_to_check) not in disallowed_list:
                                status = 'PASS'

                        elif comparison_type == 'atleast':
                            # New comparison type to check if the expected value is a substring of the actual value.
                            if expected_value in str(value_to_check):
                                status = 'PASS'

                        elif comparison_type == 'greater':
                            if 'TLS' in str(value_to_check).upper() and 'TLS' in expected_value.upper():
                                if parse_version(str(value_to_check)) >= parse_version(expected_value):
                                    status = 'PASS'
                            elif float(value_to_check) >= float(expected_value):
                                status = 'PASS'

                    except (ValueError, TypeError) as e:
                        current_setting_str += f" (Comparison Error: {e})"
        
        # Only include remediation text if the status is FAIL
        remediation_text = remediation if status == 'FAIL' else ''
        
        # Append the result row to our report
        final_report.append({
            'CIS.NO': cis_no,
            'Subject': subject,
            'Description': audit_name,
            'Current Settings': current_setting_str,
            'Status': status,
            'Remediation': remediation_text
        })

    # Write the final report to the output CSV file
    try:
        with open(output_csv_path, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=headers)
            writer.writeheader()
            writer.writerows(final_report)
        print(f"\nValidation complete! The final report has been saved to '{output_csv_path}'")
    except IOError as e:
        print(f"\nError writing to output file: {e}")

def main():
    """Main function to run the validator."""
    print("--- PostgreSQL Audit Validator ---")
    
    # Set up the argument parser to accept file paths from the command line
    parser = argparse.ArgumentParser(description="Validate PostgreSQL audit results against a rules file.")
    parser.add_argument("results_json", help="Path to the JSON file containing audit results.")
    parser.add_argument("rules_csv", help="Path to the CSV file containing validation rules.")
    parser.add_argument("-o", "--output", default="validation_results.csv", help="Path for the output CSV report (default: validation_results.csv).")
    
    args = parser.parse_args()
    
    # Call the validation function with the provided file paths
    validate_results(args.results_json, args.rules_csv, args.output)

if __name__ == '__main__':
    main()
