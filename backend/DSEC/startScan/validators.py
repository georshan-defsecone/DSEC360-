
def validate(json_file, expected_dict, output_path):
    with open(json_file) as f:
        try:
            json_objects = json.load(f)
        except json.JSONDecodeError as e:
            print(f"❌ Failed to parse JSON file: {e}")
            traceback.print_exc()
            return

    results_csv = []
    seen_audit_ids = set()

    for data in json_objects:
        json_name = data.get('name', '').strip()
        audit_id = extract_audit_id_from_json_name(json_name)

        if not audit_id:
            results_csv.append({
                'CIS.NO': '',
                'Subject': json_name,
                'Status': 'FAIL',
                'Current Settings': 'Could not extract audit ID',
                'Description': '',
                'Remediation': ''
            })
            continue

        seen_audit_ids.add(audit_id)
        expected_info = expected_dict.get(audit_id)
        remediation = expected_info.get('remediation', '') if expected_info else ''
        if not expected_info:
            results_csv.append({
                'CIS.NO': audit_id,
                'Subject': strip_audit_number(json_name),
                'Status': 'FAIL',
                'Current Settings': f"No expected value found for audit ID: {audit_id}",
                'Description': '',
                'Remediation': remediation
            })
            continue

        expected_value = expected_info['expected_value']
        comparison_type = expected_info['comparison_type']
        field_to_check = expected_info['field_to_check']
        audit_name = expected_info['audit_name']
        audit_clean = strip_audit_number(audit_name)
        description = expected_info.get('description', '')
        results = data.get('results', None)

        if comparison_type == 'some_result':
            status = 'PASS' if results and isinstance(results, list) and len(results) > 0 else 'FAIL'
            msg = 'Results found' if status == 'PASS' else 'No results found'
            results_csv.append({
                'CIS.NO': audit_id,
                'Subject': audit_clean,
                'Status': status,
                'Current Settings': msg,
                'Description': description,
                'Remediation': '' if status == 'PASS' else remediation
            })
            continue

        if field_to_check.lower() == 'null':
            expected_is_null = expected_value.strip().lower() == 'null'
            status, msg = '', ''
            if expected_is_null:
                if results is None or (isinstance(results, list) and len(results) == 0):
                    status, msg = 'PASS', 'Results are null or empty'
                else:
                    status, msg = 'FAIL', f"{results}"
            else:
                if results is None or (isinstance(results, list) and len(results) == 0):
                    status, msg = 'FAIL', 'Expected value present but got null'
                else:
                    status, msg = 'PASS', 'Results present as expected'

            results_csv.append({
                'CIS.NO': audit_id,
                'Subject': audit_clean,
                'Status': status,
                'Current Settings': msg,
                'Description': description,
                'Remediation': '' if status == 'PASS' else remediation
            })
            continue

        if not isinstance(results, list):
            msg = "'results' is null" if results is None else str(results)
            results_csv.append({
                'CIS.NO': audit_id,
                'Subject': audit_clean,
                'Status': 'FAIL',
                'Current Settings': msg,
                'Description': description,
                'Remediation': remediation
            })
            continue

        all_passed = True
        fail_reasons = []

        for result in results:
            actual_value = result.get(field_to_check)
            if actual_value is None and expected_value.strip().lower() != 'null':
                fail_reasons.append(f"Missing '{field_to_check}'")
                all_passed = False
                continue

            if not compare_values(actual_value, expected_value, comparison_type):
                fail_reasons.append(f"{field_to_check} = {actual_value}")
                all_passed = False

        results_csv.append({
            'CIS.NO': audit_id,
            'Subject': audit_clean,
            'Status': 'PASS' if all_passed else 'FAIL',
            'Current Settings': 'All checks passed' if all_passed else '; '.join(fail_reasons),
            'Description': description,
            'Remediation': '' if all_passed else remediation
        })

    for audit_id, info in expected_dict.items():
        if audit_id not in seen_audit_ids:
            results_csv.append({
                'CIS.NO': audit_id,
                'Subject': strip_audit_number(info['audit_name']),
                'Status': 'FAIL',
                'Current Settings': 'Audit ID not found in JSON',
                'Description': info.get('description', ''),
                'Remediation': info.get('remediation', '')
            })

    # Save CSV
    write_csv(results_csv, output_path)

    # Save Excel with same base name
    excel_path = os.path.splitext(output_path)[0] + '.xlsx'
    write_excel(results_csv, excel_path)

    print(f"\n✅ Validation reports saved:\n- CSV: {output_path}\n- Excel: {excel_path}")