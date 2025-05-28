#!/usr/bin/env python3
"""
Cross-platform project launcher for React + Django application
Automatically detects OS and sets up PostgreSQL, Django backend, and React frontend
"""

import os
import sys
import platform
import subprocess
import threading
import time
import shutil
from pathlib import Path

# Configuration
APP_NAME = "psql"
PG_USER = "dsec360"
PG_PASSWORD = "dsec360@123"
PG_DB = "dsec360"
VENV_DIR = "venv"

def get_os_type():
    """Detect the operating system"""
    system = platform.system().lower()
    if system == "windows":
        return "windows"
    elif system in ["linux", "darwin"]:
        return "unix"
    else:
        print(f"Unsupported operating system: {system}")
        sys.exit(1)

def run_command(command, shell=True, check=True, capture_output=False):
    """Execute a command with proper error handling"""
    try:
        if capture_output:
            result = subprocess.run(command, shell=shell, check=check, 
                                  capture_output=True, text=True)
            return result.stdout.strip()
        else:
            subprocess.run(command, shell=shell, check=check)
            return True
    except subprocess.CalledProcessError as e:
        print(f"Command failed: {command}")
        print(f"Error: {e}")
        return False

def check_command_exists(command):
    """Check if a command exists in the system PATH"""
    return shutil.which(command) is not None

