import csv
import sys
import os
import re
import argparse
import xml.etree.ElementTree as ET


#needed
def append_data_to_csvfile(file_name, headers, data):
    try:
        # Check if the file exists and is not empty
        file_exists = os.path.isfile(file_name) and os.path.getsize(file_name) > 0

        with open(file_name, mode='a', newline='') as file:
            writer = csv.writer(file)

            # Write headers if the file is new or empty
            if not file_exists:
                writer.writerow(headers)

            # Append the actual data
            writer.writerow(data)

    except IOError as e:
        print(f"IO error occurred: {e}")


class FortiGate:

    fortigate_heading = ['CIS.NO', 'Subject', 'Description', 'Status','Current_Setting', 'Remediation']

    @staticmethod
    def get_unset_keys(block: str):
        """
        Extracts keys that are explicitly unset in a FortiGate config block.
        Example match: 'unset password' → returns 'password'
        """
        unset_keys = set()
        pattern = re.findall(r'^\s*unset\s+(\S+)', block, re.MULTILINE)
        for match in pattern:
            unset_keys.add(match.strip())
        return unset_keys


    @staticmethod
    def get_all_edit_names(block: str) -> list:
        """
        Extracts all `edit` block names from a FortiGate configuration block.

        Args:
            block (str): Multiline FortiGate config block.

        Returns:
            List[str]: All edit names found (e.g., profile or interface names).
        """
        edit_pattern = r'\bedit\s+"?([\w\-_.]+)"?'
        return re.findall(edit_pattern, block)


    # @staticmethod
    # def split_antivirus_profiles(raw_block):
    #     profiles = []
    #     current_profile = []
    #     inside_profile = False

    #     for line in raw_block.splitlines():
    #         if line.strip().startswith("edit"):
    #             inside_profile = True
    #             current_profile = [line]
    #         elif line.strip() == "next":
    #             current_profile.append(line)
    #             profiles.append("\n".join(current_profile))
    #             inside_profile = False
    #         elif inside_profile:
    #             current_profile.append(line)

    #     return profiles


    #needed
    @staticmethod
    def remove_old_csv(file_name):
        file_exists = os.path.isfile(file_name) 
        if file_exists:
            os.remove(file_name)



    @staticmethod
    def get_edit_block_data(config, edit_name):
        # Split the config into blocks by the 'edit' keyword
        blocks = config.split('edit ')[1:]

        # Create a dictionary to hold the parsed blocks
        parsed_blocks = {}

        # Process each block to store it in the dictionary with the 'edit' name as the key
        for block in blocks:
            block = block.strip()
            current_edit_name = block.split('"')[1]
            block_data = block.rsplit('next', 1)[0].strip()
            parsed_blocks[current_edit_name] = block_data

        # Retrieve data for the specified block
        if edit_name in parsed_blocks:
            return parsed_blocks[edit_name]
        else:
            return False

    #needed
    @staticmethod
    def get_metadata_from_csv(csv_path, check_id):
        with open(csv_path, 'r', newline='', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row['CIS_NO'] == check_id or row.get('\ufeffCIS_NO') == check_id:
                    subject = row.get('Subject', '')
                    description = row.get('Description', '')
                    remediation = row.get('Remediation', '')
                    return subject, description, remediation
        return '', '', ''


    #needed
    @staticmethod
    def get_data_from_set_list(data):
        key_value_pairs = {}

        # Match only valid `set <key> <value>` lines
        lines = data.strip().splitlines()
        for line in lines:
            line = line.strip()
            if line.lower().startswith('set '):
                parts = line.split(maxsplit=2)
                if len(parts) >= 3:
                    key = parts[1]
                    value_raw = parts[2]
                    # Parse quoted or space-separated values
                    value_parts = re.findall(r'\'[^\']*\'|\"[^\"]*\"|\S+', value_raw)
                    value_parts = [s.strip('"').strip("'") for s in value_parts]

                    # Handle multiple values
                    if key in key_value_pairs:
                        key_value_pairs[key] += tuple(value_parts)
                    else:
                        key_value_pairs[key] = tuple(value_parts)

        return key_value_pairs
    
    # #needed
    # @staticmethod
    # def get_unset_keys(data):
        unset_keys = []

        # Match only valid `unset <key>` lines
        lines = data.strip().splitlines()
        for line in lines:
            line = line.strip()
            if line.lower().startswith('unset '):
                parts = line.split()
                if len(parts) == 2:
                    unset_keys.append(parts[1].strip())

        return unset_keys


    
    @staticmethod
    def extract_policy(file_path, policy_name, match_exact=False):
        import re

        policies = []
        current_policy = []
        inside_policy = False

        with open(file_path, 'r') as file:
            for line in file:
                line = line.rstrip()

                # Determine match condition
                if match_exact:
                    is_match = line == policy_name
                else:
                    is_match = re.match(rf'^{policy_name}', line)

                if is_match:
                    if inside_policy:
                        policies.append(''.join(current_policy))
                        current_policy = []
                    inside_policy = True

                if inside_policy:
                    current_policy.append(line + '\n')

                if re.match(r'^end$', line) and inside_policy:
                    current_policy.append('\n')  # Optional: add extra newline after end
                    policies.append(''.join(current_policy))
                    current_policy = []
                    inside_policy = False

            # Catch incomplete block
            if inside_policy:
                policies.append(''.join(current_policy))

        return policies

    #needed
    @staticmethod
    def split_values(data, key):
        return ', '.join(value for value in data[key]) if key in data else None


    
    # 1 Network Settings

    # 1.1 Ensure DNS server is configured
    @staticmethod
    def check_system_dns(input_file, metadata_file,output_csv_location):
        cis_no = '1.1'
        name, description, base_remediation = FortiGate.get_metadata_from_csv(metadata_file, cis_no)

        dns_blocks = FortiGate.extract_policy(input_file, 'config system dns', match_exact=True)

        if dns_blocks:
            for block in dns_blocks:
                values = FortiGate.get_data_from_set_list(block)

                primary = values.get('primary', ('',))[0]
                secondary = values.get('secondary', ('',))[0]

                current_setting = f"Primary: {primary or 'Not Found'}\nSecondary: {secondary or 'Not Found'}"

                # Initialize
                status = 'FAIL'
                reason_for_fail = ''

                if not primary and not secondary:
                    reason_for_fail = 'Primary and Secondary DNS not configured'
                elif primary and secondary:
                    status = 'PASS'
                    remediation = ''
                else:
                    reason_for_fail = 'Only one DNS configured or value missing'

                if status == 'FAIL':
                    remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)

                append_data = [cis_no, name, description, status, current_setting, remediation]
                append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)
        else:
            # Block not found
            status = 'FAIL'
            current_setting = 'config system dns block not found in config'
            reason_for_fail = 'DNS configuration block missing entirely'
            remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)

            append_data = [cis_no, name, description, status, current_setting, remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)


    # # 2 System Settings

    # 2.1.1 Ensure 'Pre-Login Banner' is set
    @staticmethod
    def pre_login_banner(input_file, metadata_file,output_csv_location):
        cis_no = '2.1.1'
        name, description, base_remediation = FortiGate.get_metadata_from_csv(metadata_file, cis_no)

        status = 'FAIL'
        current_setting = ''
        reason_for_fail = ''

        datas = FortiGate.extract_policy(input_file, 'config system global', match_exact=True)

        if datas:
            for data in datas:
                values = FortiGate.get_data_from_set_list(data)
                banner_key = 'pre-login-banner'
                pre_login_banner = values.get(banner_key, ('',))[0].strip().lower()

                if pre_login_banner == 'enable':
                    status = 'PASS'
                    current_setting = "Pre-Login-Banner: enable"
                    remediation = ''
                elif pre_login_banner:
                    reason_for_fail = f"Pre-Login-Banner is set to '{pre_login_banner}', but it must be 'enable'"
                    current_setting = f"Pre-Login-Banner: {pre_login_banner}"
                    remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)
                else:
                    reason_for_fail = "Pre-Login-Banner setting is missing"
                    current_setting = "Pre-Login-Banner: Not Found"
                    remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)

                append_data = [cis_no, name, description, status, current_setting, remediation]
                append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)
                break  # Assume only one global block
        else:
            current_setting = "config system global block not found in config"
            reason_for_fail = "Global system configuration block is missing"
            remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)

            append_data = [cis_no, name, description, status, current_setting, remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)



    # 2.1.2 Ensure 'Post-Login Banner' is set
    @staticmethod
    def post_login_banner(input_file, metadata_file,output_csv_location):
        cis_no = '2.1.2'
        name, description, base_remediation = FortiGate.get_metadata_from_csv(metadata_file, cis_no)

        status = 'FAIL'
        current_setting = ''
        reason_for_fail = ''

        datas = FortiGate.extract_policy(input_file, 'config system global', match_exact=True)

        if datas:
            for data in datas:
                values = FortiGate.get_data_from_set_list(data)
                banner_key = 'post-login-banner'
                post_login_banner = values.get(banner_key, ('',))[0].strip().lower()

                if post_login_banner == 'enable':
                    status = 'PASS'
                    current_setting = "Post-Login-Banner: enable"
                    remediation = ''
                elif post_login_banner:
                    reason_for_fail = f"Post-Login-Banner is set to '{post_login_banner}', but it must be 'enable'"
                    current_setting = f"Post-Login-Banner: {post_login_banner}"
                    remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)
                else:
                    reason_for_fail = "Post-Login-Banner setting is missing"
                    current_setting = "Post-Login-Banner: Not Found"
                    remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)

                append_data = [cis_no, name, description, status, current_setting, remediation]
                append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)
                break
        else:
            current_setting = "config system global block not found in config"
            reason_for_fail = "Global system configuration block is missing"
            remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)

            append_data = [cis_no, name, description, status, current_setting, remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)


    # 2.1.4 Ensure correct system time is configured through NTP
    @staticmethod
    def sys_time(input_file, metadata_file,output_csv_location):
        cis_no = '2.1.4'
        name, description, base_remediation = FortiGate.get_metadata_from_csv(metadata_file, cis_no)

        status = 'FAIL'
        current_setting = ''
        reason_for_fail = ''

        datas = FortiGate.extract_policy(input_file, 'config system ntp', match_exact=True)

        if datas:
            for data in datas:
                values = FortiGate.get_data_from_set_list(data)

                ntp_type = values.get('type', ('',))[0].strip().lower()
                ntpsync = values.get('ntpsync', ('',))[0].strip().lower()
                servers = values.get('server', ())

                has_servers = len(servers) > 0
                server_info = ', '.join(servers) if has_servers else 'Not Found'

                current_setting = (
                    f"Type: {ntp_type or 'Not Found'}, "
                    f"NTP Sync: {ntpsync or 'Not Found'}, "
                    f"Servers: {server_info}"
                )

                # Evaluate compliance
                if ntp_type == 'custom' and ntpsync == 'enable' and has_servers:
                    status = 'PASS'
                    remediation = ''
                else:
                    fail_reasons = []
                    if ntp_type != 'custom':
                        fail_reasons.append("NTP type is not 'custom'")
                    if ntpsync != 'enable':
                        fail_reasons.append("NTP synchronization is not enabled")
                    if not has_servers:
                        fail_reasons.append("No NTP servers are configured")

                    reason_for_fail = '; '.join(fail_reasons)
                    remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)

                append_data = [cis_no, name, description, status, current_setting, remediation]
                append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)
                break
        else:
            current_setting = 'config system ntp block not found'
            reason_for_fail = 'NTP configuration block is missing'
            remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)

            append_data = [cis_no, name, description, status, current_setting, remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)



    # 2.1.5 Ensure hostname is set
    @staticmethod
    def hostname(input_file, metadata_file,output_csv_location):
        cis_no = '2.1.5'
        name, description, base_remediation = FortiGate.get_metadata_from_csv(metadata_file, cis_no)

        status = 'FAIL'
        current_setting = ''
        reason_for_fail = ''

        # Extract `config system global` block (should be unique)
        datas = FortiGate.extract_policy(input_file, 'config system global', match_exact=True)

        if datas:
            data = datas[0]  # Only the first block is expected
            values = FortiGate.get_data_from_set_list(data)
            hostname = values.get('hostname', ('',))[0].strip()

            current_setting = f"Hostname: {hostname or 'Not Found'}"

            if hostname:
                status = 'PASS'
                remediation = ''
            else:
                reason_for_fail = "Hostname is missing"
                remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)

            append_data = [cis_no, name, description, status, current_setting, remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)
        else:
            current_setting = "config system global block not found"
            reason_for_fail = "The configuration block for hostname was not found"
            remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)

            append_data = [cis_no, name, description, 'FAIL', current_setting, remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)



