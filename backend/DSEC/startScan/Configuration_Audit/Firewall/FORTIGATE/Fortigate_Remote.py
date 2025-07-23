import paramiko
import time
import socket

def connect_to_fortigate_and_backup(ssh_info, output_file="config.conf"):
    ip = ssh_info["ip"]
    port = ssh_info["port"]
    username = ssh_info["username"]
    password = ssh_info["password"]

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    print(f"🔌 Connecting to {ip}:{port}...")

    try:
        ssh.connect(hostname=ip, port=port, username=username, password=password, timeout=10)
        print(f"✅ Connected successfully to {ip}.")

        shell = ssh.invoke_shell()
        time.sleep(1)
        shell.recv(10000)  # Flush login banner

        # Disable pagination (to prevent --More-- prompts)
        shell.send("config system console\n")
        time.sleep(0.5)
        shell.send("set output standard\n")
        time.sleep(0.5)
        shell.send("end\n")
        time.sleep(0.5)

        # Send command to dump full config
        shell.send("show full-configuration\n")
        time.sleep(2)

        output = ""
        last_data_time = time.time()

        # Read until no more new data for 5 seconds
        while True:
            if shell.recv_ready():
                chunk = shell.recv(65535).decode("utf-8", errors="ignore")
                output += chunk
                last_data_time = time.time()
            else:
                if time.time() - last_data_time > 5:
                    break
                time.sleep(1)

        # Normalize output: remove carriage returns and multiple blank lines
        lines = output.replace('\r', '').split('\n')
        clean_lines = [line.rstrip() for line in lines if line.strip() != '']
        normalized_output = '\n'.join(clean_lines)

        with open(output_file, "w", encoding="utf-8") as file:
            file.write(normalized_output)
            print(f"✅ Cleaned config saved to {output_file} ({len(clean_lines)} lines)")

    except socket.timeout:
        print("❌ Connection timed out. Check IP/port/network.")
    except paramiko.AuthenticationException:
        print("❌ Authentication failed. Check username/password.")
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        ssh.close()
