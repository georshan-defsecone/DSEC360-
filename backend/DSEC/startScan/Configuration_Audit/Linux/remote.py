from fabric import Connection, Config
import os

def execute_remote(script_name, username, password, ip, port, result_name="results.json"):
    """
    Uploads and executes a local Bash audit script on a remote host using sudo,
    then downloads the resulting JSON output back to the local system.
    """

    remote_script_path=f"/tmp/{script_name}"
    remote_result_path=f"/tmp/{result_name}"
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    local_result_path=os.path.join(BASE_DIR, result_name)

    config = Config(overrides={"sudo":{"password":password}})
    conn = Connection(
        host=ip,
        user=username,
        port=port,
        connect_kwargs={
            "password":password,
            "allow_agent": False,
            "look_for_keys": False
            },
        config=config
    )

    print(f"Uploading script: {script_name} → {remote_script_path}")
    conn.put(script_name, remote=remote_script_path)
    conn.run(f"chmod +x {remote_script_path}")

    print("Running script remotely with sudo...")
    result = conn.sudo(remote_script_path, pty=True)

    print("stdout:\n", result.stdout)
    print("stderr:\n", result.stderr)

    print("Downloading result JSON from remote...")
    conn.get(remote_result_path, local=local_result_path)
    print(f"Result saved to: {local_result_path}")

    print("Cleaning up remote files...")
    conn.sudo(f"rm -f {remote_script_path} {remote_result_path}", pty=True)

    conn.close()