#     # 2.1.7 Disable USB Firmware and configuration installation
    @staticmethod
    def disable_usb_firmware(input_file, metadata_file,output_csv_location):
        cis_no = '2.1.7'
        name, description, base_remediation = FortiGate.get_metadata_from_csv(metadata_file, cis_no)

        status = 'FAIL'
        current_setting = ''
        reason_for_fail = ''

        datas = FortiGate.extract_policy(input_file, 'config system auto-install', match_exact=True)
        if datas:
            for data in datas:
                values = FortiGate.get_data_from_set_list(data)

                config = values.get('auto-install-config', ('',))[0].strip().lower()
                image = values.get('auto-install-image', ('',))[0].strip().lower()

                current_setting = (
                    f"Auto-install-config: {config or 'Not Found'}\n"
                    f"Auto-install-image: {image or 'Not Found'}"
                )

                if config == 'disable' and image == 'disable':
                    status = 'PASS'
                    remediation = ''
                else:
                    reasons = []
                    if config != 'disable':
                        reasons.append("auto-install-config is not set to disable")
                    if image != 'disable':
                        reasons.append("auto-install-image is not set to disable")
                    reason_for_fail = "; ".join(reasons)
                    remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)

                append_data = [cis_no, name, description, status, current_setting, remediation]
                append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)
                break
        else:
            current_setting = 'config system auto-install block not found'
            reason_for_fail = 'Missing config block to evaluate auto-install settings'
            remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)

            append_data = [cis_no, name, description, status, current_setting, remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)


    # 2.1.8 Disable static keys for TLS
    @staticmethod
    def disable_static_key_4_tls(input_file, metadata_file,output_csv_location):
        cis_no = '2.1.8'
        name, description, base_remediation = FortiGate.get_metadata_from_csv(metadata_file, cis_no)

        status = 'FAIL'
        current_setting = ''
        reason_for_fail = ''

        datas = FortiGate.extract_policy(input_file, 'config system global', match_exact=True)
        if datas:
            for data in datas:
                values = FortiGate.get_data_from_set_list(data)
                raw_value = values.get('ssl-static-key-ciphers', ('',))[0].strip().lower()

                current_setting = f"ssl-static-key-ciphers: {raw_value or 'Not Found'}"

                if raw_value == 'disable':
                    status = 'PASS'
                    remediation = ''
                else:
                    if not raw_value:
                        reason_for_fail = "ssl-static-key-ciphers not configured (default is 'enable')"
                    else:
                        reason_for_fail = f"ssl-static-key-ciphers is set to '{raw_value}' instead of 'disable'"
                    remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)

                append_data = [cis_no, name, description, status, current_setting, remediation]
                append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)
                break  # Only one block is expected
        else:
            current_setting = 'config system global block not found'
            reason_for_fail = "Missing configuration block"
            remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)

            append_data = [cis_no, name, description, status, current_setting, remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)


