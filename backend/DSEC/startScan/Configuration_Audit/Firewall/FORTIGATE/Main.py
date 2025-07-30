from Fortigate import fortigate_cis_audit
from Fortigate import fortigate_acl_report
import os
def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    input_config_file = os.path.join(base_dir, 'Client_Data.conf')
    metadata_file = os.path.join(base_dir, 'CIS/Fortigate_Metadata.csv')
    fortigate_cis_audit(input_config_file, metadata_file)
    fortigate_acl_report(input_config_file)
if __name__ == "__main__":
    main()
    