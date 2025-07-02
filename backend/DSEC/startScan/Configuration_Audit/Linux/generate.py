import os
import re
import yaml
import sys

def extract_script_blocks(audit_file):
    with open(audit_file, 'r') as f:
        content = f.read()

    audit_id = re.search(r'audit_id:\s*"(.*?)"', content)
    audit_id = audit_id.group(1).strip() if audit_id else os.path.splitext(os.path.basename(audit_file))[0]

    audit_name = re.search(r'audit_name:\s*"(.*?)"', content)
    audit_name = audit_name.group(1).strip() if audit_name else audit_id

    script = re.search(r'audit_script:\s*"""(.*?)"""', content, re.DOTALL)
    script = script.group(1).strip() if script else None

    depended = re.search(r'depended_audits:\s*"(.*?)"', content)
    depended = [x.strip() for x in depended.group(1).split(',')] if depended else []

    condition_match = re.search(r'condition:\n(.*)', content, re.DOTALL)
    condition = None
    if condition_match:
        try:
            condition = yaml.safe_load("condition:\n" + condition_match.group(1))
            condition = condition['condition']
        except Exception as e:
            print(f"Error parsing condition in {audit_file}: {e}")

    return audit_id, audit_name, script, depended, condition

def audit_id_to_func_name(audit_id):
    pattern = r'\W|^(?=\d)'
    return "a_" + re.sub(pattern, '_', audit_id)

def strip_outer_braces(script):
    lines = script.strip().splitlines()
    if lines and lines[0].strip() == '{' and lines[-1].strip() == '}':
        return '\n'.join(lines[1:-1]).strip()
    return script.strip()