#     # 2.1.9 Enable Global Strong Encryption
    @staticmethod
    def global_strong_encryption(input_file, metadata_file,output_csv_location):
        cis_no = '2.1.9'
        name, description, base_remediation = FortiGate.get_metadata_from_csv(metadata_file, cis_no)

        status = 'FAIL'
        current_setting = ''
        reason_for_fail = ''

        datas = FortiGate.extract_policy(input_file, 'config system global', match_exact=True)
        if datas:
            for data in datas:
                values = FortiGate.get_data_from_set_list(data)
                strong_crypto = values.get('strong-crypto', ('',))[0].strip().lower()

                current_setting = f"strong-crypto: {strong_crypto or 'Not Found'}"

                if strong_crypto == 'enable':
                    status = 'PASS'
                    remediation = ''
                else:
                    if not strong_crypto:
                        reason_for_fail = "strong-crypto not configured (explicit 'enable' required)"
                    else:
                        reason_for_fail = f"strong-crypto is set to '{strong_crypto}' instead of 'enable'"
                    remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)

                append_data = [cis_no, name, description, status, current_setting, remediation]
                append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)
                break  # Only need first match
        else:
            current_setting = 'config system global block not found'
            reason_for_fail = 'Missing configuration block'
            remediation = base_remediation.replace('[reason_for_fail]', reason_for_fail)

            append_data = [cis_no, name, description, status, current_setting, remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)


