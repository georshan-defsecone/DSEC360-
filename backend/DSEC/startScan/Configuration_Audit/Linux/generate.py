import os
import re
import yaml
import sys

def extract_script_blocks(audit_file):
    """
    Extracts audit ID, name, script, dependencies, and conditions from an audit file.
    """
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
            # Safely load YAML for the condition block
            condition = yaml.safe_load("condition:\n" + condition_match.group(1))
            condition = condition['condition']
        except Exception as e:
            print(f"Error parsing condition in {audit_file}: {e}")

    return audit_id, audit_name, script, depended, condition

def audit_id_to_func_name(audit_id):
    """
    Converts an audit ID into a valid shell function name.
    """
    pattern = r'\W|^(?=\d)' # Matches non-alphanumeric characters or digits at the start
    return "a_" + re.sub(pattern, '_', audit_id)

def strip_outer_braces(script):
    """
    Removes outer curly braces from a script string if they exist.
    This is common in shell script blocks embedded in YAML.
    """
    lines = script.strip().splitlines()
    if lines and lines[0].strip() == '{' and lines[-1].strip() == '}':
        return '\n'.join(lines[1:-1]).strip()
    return script.strip()

def ubuntu(standard, version, exclude_audits=None, method="agent", ssh_info=None):
    """
    Generates a shell script for configuration audits based on a given standard and version.

    Args:
        standard (str): The security standard (e.g., "CIS", "NIST").
        version (str): The version of the standard (e.g., "Ubuntu_Linux_24.04").
        exclude_audits (list, optional): A list of audit IDs to exclude. Defaults to None.
        method (str, optional): Execution method ("agent" or "remote"). Defaults to "agent".
        ssh_info (dict, optional): SSH connection details for remote execution.
                                   Required if method is "remote".
    """
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
    result_file = f"results_{standard}_{version}.json" # Default result file name

    if exclude_audits is None:
        exclude_audits = set()
    else:
        # Normalize excluded audit IDs for consistent comparison
        exclude_audits = set(a.replace('_', '.') for a in exclude_audits)

    def get_audit_files():
        """
        Recursively finds all .audit files within the audit directory,
        excluding those marked for exclusion and limiting depth.
        """
        audit_files = []
        for root, dirs, files in os.walk(audit_dir):
            rel_path = os.path.relpath(root, audit_dir)
            depth = 0 if rel_path == '.' else rel_path.count(os.sep) + 1
            if depth > 2: # Limit recursion depth to 2 subdirectories
                continue
            for file in files:
                if file.endswith('.audit'):
                    audit_id_guess = os.path.splitext(file)[0].replace('_', '.')
                    if audit_id_guess not in exclude_audits:
                        audit_files.append(os.path.join(root, file))
        return audit_files

    audit_files = get_audit_files()
    audit_data = {} # Stores parsed data for each audit

    functions = [] # List to hold shell function definitions
    runners = []   # List to hold shell function calls and result processing logic

    # Parse all audit files and store their data
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

    # Generate shell functions and their runners
    for audit_id, data in audit_data.items():
        if audit_id.replace('_', '.') in exclude_audits:
            continue

        func_name = audit_id_to_func_name(audit_id)
        script = strip_outer_braces(data['script'])

        # Add the audit script as a shell function
        functions.append(f"{func_name}() {{\n{script}\n}}\n")

        # Generate the runner function for each audit
        runner = f"""
run_{func_name}() {{
    local status # Declare local variable for audit status
    local output # Declare local variable for audit output
    output=$({func_name} 2>&1) # Execute the audit function and capture its output and errors

    # Determine audit status based on output
    if echo "$output" | grep -q "\\*\\* ERROR \\*\\*"; then
        status="ERROR"
    elif echo "$output" | grep -q "\\*\\* PASS \\*\\*"; then
        status="PASS"
    else
        status="FAIL"
    fi

    # Conditionally write results based on output_format (json or tsv)
    if [[ "$output_format" == "json" ]]; then
        jq -n --arg audit_id "{audit_id}" --arg audit_name "{data['name']}" --arg status "$status" --arg output "$output" \\
            '{{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}}' >> tmp_results.json
    else
        # Flatten output for TSV to avoid issues with newlines/tabs
        output_flat=$(echo "$output" | tr '\\t' ' ' | tr '\\n' ' ' | sed 's/  */ /g')
        printf "%s\\t%s\\t%s\\t%s\\n" "{audit_id}" "{data['name']}" "$status" "$output_flat" >> "$result_file"
    fi
"""

        condition = data.get("condition")
        if condition:
            match_type = condition.get("match")
            all_depended_ids = [
                x.replace('_', '.') if '_' in x else x for x in data.get("depended_audits", [])
                if x.replace('_', '.') not in exclude_audits
            ]

            runner += "    declare -A executed_dependent_audits\n" # Associative array to track executed dependents
            runner += f'    echo "DEBUG: Parent audit {audit_id} status is: $status"\n' # Debugging line

            if match_type in ("output_contains", "output_regex"):
                runner += "    matched_case=false\n" # Flag to check if any condition case matched

                for case in condition.get("cases", []):
                    val = case["value"]
                    run_list = [
                        x.replace('_', '.') if '_' in x else x for x in case["run"]
                        if x.replace('_', '.') not in exclude_audits
                    ]

                    if not run_list:
                        continue # Skip this case if all run targets are excluded

                    # Check if output matches the condition
                    if match_type == "output_regex":
                        runner += f'    if echo "$output" | grep -Eq "{val}"; then\n'
                    else:
                        runner += f'    if echo "$output" | grep -q "{val}"; then\n'

                    # Run dependent audits if condition matches
                    for dep_id in run_list:
                        dep_func = audit_id_to_func_name(dep_id)
                        runner += f'        run_{dep_func}\n'
                        runner += f'        executed_dependent_audits["{dep_id}"]=1\n' # Mark as executed
                    runner += "        matched_case=true\n"
                    runner += "    fi\n"

                default = condition.get("default", {})
               
                runner += f'    echo "DEBUG: Entering conditional block for {audit_id}. Current status: $status"\n'
                # Handle dependent audits based on parent status and whether a case matched
                runner += '    if [[ "$status" = "FAIL" ]] || [[ "$status" = "ERROR" ]]; then\n'
                runner += f'        echo "DEBUG: Inside FAIL/ERROR conditional for {audit_id}. Status being evaluated: $status"\n'
                # If parent audit failed/errored, skip all its dependent audits
                for dep_id in all_depended_ids:
                    if dep_id in exclude_audits:
                        continue
                    dep_name = audit_data.get(dep_id, {}).get("name", dep_id)
                    runner += f'        if [[ -z "${{executed_dependent_audits["{dep_id}"]}}" ]]; then\n' # If not already executed
                    runner += '            if [[ "$output_format" == "json" ]]; then\n'
                    runner += f'                jq -n --arg audit_id "{dep_id}" --arg audit_name "{dep_name}" \\\n'
                    runner += f'                    --arg status "FAIL" --arg output "Skipped: prerequisite audit {audit_id} failed" \\\n'
                    runner += f'                    \'{{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}}\' >> tmp_results.json\n'
                    runner += '            else\n'
                    runner += f'                output_flat=$(echo "Skipped: prerequisite audit {audit_id} failed" | tr \'\\t\' \' \' | tr \'\\n\' \' \' | sed \'s/  */ /g\')\n'
                    runner += f'                printf "%s\\t%s\\t%s\\t%s\\n" "{dep_id}" "{dep_name}" "FAIL" "$output_flat" >> "$result_file"\n'
                    runner += '            fi\n'
                    runner += '        fi\n'
                runner += '    else\n' # Corrected: Added newline after else
                runner += '    # Parent audit passed\n' # Added for clarity
                runner += f'        echo "DEBUG: Inside PASS conditional for {audit_id}. Status being evaluated: $status"\n'
                runner += '        if [[ "$matched_case" = false ]]; then\n' # If parent passed but no specific case matched
                if default.get("action") == "skip":
                    default_status = default.get("status", "PASS").upper()
                    for dep_id in all_depended_ids:
                        if dep_id in exclude_audits:
                            continue
                        dep_name = audit_data.get(dep_id, {}).get("name", dep_id)
                        runner += f'            if [[ -z "${{executed_dependent_audits["{dep_id}"]}}" ]]; then\n'
                        if default_status == "PASS":
                            reason = f"Skipped: not applicable due to {audit_id}"
                        else:
                            reason = f"Skipped: audit not applicable because {audit_id} conditions not met"
                        runner += '                if [[ "$output_format" == "json" ]]; then\n'
                        runner += f'                    jq -n --arg audit_id "{dep_id}" --arg audit_name "{dep_name}" \\\n'
                        runner += f'                        --arg status "{default_status}" --arg output "{reason}" \\\n'
                        runner += f'                        \'{{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}}\' >> tmp_results.json\n'
                        runner += '                else\n'
                        runner += f'                    output_flat=$(echo "{reason}" | tr \'\\t\' \' \' | tr \'\\n\' \' \' | sed \'s/  */ /g\')\n'
                        runner += f'                    printf "%s\\t%s\\t%s\\t%s\\n" "{dep_id}" "{dep_name}" "{default_status}" "$output_flat" >> "$result_file"\n'
                        runner += '                fi\n'
                        runner += '            fi\n'
                else:
                    runner += f'            echo "Warning: No conditions matched for audit {audit_id} and no default action defined"\n'
                runner += '        else\n' # Corrected: Added newline after else
                runner += '        # A case matched when parent passed, now skip others that were not executed\n' # Added for clarity
                default_status = default.get("status", "PASS").upper()
                for dep_id in all_depended_ids:
                    if dep_id in exclude_audits:
                        continue
                    dep_name = audit_data.get(dep_id, {}).get("name", dep_id)
                    runner += f'            if [[ -z "${{executed_dependent_audits["{dep_id}"]}}" ]]; then\n'
                    reason = f"Skipped: not applicable as a different firewall was detected by {audit_id}"
                    runner += '                if [[ "$output_format" == "json" ]]; then\n'
                    runner += f'                    jq -n --arg audit_id "{dep_id}" --arg audit_name "{dep_name}" \\\n'
                    runner += f'                        --arg status "{default_status}" --arg output "{reason}" \\\n'
                    runner += f'                        \'{{"audit_id": $audit_id, "audit_name": $audit_name, "status": $status, "output": $output}}\' >> tmp_results.json\n'
                    runner += '                else\n'
                    runner += f'                    output_flat=$(echo "{reason}" | tr \'\\t\' \' \' | tr \'\\n\' \' \' | sed \'s/  */ /g\')\n'
                    runner += f'                    printf "%s\\t%s\\t%s\\t%s\\n" "{dep_id}" "{dep_name}" "{default_status}" "$output_flat" >> "$result_file"\n'
                    runner += '                fi\n'
                    runner += '            fi\n'
                runner += '        fi\n'
                runner += '    fi\n'
               
        runner += "}\n"
        runners.append(runner)

    # Write the combined shell script
    with open(output_file, 'w', newline='\n') as out:
        out.write("#!/usr/bin/env bash\n\n")
        out.writelines(func + "\n" for func in functions) # Write all audit functions
        out.writelines(runner + "\n" for runner in runners) # Write all runner functions

        # Add logic to detect jq and set output format at the beginning of the script execution
        out.write(r'''
# Detect if jq is available
if command -v jq >/dev/null 2>&1; then
    output_format="json"
    rm -f tmp_results.json # Clean up any previous temporary JSON file
    touch tmp_results.json # Create an empty temporary JSON file
else
    output_format="tsv"
    # Adjust result_file name for TSV output
    result_file="/tmp/''' + result_file.replace(".json", ".tsv") + r'''"
    echo -e "CIS.No.\tName\tResult\tOutput" > "$result_file" # Write TSV header
fi

''')

        # Determine root audits (audits that don't depend on others)
        all_audits = set(audit_data.keys())
        dependent_audits = set()
        for data in audit_data.values():
            dependent_audits.update([d.replace('_', '.') for d in data.get("depended_audits", [])])

        root_audits = all_audits - dependent_audits - exclude_audits

        def sort_key(aid):
            """Helper to sort audit IDs numerically."""
            parts = aid.split('.')
            return [int(p) if p.isdigit() else p for p in parts]

        # Run all root audits
        for audit_id in sorted(root_audits, key=sort_key):
            if audit_id.replace('_', '.') not in exclude_audits:
                func_name = audit_id_to_func_name(audit_id)
                out.write(f"run_{func_name}\n")

        # Finalize results based on output format
        out.write(f'''
if [[ "$output_format" == "json" ]]; then
    # Sort and format JSON results
    jq -s 'sort_by(.audit_id | split(".") | map(try tonumber catch .))' tmp_results.json > /tmp/{result_file}
    rm -f tmp_results.json # Clean up temporary JSON file
    echo "Audit complete. Results saved to {result_file}"
else
    echo "Audit complete. Results saved to $result_file"
fi
''')

    os.chmod(output_file, 0o755) # Make the generated script executable
    print(f"Script written to: {output_file}")

    # Handle remote execution if specified
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

        # Improved validation with error handling for post-execution processing
        json_path = os.path.join(os.path.dirname(__file__), "results_CIS_Ubuntu_Linux_24.04.json")
        csv_path = os.path.join(BASE_DIR, standard, version + ".csv")

        output_csv_file = os.path.join(os.path.dirname(__file__), f"results_{standard}_{version}.csv")
       
        try:
            # Check if required files exist before attempting validation
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