def ubuntu(standard, version, exclude_audits=None, method="agent", ssh_info=None):
    VALID_STANDARDS = ["CIS", "NIST"]
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))


    if standard not in VALID_STANDARDS:
        print(f"Error: '{standard}' is not a valid standard.")
        sys.exit(1)

    audit_dir = os.path.join(BASE_DIR, standard, "Audits", version)


    if not os.path.isdir(audit_dir):
        print(f" Error: Version '{version}' not found in {standard}/Audits/")
        sys.exit(1)

    output_file = f"combined_{standard}_{version}.sh"
    result_file = f"results_{standard}_{version}.json"

    if exclude_audits is None:
        exclude_audits = set()
    else:
        exclude_audits = set(a.replace('_', '.') for a in exclude_audits)

    def get_audit_files():
        audit_files = []
        for root, dirs, files in os.walk(audit_dir):
            rel_path = os.path.relpath(root, audit_dir)
            depth = 0 if rel_path == '.' else rel_path.count(os.sep) + 1
            if depth > 2:
                continue
            for file in files:
                if file.endswith('.audit'):
                    audit_id_guess = os.path.splitext(file)[0].replace('_', '.')
                    if audit_id_guess not in exclude_audits:
                        audit_files.append(os.path.join(root, file))
        return audit_files

    audit_files = get_audit_files()
    audit_data = {}

    functions = []
    runners = []

    for path in audit_files:
        audit_id, audit_name, script, depended, condition = extract_script_blocks(path)
        audit_id_norm = audit_id.replace('_', '.')
        if audit_id_norm in exclude_audits:
            continue
        if audit_id and script:
            audit_data[audit_id] = {
                'name': audit_name,
                'script': script,
                'depended_audits': depended,
                'condition': condition
            }

    for audit_id, data in audit_data.items():
        if audit_id.replace('_', '.') in exclude_audits:
            continue

        func_name = audit_id_to_func_name(audit_id)
        script = strip_outer_braces(data['script'])

        functions.append(f"{func_name}() {{\n{script}\n}}\n")

        runner = f"""
run_{func_name}() {{
    local status # Added local declaration
    local output # Added local declaration
    output=$({func_name} 2>&1)
    if echo "$output" | grep -q "\\*\\* ERROR \\*\\*"; then
        status=$(echo "ERROR")
    elif echo "$output" | grep -q "\\*\\* PASS \\*\\*"; then
        status=$(echo "PASS")
    else
        status=$(echo "FAIL")
    fi

    jq -n --arg audit_id "{audit_id}" --arg audit_name "{data['name']}" --arg status "$status" --arg output "$output" \\
        '{{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}}' >> tmp_results.json
"""

        condition = data.get("condition")
        if condition:
            match_type = condition.get("match")
            all_depended_ids = [
                x.replace('_', '.') if '_' in x else x for x in data.get("depended_audits", [])
                if x.replace('_', '.') not in exclude_audits
            ]

            runner += "    declare -A executed_dependent_audits\n" # Declare associative array to track executed
            
            # --- DEBUG START ---
            runner += f'    echo "DEBUG: Parent audit {audit_id} status is: $status"\n'
            # --- DEBUG END ---

            if match_type in ("output_contains", "output_regex"):
                runner += "    matched_case=false\n" # Renamed from 'matched' to avoid confusion

                for case in condition.get("cases", []):
                    val = case["value"]
                    run_list = [
                        x.replace('_', '.') if '_' in x else x for x in case["run"]
                        if x.replace('_', '.') not in exclude_audits
                    ]

                    if not run_list:
                        continue  # Skip this case entirely if all run targets are excluded

                    if match_type == "output_regex":
                        runner += f'    if echo "$output" | grep -Eq "{val}"; then\n'
                    else:
                        runner += f'    if echo "$output" | grep -q "{val}"; then\n'

                    for dep_id in run_list:
                        dep_func = audit_id_to_func_name(dep_id)
                        runner += f'        run_{dep_func}\n'
                        runner += f'        executed_dependent_audits["{dep_id}"]=1\n' # Mark as executed
                    runner += "        matched_case=true\n"
                    runner += "    fi\n"

                default = condition.get("default", {})
                
                runner += f'    echo "DEBUG: Entering conditional block for {audit_id}. Current status: $status"\n' # Additional debug
                # Handle dependent audits based on parent status and matched_case
                runner += '    if [[ "$status" = "FAIL" ]] || [[ "$status" = "ERROR" ]]; then\n' # Changed to [[ ]]
                runner += f'        echo "DEBUG: Inside FAIL/ERROR conditional for {audit_id}. Status being evaluated: $status"\n' # New precise debug
                for dep_id in all_depended_ids:
                    if dep_id in exclude_audits:
                        continue
                    dep_name = audit_data.get(dep_id, {}).get("name", dep_id)
                    runner += f'        if [[ -z "${{executed_dependent_audits["{dep_id}"]}}" ]]; then\n' # Changed to [[ ]]
                    runner += f'            jq -n --arg audit_id "{dep_id}" --arg audit_name "{dep_name}" \\\n'
                    runner += f'                --arg status "FAIL" --arg output "Skipped: prerequisite audit {audit_id} failed" \\\n'
                    runner += f'                \'{{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}}\' >> tmp_results.json\n'
                    runner += '        fi\n'
                runner += '    else # Parent audit passed\n'
                runner += f'        echo "DEBUG: Inside PASS conditional for {audit_id}. Status being evaluated: $status"\n' # New precise debug
                runner += '        if [[ "$matched_case" = false ]]; then\n' # Changed to [[ ]]
                if default.get("action") == "skip":
                    default_status = default.get("status", "PASS").upper()
                    for dep_id in all_depended_ids:
                        if dep_id in exclude_audits:
                            continue
                        dep_name = audit_data.get(dep_id, {}).get("name", dep_id)
                        runner += f'            if [[ -z "${{executed_dependent_audits["{dep_id}"]}}" ]]; then\n' # Changed to [[ ]]
                        if default_status == "PASS":
                            reason = f"Skipped: not applicable due to {audit_id}"
                        else:
                            reason = f"Skipped: audit not applicable because {audit_id} conditions not met"
                        runner += f'                jq -n --arg audit_id "{dep_id}" --arg audit_name "{dep_name}" \\\n'
                        runner += f'                    --arg status "{default_status}" --arg output "{reason}" \\\n'
                        runner += f'                    \'{{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}}\' >> tmp_results.json\n' # THIS IS THE CRITICAL FIX
                        runner += '            fi\n'
                else:
                    runner += f'            echo "Warning: No conditions matched for audit {audit_id} and no default action defined"\n'
                runner += '        else # A case matched when parent passed, now skip others that were not executed\n'
                default_status = default.get("status", "PASS").upper() # Use default status for skipped, typically PASS
                for dep_id in all_depended_ids:
                    if dep_id in exclude_audits:
                        continue
                    dep_name = audit_data.get(dep_id, {}).get("name", dep_id)
                    runner += f'            if [[ -z "${{executed_dependent_audits["{dep_id}"]}}" ]]; then\n' # Changed to [[ ]]
                    reason = f"Skipped: not applicable as a different firewall was detected by {audit_id}"
                    runner += f'                jq -n --arg audit_id "{dep_id}" --arg audit_name "{dep_name}" \\\n'
                    runner += f'                    --arg status "{default_status}" --arg output "{reason}" \\\n'
                    runner += f'                    \'{{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}}\' >> tmp_results.json\n' # THIS IS THE CRITICAL FIX
                    runner += '            fi\n'
                runner += '        fi\n'
                runner += '    fi\n'
                
        runner += "}\n"
        runners.append(runner)

    with open(output_file, 'w', newline='\n') as out:
        out.write("#!/usr/bin/env bash\n\n")
        out.writelines(func + "\n" for func in functions)
        out.writelines(runner + "\n" for runner in runners)

        out.write("""
# Run all root audits and collect JSON output
rm -f tmp_results.json
touch tmp_results.json

""")

        all_audits = set(audit_data.keys())
        dependent_audits = set()
        for data in audit_data.values():
            dependent_audits.update([d.replace('_', '.') for d in data.get("depended_audits", [])])

        root_audits = all_audits - dependent_audits - exclude_audits

        def sort_key(aid):
            parts = aid.split('.')
            return [int(p) if p.isdigit() else p for p in parts]

        for audit_id in sorted(root_audits, key=sort_key):
            if audit_id.replace('_', '.') not in exclude_audits:
                func_name = audit_id_to_func_name(audit_id)
                out.write(f"run_{func_name}\n")

        out.write(f"""
# Finalize JSON
jq -s 'sort_by(.audit_id | split(".") | map(try tonumber catch .))' tmp_results.json > /tmp/{result_file}
rm -f tmp_results.json
echo "Audit complete. Results saved to {result_file}"
""")

    os.chmod(output_file, 0o755)
    print(f"Script written to: {output_file}")

    if method == "remote":
        if not ssh_info or not all(k in ssh_info for k in ("username", "password", "ip", "port")):
            raise ValueError("Missing SSH info for remote execution")
        
        from ...remote import linux_connection
        linux_connection(
            script_name=output_file,
            username=ssh_info["username"],
            password=ssh_info["password"],
            ip=ssh_info["ip"],
            port=ssh_info["port"],
            result_name=result_file
        )

        # Improved validation with error handling
        json_path = os.path.join(os.path.dirname(__file__), "results_CIS_Ubuntu_Linux_24.04.json")
        csv_path = os.path.join(BASE_DIR, standard, version + ".csv")

        output_csv_file = os.path.join(os.path.dirname(__file__), f"results_{standard}_{version}.csv")
        
        try:
            # Check if required files exist
            if not os.path.exists(json_path):
                print(f"Warning: JSON results file not found at {json_path}")
                return
                
            if not os.path.exists(csv_path):
                print(f"Warning: CSV metadata file not found at {csv_path}")
                print(f"Expected location: {csv_path}")
                return
            
            print(f"Creating Excel report from:")
            print(f"  JSON: {json_path}")
            print(f"  CSV:  {csv_path}")
            print(f"  Output_CSV: {output_csv_file}")
            
            from .validate import validateResult
            validateResult(json_path=json_path, csv_path=csv_path, output_csv_path=output_csv_file)
            
        except Exception as e:
            print(f"Error during validation: {e}")
            print("JSON and CSV files are available for manual processing")