#     # 2.2 Password Policy

    #2.2.1 Ensure 'Password Policy' is enabled (Automated) 
    @staticmethod
    def password_policy(input_file, metadata_file,output_csv_location):
        cis_no = '2.2.1'
        name, description, remediation_template = FortiGate.get_metadata_from_csv(metadata_file, cis_no)

        status = 'FAIL'
        current_setting = ''
        reason_for_fail = ''
        remediation = ''

        # Step 1: Check local password policy
        datas = FortiGate.extract_policy(input_file, 'config system password-policy', match_exact=True)
        if datas:
            for data in datas:
                patterns = {
                    'status': r'set status (\S+)',
                    'apply-to': r'set apply-to ([^\n]+)',
                    'minimum-length': r'set minimum-length (\d+)',
                    'min-lower-case-letter': r'set min-lower-case-letter (\d+)',
                    'min-upper-case-letter': r'set min-upper-case-letter (\d+)',
                    'min-non-alphanumeric': r'set min-non-alphanumeric (\d+)',
                    'min-number': r'set min-number (\d+)',
                    'expire-status': r'set expire-status (\S+)',
                    'expire-day': r'set expire-day (\d+)',
                    'reuse-password': r'set reuse-password (\S+)'
                }

                extracted = {k: re.search(p, data) for k, p in patterns.items()}
                current_setting = '\n'.join(f"{k}: {v.group(1)}" for k, v in extracted.items() if v)
                missing = [k for k, v in extracted.items() if not v]

                if missing:
                    reason_for_fail = f"Missing fields: {', '.join(missing)}"
                elif all(extracted.values()):
                    values = {k: v.group(1).strip().lower() for k, v in extracted.items()}
                    # Validate all rules
                    failed_checks = []
                    if values['status'] != 'enable':
                        failed_checks.append("status not enabled")
                    if 'admin-password' not in values['apply-to']:
                        failed_checks.append("apply-to missing 'admin-password'")
                    if int(values['minimum-length']) < 8:
                        failed_checks.append("minimum length < 8")
                    if int(values['min-lower-case-letter']) < 1:
                        failed_checks.append("missing lower-case requirement")
                    if int(values['min-upper-case-letter']) < 1:
                        failed_checks.append("missing upper-case requirement")
                    if int(values['min-non-alphanumeric']) < 1:
                        failed_checks.append("missing special character requirement")
                    if int(values['min-number']) < 1:
                        failed_checks.append("missing numeric requirement")
                    if values['expire-status'] != 'enable':
                        failed_checks.append("expire-status not enabled")
                    if int(values['expire-day']) < 90:
                        failed_checks.append("expire-day < 90")
                    if values['reuse-password'] != 'disable':
                        failed_checks.append("reuse-password not disabled")

                    if not failed_checks:
                        status = 'PASS'
                    else:
                        reason_for_fail = '; '.join(failed_checks)
                else:
                    reason_for_fail = 'Could not extract all required fields'

                if status == 'FAIL':
                    remediation = remediation_template.replace('[reason_for_fail]', reason_for_fail)

                append_data = [cis_no, name, description, status, current_setting, remediation]
                append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)
                return

        # Step 2: Fallback to check TACACS (if password-policy block missing or invalid)
        datas = FortiGate.extract_policy(input_file, 'config user tacacs')
        if datas:
            for data in datas:
                head_match = re.search(r'\s*edit (.+)', data)
                server_matches = re.findall(r'set\s+(server[^\s]*)\s+(.*)', data)
                server_configured = len(server_matches) > 0

                current_setting = f"Auth method: TACACS - {head_match.group(1) if head_match else ''}\n"
                if server_configured:
                    current_setting += '\n'.join(f"{k}: {v}" for k, v in server_matches)
                    current_setting += '\nPassword policy is derived from TACACS/AD'
                    status = 'PASS'
                    remediation = ''
                else:
                    current_setting += 'TACACS configured but no servers defined'
                    reason_for_fail = 'TACACS block found but no servers configured'
                    remediation = remediation_template.replace('[reason_for_fail]', reason_for_fail)

                append_data = [cis_no, name, description, status, current_setting, remediation]
                append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)
                return

        # Step 3: Nothing found
        status = 'FAIL'
        current_setting = 'No local password-policy or external auth config found'
        reason_for_fail = 'No password-policy or fallback authentication configured'
        remediation = remediation_template.replace('[reason_for_fail]', reason_for_fail)

        append_data = [cis_no, name, description, status, current_setting, remediation]
        append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)

    # 2.2.2 Ensure administrator password retries and lockout time are configured
    @staticmethod
    def admin_passwd_logout_time(input_file, metadata_file,output_csv_location):
        cis_no = '2.2.2'
        name, description, remediation_template = FortiGate.get_metadata_from_csv(metadata_file, cis_no)
        
        status = 'FAIL'
        remediation = ''
        current_setting = ''

        # Extract system global config block
        datas = FortiGate.extract_policy(input_file, 'config system global', match_exact=True)

        if datas:
            for data in datas:
                values = FortiGate.get_data_from_set_list(data)

                threshold = FortiGate.split_values(values, 'admin-lockout-threshold')
                duration = FortiGate.split_values(values, 'admin-lockout-duration')

                current_setting = (
                    f"admin-lockout-threshold: {threshold or 'Not Found'}\n"
                    f"admin-lockout-duration: {duration or 'Not Found'}"
                )

                # Track specific failure reasons
                reasons = []
                if not threshold or not threshold.isdigit():
                    reasons.append("admin-lockout-threshold is missing or invalid")
                elif int(threshold) != 3:
                    reasons.append("admin-lockout-threshold is not set to 3")

                if not duration or not duration.isdigit():
                    reasons.append("admin-lockout-duration is missing or invalid")
                elif int(duration) != 900:
                    reasons.append("admin-lockout-duration is not set to 900")

                if not reasons:
                    status = 'PASS'
                    remediation = ''
                else:
                    reason_for_fail = "; ".join(reasons)
                    remediation = remediation_template.replace('[reason_for_fail]', reason_for_fail)

                append_data = [cis_no, name, description, status, current_setting, remediation]
                append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)
                break  # Only one block expected
        else:
            status = 'FAIL'
            current_setting = 'config system global block not found'
            remediation = remediation_template.replace('[reason_for_fail]', 'Configuration block is missing')
            append_data = [cis_no, name, description, status, current_setting, remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)


    # 2.3 SNMP

    # 2.3.1 Ensure only SNMPv3 is enabled (Automated)
    @staticmethod
    def only_snmp_ver_three_is_enabled(input_file, metadata_file,output_csv_location):
        cis_no = '2.3.1'
        name, description, remediation_template = FortiGate.get_metadata_from_csv(metadata_file, cis_no)

        status = 'FAIL'
        current_setting = ''
        remediation_reason = ''

        snmp_info = FortiGate.extract_policy(input_file, 'config system snmp sysinfo', match_exact=True)
        snmp_community = FortiGate.extract_policy(input_file, 'config system snmp community', match_exact=True)
        snmp_users = FortiGate.extract_policy(input_file, 'config system snmp user', match_exact=True)

        if snmp_info:
            for data in snmp_info:
                get_datas = FortiGate.get_data_from_set_list(data)
                snmp_status = FortiGate.split_values(get_datas, 'status')

                current_setting += f"SNMP Agent Status: {snmp_status or 'Not Found'}\n"

                if snmp_status.lower() == 'disable':
                    status = 'PASS'
                    current_setting += "SNMP is disabled\n"
                    remediation = ''
                else:
                    if snmp_community:
                        current_setting += "SNMPv1/v2c Community: Found\n"
                        remediation_reason = "SNMPv1/v2c community is configured."
                        status = 'FAIL'
                    else:
                        current_setting += "SNMPv1/v2c Community: Not Found\n"

                        if snmp_users:
                            users = []
                            for d in snmp_users:
                                user_pattern = re.findall(r'\s*edit\s+"?(.*?)"?\s*$', d, re.MULTILINE)
                                if user_pattern:
                                    users.extend(user_pattern)

                            if users:
                                for i, u in enumerate(users, start=1):
                                    current_setting += f"SNMPv3 User {i}: {u}\n"
                                status = 'PASS'
                                remediation = ''
                            else:
                                current_setting += "SNMPv3 Users: Not Found\n"
                                remediation_reason = "SNMPv3 users are missing."
                                status = 'FAIL'
                        else:
                            current_setting += "SNMPv3 Users: Not Found\n"
                            remediation_reason = "No SNMPv3 user configured."
                            status = 'FAIL'

                # Generate final remediation content with reason
                if status == 'FAIL':
                    remediation = f"[Reason]: {remediation_reason or 'Misconfiguration of SNMP settings'}\n\n" + remediation_template

                try:
                    append_data = [cis_no, name, description, status, current_setting.strip(), remediation]
                    append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)
                except Exception as e:
                    print(f"❌ Failed to write to CSV for {cis_no}: {e}")
                break  # One block is sufficient
        else:
            # If config block is not found, assume SNMP is disabled
            status = 'PASS'
            current_setting = 'SNMP Agent Block Not Found (Assumed Disabled)'
            remediation = ''

            try:
                append_data = [cis_no, name, description, status, current_setting, remediation]
                print(f"Appending row (fallback): {append_data}")
                append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)
            except Exception as e:
                print(f"❌ Failed to write to CSV for {cis_no} (fallback): {e}")



