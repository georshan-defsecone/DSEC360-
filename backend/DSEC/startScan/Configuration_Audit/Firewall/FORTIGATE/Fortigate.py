import os
from .Fortigate_Audit import FortiGate
from .Fortigate_ACL import FortiGateACLReporter
def fortigate_cis_audit(input_file, metadata_file,output_csv_for_audit):
    print("Entered fortigate cis function")
    FortiGate.remove_old_csv(output_csv_for_audit)
    FortiGate.check_system_dns(input_file, metadata_file,output_csv_for_audit)
    FortiGate.pre_login_banner(input_file,metadata_file,output_csv_for_audit)
    FortiGate.post_login_banner(input_file,metadata_file,output_csv_for_audit)
    FortiGate.sys_time(input_file,metadata_file,output_csv_for_audit)
    FortiGate.hostname(input_file,metadata_file,output_csv_for_audit)
    FortiGate.disable_usb_firmware(input_file,metadata_file,output_csv_for_audit)
    FortiGate.disable_static_key_4_tls(input_file,metadata_file,output_csv_for_audit)
    FortiGate.global_strong_encryption(input_file,metadata_file,output_csv_for_audit)
    FortiGate.password_policy(input_file, metadata_file,output_csv_for_audit)
    FortiGate.admin_passwd_logout_time(input_file, metadata_file,output_csv_for_audit)
    FortiGate.only_snmp_ver_three_is_enabled(input_file, metadata_file,output_csv_for_audit)
    FortiGate.idle_timeout(input_file, metadata_file,output_csv_for_audit)
    FortiGate.only_encrypted_channel(input_file, metadata_file,output_csv_for_audit)
    FortiGate.high_availability(input_file, metadata_file,output_csv_for_audit)
    FortiGate.monitor_interfaces(input_file,metadata_file,output_csv_for_audit)
    FortiGate.no_all_service_in_policy(input_file, metadata_file,output_csv_for_audit)
    FortiGate.antivirus_push_updates(input_file,metadata_file,output_csv_for_audit)
    FortiGate.outbreak_prevention_enabled(input_file, metadata_file,output_csv_for_audit)
    FortiGate.antivirus_ai_detection(input_file, metadata_file,output_csv_for_audit)
    FortiGate.antivirus_grayware_detection(input_file, metadata_file,output_csv_for_audit)
    FortiGate.application_block_non_default_ports(input_file, metadata_file,output_csv_for_audit)
    FortiGate.event_logging_enabled(input_file, metadata_file,output_csv_for_audit)
    FortiGate.encrypt_log_transmission_to_fortianalyzer(input_file, metadata_file,output_csv_for_audit)
def fortigate_acl_report(input_file,output_acl_csv):
    FortiGateACLReporter.generate_acl_csv(input_file,output_acl_csv)











   
   
    
    
    