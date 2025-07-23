import csv
import re

class FortiGateACLReporter:
    @staticmethod
    def normalize(value):
        return value.lower() if value else ''

    @staticmethod
    def split_values(data, key):
        return ', '.join(value for value in data[key]) if key in data else None

    @staticmethod
    def determine_impact(source, destination, service, action, status):
        source = FortiGateACLReporter.normalize(source)
        destination = FortiGateACLReporter.normalize(destination)
        service = FortiGateACLReporter.normalize(service)
        action = FortiGateACLReporter.normalize(action)
        status = FortiGateACLReporter.normalize(status)

        if action == 'accept' and status != 'disable':
            if source == 'all' and destination == 'all' and service == 'all':
                return 'High'
            elif source == 'all' and destination == 'all' and service != 'all':
                return 'Medium'
            elif source != 'all' and destination == 'all' and service == 'all':
                return 'Medium'
            elif source == 'all' and destination != 'all' and service == 'all':
                return 'Medium'
            elif source != 'all' and destination != 'all' and service == 'all':
                return 'Low'
            elif source == 'all' and destination != 'all' and service != 'all':
                return 'Low'
        return 'None'

    @staticmethod
    def extract_policy(file_path, policy_name):
        policies = []
        current_policy = []
        inside_policy = False

        with open(file_path, 'r') as file:
            for line in file:
                if re.match(rf'^{policy_name}', line):
                    if inside_policy:
                        policies.append(''.join(current_policy))
                        current_policy = []
                    inside_policy = True

                if inside_policy:
                    current_policy.append(line)

                if re.match(r'^end$', line) and inside_policy:
                    current_policy.append(line)
                    policies.append(''.join(current_policy))
                    current_policy = []
                    inside_policy = False

        if inside_policy:
            policies.append(''.join(current_policy))

        return policies

    @staticmethod
    def get_data_from_set(data):
        patterns = re.findall(r'\s*set\s+(\S+)\s+(.*)', data)
        return patterns

    @staticmethod
    def get_data_from_set_2(data):
        key_value_pairs = {}
        patterns = re.findall(r'\s*set\s+(\S+)\s+(.*)', data)
        for key, value in patterns:
            value_parts = re.findall(r'\'[^\']*\'|\"[^\"]*\"|\S+', value)
            value_parts = [s.strip('"').strip("'") for s in value_parts]
            if key in key_value_pairs:
                if isinstance(key_value_pairs[key], tuple):
                    key_value_pairs[key] += tuple(value_parts)
                else:
                    key_value_pairs[key] = (key_value_pairs[key],) + tuple(value_parts)
            else:
                key_value_pairs[key] = tuple(value_parts)
        return key_value_pairs

    @staticmethod
    def generate_acl_csv(input_file, output_file):
        acl_heading = [
            'Edit Number', 'Name', 'Impact', 'Src Interface', 'Src Address', 'Dst Interface',
            'Dst Address', 'Status', 'Action', 'Service', 'Schedule', 'Log Traffic',
            'Log Traffic Start', 'Global Label'
        ]

        firewall_policies = FortiGateACLReporter.extract_policy(input_file, 'config firewall policy')
        with open(output_file, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(acl_heading)

            for config_block in firewall_policies:
                policy_blocks = re.findall(r'edit (\d+)(.*?)next', config_block, re.DOTALL)
                for edit_num, block in policy_blocks:
                    key_value_pairs = {}
                    for key, value in FortiGateACLReporter.get_data_from_set(block):
                        value_parts = value.split('" "')
                        value_parts = [s.strip('"') for s in value_parts]
                        key_value_pairs[key] = tuple(value_parts)

                    status = FortiGateACLReporter.split_values(key_value_pairs, 'status')
                    name = FortiGateACLReporter.split_values(key_value_pairs, 'name')
                    srcintf = FortiGateACLReporter.split_values(key_value_pairs, 'srcintf')
                    dstintf = FortiGateACLReporter.split_values(key_value_pairs, 'dstintf')
                    action = FortiGateACLReporter.split_values(key_value_pairs, 'action')
                    srcaddr = FortiGateACLReporter.split_values(key_value_pairs, 'srcaddr')
                    dstaddr = FortiGateACLReporter.split_values(key_value_pairs, 'dstaddr')
                    schedule = FortiGateACLReporter.split_values(key_value_pairs, 'schedule')
                    service = FortiGateACLReporter.split_values(key_value_pairs, 'service')
                    log_traffic = FortiGateACLReporter.split_values(key_value_pairs, 'logtraffic')
                    log_traffic_start = FortiGateACLReporter.split_values(key_value_pairs, 'logtraffic-start')
                    global_label = FortiGateACLReporter.split_values(key_value_pairs, 'global-label')
                    impact = FortiGateACLReporter.determine_impact(srcaddr, dstaddr, service, action, status)

                    row = [
                        edit_num, name, impact, srcintf, srcaddr, dstintf, dstaddr, status,
                        action, service, schedule, log_traffic, log_traffic_start, global_label
                    ]
                    writer.writerow(row)