#    # 2.4 Administrators and Admin Profiles


    # 2.4.4 Ensure idle timeout time is configured
    @staticmethod
    def idle_timeout(input_file, metadata_file,output_csv_location):
        cis_no = '2.4.4'
        name, description, remediation_template = FortiGate.get_metadata_from_csv(metadata_file, cis_no)
        status = 'FAIL'
        current_setting = ''
        remediation = ''

        datas = FortiGate.extract_policy(input_file, 'config system global')
        if datas:
            for data in datas:
                get_datas = FortiGate.get_data_from_set_list(data)
                timeout = FortiGate.split_values(get_datas, 'admintimeout') if 'admintimeout' in get_datas else ''

                if timeout and timeout.isdigit():
                    current_setting = f"admintimeout: {timeout}"
                    if timeout and timeout.isdigit():
                        current_setting = f"admintimeout: {timeout}"
                        status = 'PASS'
                        remediation = ''
                    else:
                        status = 'FAIL'
                        current_setting = 'admintimeout: Not Found'
                        reason = "Idle timeout is not configured or has invalid value"
                        remediation = remediation_template.replace("[reason_for_fail]", reason)
                else:
                    status = 'FAIL'
                    current_setting = 'admintimeout: Not Found'
                    reason = "Idle timeout is not configured or has invalid value"
                    remediation = remediation_template.replace("[reason_for_fail]", reason)

                append_data = [cis_no, name, description, status, current_setting, remediation]
                append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)
        else:
            status = 'FAIL'
            current_setting = 'Block Not Found'
            reason = "config system global block is missing"
            remediation = remediation_template.replace("[reason_for_fail]", reason)
            append_data = [cis_no, name, description, status, current_setting, remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)

    # 2.4.5 Ensure only encrypted access channels are enabled
    @staticmethod
    def only_encrypted_channel(input_file, metadata_file,output_csv_location):
        cis_no = '2.4.5'
        name, description, remediation_template = FortiGate.get_metadata_from_csv(metadata_file, cis_no)

        status = 'PASS'
        current_setting = ''
        remediation = ''
        failure_reasons = []

        datas = FortiGate.extract_policy(input_file, 'config system interface')
        if datas:
            all_blocks_output = []
            non_compliant_found = False
            found_edit = False

            for data in datas:
                # Extract all interface edit block names
                interfaces = re.findall(r'\s*edit\s+"([^"]+)"', data)

                for interface in interfaces:
                    found_edit = True
                    edit_block = FortiGate.get_edit_block_data(data, interface)
                    set_data = FortiGate.get_data_from_set_list(edit_block)

                    allowaccess_raw = FortiGate.split_values(set_data, 'allowaccess') or ''
                    allowaccess = allowaccess_raw.split()
                    status_value = FortiGate.split_values(set_data, 'status') or 'up'

                    if status_value.lower() == 'down':
                        continue  # Skip inactive interfaces

                    bad_protocols = [proto for proto in ['http', 'telnet'] if proto in allowaccess]
                    is_non_compliant = bool(bad_protocols)

                    block_summary = (
                        f"Interface: {interface}\n"
                        f"Status: {status_value}\n"
                        f"AllowAccess: {', '.join(allowaccess) if allowaccess else 'Not Found'}\n"
                        f"{'=> Non-compliant (uses: ' + ', '.join(bad_protocols) + ')' if is_non_compliant else '=> Compliant'}"
                    )

                    all_blocks_output.append(block_summary)

                    if is_non_compliant:
                        non_compliant_found = True
                        failure_reasons.append(f"{interface} allows: {', '.join(bad_protocols)}")

            if not found_edit:
                status = 'FAIL'
                current_setting = 'No interface edit blocks found'
                remediation = remediation_template.replace('[reason_for_fail]', 'No editable interfaces found.')
            else:
                status = 'FAIL' if non_compliant_found else 'PASS'
                current_setting = "\n\n".join(all_blocks_output)

                if non_compliant_found:
                    reason_text = "; ".join(failure_reasons)
                    remediation = remediation_template.replace('[reason_for_fail]', reason_text)
                else:
                    remediation = ''

            append_data = [cis_no, name, description, status, current_setting.strip(), remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)

        else:
            status = 'FAIL'
            current_setting = 'config system interface block not found'
            remediation = remediation_template.replace('[reason_for_fail]', 'Interface configuration block missing.')
            append_data = [cis_no, name, description, status, current_setting, remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)



#     # 2.5 High Availability

