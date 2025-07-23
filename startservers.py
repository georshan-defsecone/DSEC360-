import subprocess
import os
import platform

def start_servers():
    """
    Starts the frontend and backend servers in separate terminal windows.
    """
    # This line is corrected to correctly locate the project directory
    # It assumes this script is in your main 'project' folder.
    project_dir = os.path.dirname(os.path.abspath(__file__))

    frontend_dir = os.path.join(project_dir, 'frontend')
    backend_dir = os.path.join(project_dir, 'backend')
    dsec_dir = os.path.join(backend_dir, 'DSEC')

    # --- Start Frontend ---
    frontend_command = f"cd {frontend_dir} && npm run dev"

    # --- Start Backend ---
    # Command to activate virtual environment and run the server
    if platform.system() == "Windows":
        # Note: Ensure your venv is named 'venv'
        backend_command = f'cd {dsec_dir} && ..\\env\\Scripts\\activate && python manage.py runserver'
    else: # macOS and Linux
        backend_command = f'cd {dsec_dir} && . ../env/bin/activate && python manage.py runserver'

    # --- Execute commands in new terminal windows ---
    print("Attempting to start servers...")
    print(f"Frontend path: {frontend_dir}")
    print(f"Backend command path: {dsec_dir}")

    if platform.system() == "Windows":
        subprocess.Popen(f'start cmd /k "{frontend_command}"', shell=True)
        subprocess.Popen(f'start cmd /k "{backend_command}"', shell=True)
    elif platform.system() == "Darwin":  # macOS
        subprocess.Popen(['osascript', '-e', f'tell app "Terminal" to do script "{frontend_command}"'])
        subprocess.Popen(['osascript', '-e', f'tell app "Terminal" to do script "{backend_command}"'])
    else:  # Linux
        subprocess.Popen(['gnome-terminal', '--', 'bash', '-c', f'{frontend_command}; exec bash'])
        subprocess.Popen(['gnome-terminal', '--', 'bash', '-c', f'{backend_command}; exec bash'])

    print("🚀 Server startup commands have been sent to new terminal windows.")

if __name__ == "__main__":
    start_servers()