def install_postgresql_windows():
    """Install PostgreSQL on Windows automatically"""
    import urllib.request
    import tempfile
    
    PG_VERSION = "16.3"
    POSTGRES_PASSWORD = "dsec360@123"
    
    major_version = PG_VERSION.split(".")[0]
    installer_url = f"https://get.enterprisedb.com/postgresql/postgresql-{PG_VERSION}-1-windows-x64.exe"
    
    print(f"Downloading PostgreSQL {PG_VERSION} installer...")
    
    # Download installer to temp directory
    with tempfile.NamedTemporaryFile(suffix='.exe', delete=False) as tmp_file:
        installer_path = tmp_file.name
    
    try:
        urllib.request.urlretrieve(installer_url, installer_path)
        print("Download complete. Installing PostgreSQL silently...")
        
        # Install PostgreSQL silently
        install_args = [
            installer_path,
            "--mode", "unattended",
            "--superpassword", POSTGRES_PASSWORD,
            f"--servicename", f"postgresql-{major_version}",
            "--serviceaccountpassword", POSTGRES_PASSWORD,
            "--prefix", f"C:\\Program Files\\PostgreSQL\\{major_version}"
        ]
        
        result = subprocess.run(install_args, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Installation failed: {result.stderr}")
            return False
        
        print("PostgreSQL installation complete.")
        
        # Add PostgreSQL to PATH
        pg_bin_path = f"C:\\Program Files\\PostgreSQL\\{major_version}\\bin"
        current_path = os.environ.get('PATH', '')
        if pg_bin_path not in current_path:
            os.environ['PATH'] = f"{current_path};{pg_bin_path}"
        
        # Wait for service to start
        print("Waiting for PostgreSQL service to start...")
        time.sleep(10)
        
        return True
        
    except Exception as e:
        print(f"Failed to download or install PostgreSQL: {e}")
        return False
    finally:
        # Clean up installer file
        try:
            os.unlink(installer_path)
        except:
            pass

def install_postgresql_unix():
    """Install PostgreSQL on Unix-like systems"""
    print("Installing PostgreSQL...")
    
    if check_command_exists("apt"):
        print("Installing PostgreSQL with apt...")
        run_command("sudo apt update")
        run_command("sudo apt install -y postgresql postgresql-contrib")
    elif check_command_exists("dnf"):
        print("Installing PostgreSQL with dnf...")
        run_command("sudo dnf install -y postgresql-server postgresql-contrib")
    elif check_command_exists("pacman"):
        print("Installing PostgreSQL with pacman...")
        run_command("sudo pacman -Sy --noconfirm postgresql")
    elif check_command_exists("brew"):
        print("Installing PostgreSQL with Homebrew...")
        run_command("brew install postgresql")
        run_command("brew services start postgresql")
    else:
        print("No supported package manager found. Please install PostgreSQL manually.")
        sys.exit(1)

def setup_postgresql_windows():
    """Setup PostgreSQL on Windows"""
    print("Setting up PostgreSQL on Windows...")
    
    PG_VERSION = "16.3"
    POSTGRES_PASSWORD = "dsec360@123"
    major_version = PG_VERSION.split(".")[0]
    
    # Check if PostgreSQL is already installed
    pg_bin_path = f"C:\\Program Files\\PostgreSQL\\{major_version}\\bin"
    psql_path = os.path.join(pg_bin_path, "psql.exe")
    
    if not os.path.exists(psql_path):
        print(f"PostgreSQL {PG_VERSION} not found. Installing...")
        if not install_postgresql_windows():
            print("Failed to install PostgreSQL automatically.")
            print("Please install PostgreSQL manually from: https://www.postgresql.org/download/windows/")
            return False
    else:
        print("PostgreSQL is already installed.")
        # Ensure it's in PATH
        current_path = os.environ.get('PATH', '')
        if pg_bin_path not in current_path:
            os.environ['PATH'] = f"{current_path};{pg_bin_path}"
    
    # Create SQL script for user and database setup
    sql_script = f'''
    DO $
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '{PG_USER}') THEN
            CREATE ROLE {PG_USER} WITH LOGIN PASSWORD '{PG_PASSWORD}';
        END IF;
    END
    $;

    DO $
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '{PG_DB}') THEN
            CREATE DATABASE {PG_DB} OWNER {PG_USER};
        END IF;
    END
    $;

    GRANT ALL PRIVILEGES ON DATABASE {PG_DB} TO {PG_USER};
    ALTER ROLE {PG_USER} CREATEDB;
    '''
    
    # Write SQL to temp file
    import tempfile
    with tempfile.NamedTemporaryFile(mode='w', suffix='.sql', delete=False) as sql_file:
        sql_file.write(sql_script)
        sql_file_path = sql_file.name
    
    try:
        print(f"Creating user {PG_USER} and database {PG_DB}...")
        
        # Set PGPASSWORD environment variable to avoid password prompt
        env = os.environ.copy()
        env['PGPASSWORD'] = POSTGRES_PASSWORD
        
        # Execute SQL script
        cmd = [psql_path, "-U", "postgres", "-d", "postgres", "-f", sql_file_path, "-v", "ON_ERROR_STOP=1"]
        result = subprocess.run(cmd, env=env, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"Database setup failed: {result.stderr}")
            return False
        
        # Update pg_hba.conf for md5 authentication
        pg_data_path = f"C:\\Program Files\\PostgreSQL\\{major_version}\\data"
        pg_hba_path = os.path.join(pg_data_path, "pg_hba.conf")
        
        if os.path.exists(pg_hba_path):
            print("Updating pg_hba.conf for md5 authentication...")
            
            # Read the file
            with open(pg_hba_path, 'r') as f:
                content = f.read()
            
            # Replace authentication methods
            import re
            content = re.sub(r'^(host\s+all\s+all\s+127\.0\.0\.1/32\s+)\w+', r'\1md5', content, flags=re.MULTILINE)
            content = re.sub(r'^(host\s+all\s+all\s+::1/128\s+)\w+', r'\1md5', content, flags=re.MULTILINE)
            
            # Write back
            with open(pg_hba_path, 'w') as f:
                f.write(content)
            
            # Restart PostgreSQL service
            print("Restarting PostgreSQL service...")
            try:
                subprocess.run(["net", "stop", f"postgresql-{major_version}"], check=False, capture_output=True)
                time.sleep(2)
                subprocess.run(["net", "start", f"postgresql-{major_version}"], check=True, capture_output=True)
                time.sleep(3)
            except subprocess.CalledProcessError:
                print("Warning: Could not restart PostgreSQL service automatically.")
        
        print("✅ PostgreSQL setup complete!")
        print(f"You can connect using: psql -U {PG_USER} -d {PG_DB}")
        return True
        
    except Exception as e:
        print(f"Error during PostgreSQL setup: {e}")
        return False
    finally:
        # Clean up SQL file
        try:
            os.unlink(sql_file_path)
        except:
            pass

def setup_postgresql_unix():
    """Setup PostgreSQL on Unix-like systems"""
    print("Setting up PostgreSQL on Unix...")
    
    # Check if PostgreSQL is installed
    if not check_command_exists("psql"):
        install_postgresql_unix()
    
    # Start PostgreSQL service
    if check_command_exists("systemctl"):
        run_command("sudo systemctl start postgresql", check=False)
        run_command("sudo systemctl enable postgresql", check=False)
    elif check_command_exists("brew"):
        run_command("brew services start postgresql", check=False)
    
    # Create user
    create_user_script = f'''
    DO $$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '{PG_USER}') THEN
            CREATE ROLE {PG_USER} WITH LOGIN PASSWORD '{PG_PASSWORD}';
        END IF;
    END
    $$;
    '''
    
    user_cmd = f'sudo -u postgres psql -c "{create_user_script}"'
    run_command(user_cmd, check=False)
    
    # Create database
    db_check = f"sudo -u postgres psql -tAc \"SELECT 1 FROM pg_database WHERE datname = '{PG_DB}'\""
    db_exists = run_command(db_check, capture_output=True, check=False)
    
    if "1" not in str(db_exists):
        print(f"Creating database {PG_DB}...")
        run_command(f'sudo -u postgres createdb -O {PG_USER} {PG_DB}')
    
    # Grant privileges
    grant_script = f'GRANT ALL PRIVILEGES ON DATABASE {PG_DB} TO {PG_USER}; ALTER ROLE {PG_USER} CREATEDB;'
    run_command(f'sudo -u postgres psql -c "{grant_script}"')
    
    return True

def setup_python_venv():
    """Setup Python virtual environment"""
    print("Setting up Python virtual environment...")
    
    # Check if python3-venv is available (Linux)
    os_type = get_os_type()
    if os_type == "unix" and platform.system().lower() == "linux":
        try:
            subprocess.run(["python3", "-m", "venv", "--help"], 
                         capture_output=True, check=True)
        except subprocess.CalledProcessError:
            print("Installing python3-venv...")
            run_command("sudo apt update && sudo apt install -y python3-venv")
    
    # Create virtual environment
    if not os.path.exists(VENV_DIR):
        print("Creating virtual environment...")
        python_cmd = "python" if os_type == "windows" else "python3"
        run_command(f"{python_cmd} -m venv {VENV_DIR}")
    
    return True

def find_django_project():
    """Find the Django project directory containing manage.py"""
    possible_paths = [
        os.path.join("backend", "DSEC"),  # Specific to your structure
        "backend",  # Fallback to direct backend
        os.path.join("backend", "django"),  # Common alternative
        "."  # Current directory as last resort
    ]
    
    for path in possible_paths:
        if os.path.exists(os.path.join(path, "manage.py")):
            return path
    
    return None

def activate_venv_and_install_deps():
    """Activate virtual environment and install dependencies"""
    print("Installing Python dependencies...")
    
    os_type = get_os_type()
    if os_type == "windows":
        pip_path = os.path.join(VENV_DIR, "Scripts", "pip.exe")
        python_path = os.path.join(VENV_DIR, "Scripts", "python.exe")
    else:
        pip_path = os.path.join(VENV_DIR, "bin", "pip")
        python_path = os.path.join(VENV_DIR, "bin", "python")
    
    # Upgrade pip
    run_command(f"{pip_path} install --upgrade pip")
    
    # Install requirements - check multiple possible locations
    requirements_paths = [
        os.path.join("backend", "DSEC", "requirements.txt"),  # Your specific structure
        os.path.join("backend", "requirements.txt"),
        "requirements.txt"
    ]
    
    requirements_found = False
    for req_path in requirements_paths:
        if os.path.exists(req_path):
            print(f"Installing dependencies from {req_path}...")
            run_command(f"{pip_path} install -r {req_path}")
            requirements_found = True
            break
    
    if not requirements_found:
        print("No requirements.txt found in expected locations.")
    
    return python_path

def run_django_migrations(python_path):
    """Run Django migrations"""
    print("Running Django migrations...")
    
    # Find Django project directory
    django_path = find_django_project()
    if not django_path:
        print("Django project directory with manage.py not found!")
        print("Searched in: backend/DSEC/, backend/, backend/django/, and current directory")
        return False
    
    print(f"Found Django project at: {django_path}")
    
    # Change to Django project directory
    original_dir = os.getcwd()
    os.chdir(django_path)
    
    try:
        # Calculate relative path to python executable
        if django_path == ".":
            python_cmd = python_path
        else:
            # Count directory levels to go back
            levels_back = len(django_path.split(os.sep))
            relative_path = os.sep.join([".."] * levels_back)
            python_cmd = os.path.join(relative_path, python_path)
        
        print(f"Using Python executable: {python_cmd}")
        run_command(f"{python_cmd} manage.py makemigrations")
        run_command(f"{python_cmd} manage.py migrate")
        return True
    finally:
        os.chdir(original_dir)

def start_django_server(python_path):
    """Start Django development server in a separate thread"""
    def run_server():
        print("Starting Django server at http://127.0.0.1:8000/")
        
        # Find Django project directory
        django_path = find_django_project()
        if not django_path:
            print("Django project directory with manage.py not found!")
            return
        
        # Change to Django project directory
        original_dir = os.getcwd()
        os.chdir(django_path)
        
        try:
            # Calculate relative path to python executable
            if django_path == ".":
                python_cmd = python_path
            else:
                # Count directory levels to go back
                levels_back = len(django_path.split(os.sep))
                relative_path = os.sep.join([".."] * levels_back)
                python_cmd = os.path.join(relative_path, python_path)
            
            subprocess.run([python_cmd, "manage.py", "runserver"], check=True)
        except subprocess.CalledProcessError:
            print("Django server stopped or failed to start")
        finally:
            os.chdir(original_dir)
    
    django_thread = threading.Thread(target=run_server, daemon=True)
    django_thread.start()
    return django_thread

def setup_frontend():
    """Setup and start React frontend"""
    print("Setting up React frontend...")
    
    # Check if Node.js and npm are installed
    if not check_command_exists("node"):
        print("Node.js is not installed. Please install Node.js from: https://nodejs.org/")
        return False
    
    if not check_command_exists("npm"):
        print("npm is not installed. Please install npm.")
        return False
    
    # Look for frontend directory
    frontend_path = "frontend"
    
    if not os.path.exists(frontend_path):
        print("Frontend directory not found!")
        return False
    
    if not os.path.exists(os.path.join(frontend_path, "package.json")):
        print("package.json not found in frontend directory!")
        return False
    
    print(f"Found frontend at: {frontend_path}")
    
    # Change to frontend directory
    original_dir = os.getcwd()
    os.chdir(frontend_path)
    
    try:
        # Install dependencies
        print("Installing npm dependencies...")
        run_command("npm install")
        
        # Start development server
        print("Starting React development server...")
        def run_frontend():
            try:
                subprocess.run(["npm", "run", "dev"], check=True)
            except subprocess.CalledProcessError:
                try:
                    subprocess.run(["npm", "start"], check=True)
                except subprocess.CalledProcessError:
                    print("Failed to start React development server")
        
        frontend_thread = threading.Thread(target=run_frontend, daemon=True)
        frontend_thread.start()
        
        return frontend_thread
    
    finally:
        os.chdir(original_dir)

def main():
    """Main function to orchestrate the setup and launch process"""
    print("=== Cross-Platform Project Launcher ===")
    print(f"Detected OS: {platform.system()}")
    
    os_type = get_os_type()
    
    try:
        # Step 1: Setup PostgreSQL
        print("\n--- Setting up PostgreSQL ---")
        if os_type == "windows":
            if not setup_postgresql_windows():
                print("PostgreSQL setup failed")
                return
        else:
            if not setup_postgresql_unix():
                print("PostgreSQL setup failed")
                return
        
        # Step 2: Setup Python environment
        print("\n--- Setting up Python environment ---")
        if not setup_python_venv():
            print("Python environment setup failed")
            return
        
        python_path = activate_venv_and_install_deps()
        
        # Step 3: Run Django migrations
        print("\n--- Running Django migrations ---")
        if not run_django_migrations(python_path):
            print("Django migrations failed")
            return
        
        # Step 4: Start Django server
        print("\n--- Starting Django backend ---")
        django_thread = start_django_server(python_path)
        
        # Give Django a moment to start
        time.sleep(3)
        
        # Step 5: Setup and start React frontend
        print("\n--- Starting React frontend ---")
        frontend_thread = setup_frontend()
        
        print("\n=== Setup Complete ===")
        print("Backend: http://127.0.0.1:8000/")
        print("Frontend: Check the terminal for the React dev server URL (usually http://localhost:3000)")
        print("\nPress Ctrl+C to stop all servers")
        
        # Keep the main thread alive
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\nShutting down servers...")
            
    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()