#     #2.5.1 Ensure High Availability configuration is enabled 
    @staticmethod
    def high_availability(input_file, metadata_file,output_csv_location):
        cis_no = '2.5.1'
        name, description, remediation_template = FortiGate.get_metadata_from_csv(metadata_file, cis_no)
        status = 'FAIL'
        current_setting = ''
        remediation = ''

        datas = FortiGate.extract_policy(input_file, 'config system ha', match_exact=True)
        if datas:
            for data in datas:
                get_datas = FortiGate.get_data_from_set_list(data)
                unset_keys = FortiGate.get_unset_keys(data)
                fail_reasons = []

                if not get_datas and not unset_keys:
                    current_setting = 'Not Configured'
                    remediation = remediation_template.replace('[reason_for_fail]', 'HA block present but empty.')
                    append_data = [cis_no, name, description, status, current_setting, remediation]
                    append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)
                    return

                # Extract values or defaults
                mode = '' if 'mode' in unset_keys else get_datas.get('mode', ('',))[0].lower()
                group_name = '' if 'group-name' in unset_keys else get_datas.get('group-name', ('',))[0]
                password_value = '' if 'password' in unset_keys else get_datas.get('password', ('',))[0]
                hbdev = () if 'hbdev' in unset_keys else get_datas.get('hbdev', ())

                hbdev_value = ' '.join(hbdev) if hbdev else 'NOT SET'
                password_set = 'Yes' if password_value.strip().lower().startswith('enc') else 'No'

                # Build readable config
                current_setting = (
                    f"mode: {mode or 'Not Set'}, group-name: {group_name or 'Not Set'}, "
                    f"hbdev: {hbdev_value}, password_set: {password_set}"
                )

                # Compliance Checks
                if mode not in ['a-p', 'a-a']:
                    fail_reasons.append(f"HA mode is '{mode}' (should be a-p or a-a)")

                if not group_name.strip():
                    fail_reasons.append("group-name not set")

                if password_set != 'Yes':
                    fail_reasons.append("password not set or not encrypted")

                if not hbdev:
                    fail_reasons.append("heartbeat interface (hbdev) not configured")

                # Final decision
                if not fail_reasons:
                    status = 'PASS'
                    remediation = ''
                else:
                    reason_text = '; '.join(fail_reasons)
                    remediation = remediation_template.replace('[reason_for_fail]', reason_text)

                append_data = [cis_no, name, description, status, current_setting.strip(), remediation]
                append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)
        else:
            status = 'FAIL'
            current_setting = 'config system ha block not found'
            remediation = remediation_template.replace('[reason_for_fail]', 'No HA configuration block present')
            append_data = [cis_no, name, description, status, current_setting, remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)


    #2.5.2 Ensure "Monitor Interfaces" for High Availability devices is enabled 
    @staticmethod
    def monitor_interfaces(input_file, metadata_file,output_csv_location):
        cis_no = '2.5.2'
        name, description, remediation_template = FortiGate.get_metadata_from_csv(metadata_file, cis_no)
        status = 'FAIL'
        current_setting = ''
        remediation_reason = ''
        remediation = ''

        datas = FortiGate.extract_policy(input_file, 'config system ha', match_exact=True)

        if datas:
            for data in datas:
                get_datas = FortiGate.get_data_from_set_list(data)
                unset_keys = FortiGate.get_unset_keys(data)

                if not get_datas and not unset_keys:
                    current_setting = 'Not Configured'
                    remediation_reason = 'High Availability (config system ha) block is present but empty.'
                    break

                # Extract monitor interfaces
                monitor = [] if 'monitor' in unset_keys else list(get_datas.get('monitor', ()))
                monitor_value = ' '.join(monitor) if monitor else 'NOT SET'
                current_setting = f"monitor_interfaces: {monitor_value}"

                if monitor:
                    status = 'PASS'
                    remediation_reason = ''
                    remediation = ''
                else:
                    status = 'FAIL'
                    remediation_reason = 'No monitor interfaces are defined in the HA configuration.'

                break  # process only one HA block

            if status == 'FAIL':
                remediation = remediation_template.replace('[reason_for_fail]', remediation_reason)

            append_data = [cis_no, name, description, status, current_setting.strip(), remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)

        else:
            status = 'FAIL'
            current_setting = 'config system ha block not found'
            remediation_reason = 'High Availability block is missing; monitor interfaces cannot be verified.'
            remediation = remediation_template.replace('[reason_for_fail]', remediation_reason)

            append_data = [cis_no, name, description, status, current_setting, remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)


    #3.2 Ensure that policies do not use "ALL" as Service
    @staticmethod
    def no_all_service_in_policy(input_file, metadata_file,output_csv_location):
        cis_no = '3.2'
        name, description, remediation_template = FortiGate.get_metadata_from_csv(metadata_file, cis_no)

        status = 'PASS'
        current_setting = ''
        remediation = ''
        fail_policies = []

        # Extract all firewall policies
        policy_blocks = FortiGate.extract_policy(input_file, 'config firewall policy', match_exact=True)

        if policy_blocks:
            for block in policy_blocks:
                # Split into individual policies by "edit"
                individual_policies = re.split(r'\n\s*edit\s+', block)
                for policy_raw in individual_policies:
                    if not policy_raw.strip():
                        continue

                    # Reconstruct the edit line
                    policy = "edit " + policy_raw.strip()

                    # Extract policy ID (after 'edit <id>')
                    match = re.search(r'edit\s+(\d+)', policy)
                    policy_id = match.group(1) if match else 'Unknown'

                    # Search for the service line
                    service_line_match = re.search(r'set service (.+)', policy)
                    if service_line_match:
                        services_raw = service_line_match.group(1)
                        services = re.findall(r'"([^"]+)"', services_raw)

                        if any(s.lower() == 'all' for s in services):
                            fail_policies.append(f"Policy ID {policy_id} uses service: ALL")

            if fail_policies:
                status = 'FAIL'
                current_setting = '\n'.join(fail_policies)
                reason = 'One or more firewall policies use "ALL" as service'
                remediation = remediation_template.replace('[reason_for_fail]', reason)
            else:
                current_setting = 'No firewall policy uses service "ALL"'
        else:
            status = 'FAIL'
            current_setting = 'No firewall policies found'
            reason = 'Firewall policy block missing or not matched'
            remediation = remediation_template.replace('[reason_for_fail]', reason)

        append_data = [cis_no, name, description, status, current_setting.strip(), remediation]
        append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)



    #4.2.1 Ensure Antivirus Definition Push Updates are Configured
    @staticmethod
    def antivirus_push_updates(input_file, metadata_file,output_csv_location):
        cis_no = '4.2.1'
        name, description, remediation_template = FortiGate.get_metadata_from_csv(metadata_file, cis_no)
        status = 'FAIL'
        current_setting = ''
        remediation = ''
        remediation_reason = ''

        datas = FortiGate.extract_policy(input_file, 'config system autoupdate schedule', match_exact=True)

        if datas:
            for data in datas:
                get_datas = FortiGate.get_data_from_set_list(data)

                if not get_datas:
                    current_setting = 'Not Configured'
                    remediation_reason = 'Auto-update schedule block is present but contains no parameters.'
                    break

                # Safely extract values from tuples
                raw_status = get_datas.get('status', ('',))
                raw_frequency = get_datas.get('frequency', ('',))

                update_status = raw_status[0].lower() if raw_status else ''
                frequency = raw_frequency[0].lower() if raw_frequency else ''

                current_setting = f"status: {update_status or 'Not Found'}, frequency: {frequency or 'Not Found'}"

                if update_status == 'enable' and frequency == 'automatic':
                    status = 'PASS'
                    remediation = ''  # Explicitly empty
                else:
                    remediation_reason = 'Status is not enabled or frequency is not set to automatic.'
                    status = 'FAIL'

                break  # Only one autoupdate config block expected

            if status == 'FAIL':
                remediation = remediation_template.replace('[reason_for_fail]', remediation_reason)

            append_data = [cis_no, name, description, status, current_setting, remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)

        else:
            status = 'FAIL'
            current_setting = 'config system autoupdate schedule block not found'
            remediation_reason = 'No auto-update configuration block found in the configuration.'
            remediation = remediation_template.replace('[reason_for_fail]', remediation_reason)

            append_data = [cis_no, name, description, status, current_setting, remediation]
            append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)


    

