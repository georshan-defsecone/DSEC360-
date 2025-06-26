import os
import sys
import traceback
from impacket.smbconnection import SMBConnection
from impacket.examples import logger
from .wmiexec import WMIEXEC

def upload_file_smb(username, password, domain, target_ip, share_name, local_path, remote_path):
    try:
        smb = SMBConnection(target_ip, target_ip)
        smb.login(username, password, domain)
        with open(local_path, 'rb') as f:
            smb.putFile(share_name, remote_path, f.read)
        smb.logoff()
        print(f"[+] File uploaded to \\\\{target_ip}\\{share_name}\\{remote_path}")
    except Exception as e:
        print("[-] SMB Upload failed:", e)
        sys.exit(1)

def download_file_smb(username, password, domain, target_ip, share_name, remote_path, local_path):
    try:
        smb = SMBConnection(target_ip, target_ip)
        smb.login(username, password, domain)
        with open(local_path, 'wb') as f:
            smb.getFile(share_name, remote_path, f.write)
        smb.logoff()
        print(f"[+] File downloaded from \\\\{target_ip}\\{share_name}\\{remote_path} to {local_path}")
    except Exception as e:
        print("[-] SMB Download failed:", e)
        sys.exit(1)
        
def cleanup_remote_files(username, password, target_ip, *remote_file_paths):
	domain = ""
	for remote_file_path in remote_file_paths:
		print(f"[*] Deleting remote file: {remote_file_path}")
		try:
			run_wmi_command(username, password, domain, target_ip, f'del "{remote_file_path}"')
			print(f"[+] Remote file deleted: {remote_file_path}")
			
		except Exception as e:
			print(f"[!] Failed to delete remote file: {remote_file_path}, Error: {e}")

			

def run_wmi_command(username, password, domain, target_ip, command):
    try:
        executor = WMIEXEC(command=command, username=username, password=password,
                           domain=domain, remoteHost=target_ip, share='C$')
        executor.run(addr=target_ip)
    except Exception as e:
        print("[-] WMI execution failed:", e)
        traceback.print_exc()
        sys.exit(1)

def run_remote_audit(username, password, target_ip, local_script_path, local_output_path):
    domain = ""
    share_name = "C$"

    remote_script_path = f"\\Windows\\Temp\\{os.path.basename(local_script_path)}"
    remote_output_path = f"\\Windows\\Temp\\{os.path.basename(local_output_path)}"

    logger.init()

    print("[*] Uploading PowerShell script via SMB...")
    upload_file_smb(username, password, domain, target_ip, share_name, local_script_path, remote_script_path)

    print("[*] Running PowerShell script via WMI...")
    run_wmi_command(
        username,
        password,
        domain,
        target_ip,
        f'powershell.exe -ExecutionPolicy Bypass -File "C:\\Windows\\Temp\\{os.path.basename(local_script_path)}"'
    )

    print("[*] Downloading output file via SMB...")
    download_file_smb(username, password, domain, target_ip, share_name, remote_output_path, local_output_path)

    return local_output_path