#     #4.2.3 Enable Outbreak Prevention Database 
    @staticmethod
    def outbreak_prevention_enabled(input_file, metadata_file,output_csv_location):
        cis_no = '4.2.3'
        name, description, remediation_template = FortiGate.get_metadata_from_csv(metadata_file, cis_no)

        status = 'PASS'
        current_setting = ''
        remediation_reason = ''
        profiles_missing_setting = []

        datas = FortiGate.extract_policy(input_file, 'config antivirus profile')

        if datas:
            for data in datas:
                profile_names = FortiGate.get_all_edit_names(data)
                for profile_name in profile_names:
                    profile_block = FortiGate.get_edit_block_data(data, profile_name)
                    profile_data = FortiGate.get_data_from_set_list(profile_block)
                    outbreak_setting = profile_data.get('outbreak-prevention', ('',))[0].lower()

                    current_setting += f"\nProfile: {profile_name} => outbreak-prevention: {outbreak_setting or 'Not Found'}"

                    if outbreak_setting != 'block':
                        profiles_missing_setting.append(profile_name)
                        status = 'FAIL'

            if profiles_missing_setting:
                remediation_reason = f"Outbreak prevention not properly configured in profiles: {', '.join(profiles_missing_setting)}"
                remediation = remediation_template.replace('[reason_for_fail]', remediation_reason)
            else:
                remediation = ''

        else:
            status = 'FAIL'
            current_setting = 'config antivirus profile block not found'
            remediation_reason = 'No antivirus profiles defined.'
            remediation = remediation_template.replace('[reason_for_fail]', remediation_reason)

        append_data = [cis_no, name, description, status, current_setting.strip(), remediation]
        append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)


    #4.2.4 Enable AI /heuristic based malware detection
    @staticmethod
    def antivirus_ai_detection(input_file, metadata_file,output_csv_location):
        cis_no = '4.2.4'
        name, description, remediation_template = FortiGate.get_metadata_from_csv(metadata_file, cis_no)
        status = 'FAIL'
        current_setting = ''
        remediation_reason = ''
        remediation = ''

        # Extract antivirus settings block
        datas = FortiGate.extract_policy(input_file, 'config antivirus settings', match_exact=True)

        if datas:
            for data in datas:
                get_datas = FortiGate.get_data_from_set_list(data)
                unset_keys = FortiGate.get_unset_keys(data)

                if not get_datas and not unset_keys:
                    current_setting = 'Not Configured'
                    remediation_reason = 'Antivirus settings block is present but contains no configuration.'
                    break

                if 'machine-learning-detection' in unset_keys:
                    current_setting = 'machine-learning-detection: UNSET'
                    remediation_reason = 'machine-learning-detection is not configured.'
                    break

                ml_detect = get_datas.get('machine-learning-detection', ('',))[0].lower()
                current_setting = f"machine-learning-detection: {ml_detect}"

                if ml_detect == 'enable':
                    status = 'PASS'
                    remediation = ''
                else:
                    status = 'FAIL'
                    remediation_reason = 'machine-learning-detection is set to a value other than "enable".'

                break  # Only evaluate one antivirus settings block

            if status == 'FAIL':
                remediation = remediation_template.replace('[reason_for_fail]', remediation_reason)

        else:
            status = 'FAIL'
            current_setting = 'config antivirus settings block not found'
            remediation_reason = 'No antivirus settings block found in configuration.'
            remediation = remediation_template.replace('[reason_for_fail]', remediation_reason)

        append_data = [cis_no, name, description, status, current_setting.strip(), remediation]
        append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)


    #4.2.5 Enable grayware detection on antivirus
    @staticmethod
    def antivirus_grayware_detection(input_file, metadata_file,output_csv_location):
        cis_no = '4.2.5'
        name, description, remediation_template = FortiGate.get_metadata_from_csv(metadata_file, cis_no)
        status = 'FAIL'
        current_setting = ''
        remediation_reason = ''
        remediation = ''

        # Extract block from antivirus settings
        datas = FortiGate.extract_policy(input_file, 'config antivirus settings', match_exact=True)

        if datas:
            for data in datas:
                get_datas = FortiGate.get_data_from_set_list(data)
                unset_keys = FortiGate.get_unset_keys(data)

                if not get_datas and not unset_keys:
                    current_setting = 'Not Configured'
                    remediation_reason = 'Antivirus settings block is empty or missing required keys.'
                    break

                if 'grayware' in unset_keys:
                    current_setting = 'grayware: UNSET'
                    remediation_reason = 'grayware is not explicitly configured.'
                    break

                grayware_val = get_datas.get('grayware', ('',))[0].lower()
                current_setting = f"grayware: {grayware_val}"

                if grayware_val == 'enable':
                    status = 'PASS'
                    remediation = ''
                else:
                    status = 'FAIL'
                    remediation_reason = 'grayware is not set to "enable".'

                break  # Only evaluate one block

            if status == 'FAIL':
                remediation = remediation_template.replace('[reason_for_fail]', remediation_reason)

        else:
            status = 'FAIL'
            current_setting = 'config antivirus settings block not found'
            remediation_reason = 'No antivirus settings block found in configuration.'
            remediation = remediation_template.replace('[reason_for_fail]', remediation_reason)

        append_data = [cis_no, name, description, status, current_setting.strip(), remediation]
        append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)


#     #4.4.2 Block applications running on non-default ports
    @staticmethod
    def application_block_non_default_ports(input_file, metadata_file,output_csv_location):
        cis_no = '4.4.2'
        name, description, remediation_template = FortiGate.get_metadata_from_csv(metadata_file, cis_no)
        status = 'FAIL'
        current_setting = ''
        remediation_reason = ''
        remediation = ''

        # Extract 'config application list' block
        datas = FortiGate.extract_policy(input_file, 'config application list', match_exact=True)

        if datas:
            block_data = datas[0]
            profile_blocks = re.findall(r'edit\s+"[^"]+".*?next', block_data, re.DOTALL)

            results = []
            all_profiles_compliant = True

            for profile_block in profile_blocks:
                profile_name_match = re.search(r'edit\s+"([^"]+)"', profile_block)
                if not profile_name_match:
                    continue
                profile_name = profile_name_match.group(1)

                if 'set enforce-default-app-port enable' in profile_block:
                    results.append(f"{profile_name}: ENABLED")
                else:
                    results.append(f"{profile_name}: DISABLED")
                    all_profiles_compliant = False

            current_setting = ', '.join(results)
            if all_profiles_compliant:
                status = 'PASS'
                remediation = ''
            else:
                remediation_reason = 'One or more Application Control profiles do not have enforce-default-app-port enabled.'
                remediation = remediation_template.replace('[reason_for_fail]', remediation_reason)

        else:
            current_setting = 'config application list block not found'
            remediation_reason = 'No Application Control configuration block was found.'
            remediation = remediation_template.replace('[reason_for_fail]', remediation_reason)

        append_data = [cis_no, name, description, status, current_setting.strip(), remediation]
        append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)




     #7.1.1  Enable Event Logging 
    
    #7.1.1 Enable Event Logging 
    @staticmethod
    def event_logging_enabled(input_file, metadata_file,output_csv_location):
        cis_no = '7.1.1'
        name, description, remediation_template = FortiGate.get_metadata_from_csv(metadata_file, cis_no)
        status = 'FAIL'
        current_setting = ''
        remediation_reason = ''

        # Extract `config log eventfilter` block
        datas = FortiGate.extract_policy(input_file, 'config log eventfilter', match_exact=True)

        if datas:
            for data in datas:
                get_datas = FortiGate.get_data_from_set_list(data)
                unset_keys = FortiGate.get_unset_keys(data)

                # If block is empty
                if not get_datas and not unset_keys:
                    current_setting = 'Not Configured'
                    remediation_reason = 'Event logging block exists but contains no settings.'
                    break

                # Check if 'event' is explicitly set
                if 'event' in unset_keys:
                    current_setting = 'event:UNSET'
                    remediation_reason = '"event" is not set in log eventfilter.'
                else:
                    event_value = get_datas.get('event', ('',))[0].lower()
                    current_setting = f'event:{event_value}'

                    if event_value == 'enable':
                        status = 'PASS'
                        remediation_reason = ''

                    else:
                        remediation_reason = '"event" is not set to "enable".'

                break  # Only one block expected
        else:
            current_setting = 'log eventfilter block not found'
            remediation_reason = 'log eventfilter configuration block is missing.'

        remediation = '' if status == 'PASS' else remediation_template.replace('[reason_for_fail]', remediation_reason)

        append_data = [cis_no, name, description, status, current_setting, remediation]
        append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)


    #7.2.1 Encrypt Log Transmission to FortiAnalyzer / FortiManager 
    @staticmethod
    def encrypt_log_transmission_to_fortianalyzer(input_file, metadata_file,output_csv_location):
        cis_no = '7.2.1'
        name, description, remediation_template = FortiGate.get_metadata_from_csv(metadata_file, cis_no)
        status = 'FAIL'
        current_setting = ''
        remediation_reason = ''

        datas = FortiGate.extract_policy(input_file, 'config log fortianalyzer setting', match_exact=True)

        if datas:
            for data in datas:
                get_datas = FortiGate.get_data_from_set_list(data)
                unset_keys = FortiGate.get_unset_keys(data)

                if not get_datas and not unset_keys:
                    current_setting = 'Not Configured'
                    remediation_reason = 'Log FortiAnalyzer setting block exists but has no parameters.'
                    break

                # Check 'enc-algorithm' and 'reliable'
                enc_algorithm = get_datas.get('enc-algorithm', ('',))[0].lower()
                reliable = get_datas.get('reliable', ('',))[0].lower()

                current_setting = f"enc-algorithm: {enc_algorithm or 'UNSET'}, reliable: {reliable or 'UNSET'}"

                if enc_algorithm == 'high' and reliable == 'enable':
                    status = 'PASS'
                    remediation_reason = ''
                else:
                    missing = []
                    if enc_algorithm != 'high':
                        missing.append("enc-algorithm not set to 'high'")
                    if reliable != 'enable':
                        missing.append("reliable not set to 'enable'")
                    remediation_reason = '; '.join(missing)
                break
        else:
            current_setting = 'config log fortianalyzer setting block not found'
            remediation_reason = 'Log FortiAnalyzer setting block not configured.'

        # Only show remediation if status is FAIL
        remediation = '' if status == 'PASS' else remediation_template.replace('[reason_for_fail]', remediation_reason)

        append_data = [cis_no, name, description, status, current_setting, remediation]
        append_data_to_csvfile(output_csv_location, FortiGate.fortigate_heading, append_data)


