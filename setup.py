#!/usr/bin/env python3
"""
Cross-platform project launcher for React + Django application
Automatically detects OS and sets up PostgreSQL, Django backend, and React frontend
v3
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

def run_command(command, shell=True, check=True, capture_output=False, ignore_errors=False):
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
        if ignore_errors:
            print(f"Command failed (ignored): {command}")
            return False
        print(f"Command failed: {command}")
        print(f"Error: {e}")
        if hasattr(e, 'stderr') and e.stderr:
            print(f"Stderr: {e.stderr}")
        return False

def check_command_exists(command):
    """Check if a command exists in the system PATH"""
    return shutil.which(command) is not None

def update_system_packages():
    """Update system packages first (Unix systems)"""
    print("Updating system packages...")
    
    if check_command_exists("apt"):
        print("Updating apt packages...")
        run_command("sudo apt update")
        print("Upgrading system packages...")
        run_command("sudo apt upgrade -y")
    elif check_command_exists("dnf"):
        print("Updating dnf packages...")
        run_command("sudo dnf update -y")
    elif check_command_exists("pacman"):
        print("Updating pacman packages...")
        run_command("sudo pacman -Syu --noconfirm")
    elif check_command_exists("brew"):
        print("Updating Homebrew...")
        run_command("brew update")
        run_command("brew upgrade")
    else:
        print("No supported package manager found for system updates.")

def install_postgresql_windows():
    """Install PostgreSQL on Windows automatically"""
    import urllib.request
    import tempfile
    
    PG_VERSION = "17.4"
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
        run_command("sudo apt install -y postgresql postgresql-contrib")
    elif check_command_exists("dnf"):
        print("Installing PostgreSQL with dnf...")
        run_command("sudo dnf install -y postgresql-server postgresql-contrib")
        run_command("sudo postgresql-setup --initdb", ignore_errors=True)
        run_command("sudo systemctl enable postgresql", ignore_errors=True)
        run_command("sudo systemctl start postgresql", ignore_errors=True)
    elif check_command_exists("pacman"):
        print("Installing PostgreSQL with pacman...")
        run_command("sudo pacman -Sy --noconfirm postgresql")
        run_command("sudo -u postgres initdb -D /var/lib/postgres/data", ignore_errors=True)
        run_command("sudo systemctl enable postgresql", ignore_errors=True)
        run_command("sudo systemctl start postgresql", ignore_errors=True)
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
    
    PG_VERSION = "17.4"
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
        print("Starting PostgreSQL service...")
        run_command("sudo systemctl start postgresql", check=False)
        run_command("sudo systemctl enable postgresql", check=False)
        time.sleep(2)  # Give service time to start
    elif check_command_exists("brew"):
        run_command("brew services start postgresql", check=False)
    
    # Test PostgreSQL connection
    print("Testing PostgreSQL connection...")
    test_result = run_command('sudo -u postgres psql -c "SELECT version();"', capture_output=True, check=False)
    if not test_result:
        print("PostgreSQL service may not be running properly. Attempting to restart...")
        run_command("sudo systemctl restart postgresql", check=False)
        time.sleep(3)
    
    # Create user first - Fixed the order and error handling
    print(f"Creating PostgreSQL user {PG_USER}...")
    create_user_script = f"CREATE USER {PG_USER} WITH PASSWORD '{PG_PASSWORD}' CREATEDB;"
    
    # Check if user already exists
    user_exists_cmd = f'sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname=\'{PG_USER}\'"'
    user_exists = run_command(user_exists_cmd, capture_output=True, check=False)
    
    if "1" not in str(user_exists):
        user_cmd = f'sudo -u postgres psql -c "{create_user_script}"'
        if not run_command(user_cmd, check=False):
            print(f"Failed to create user {PG_USER}. Trying alternative method...")
            # Alternative method using createuser
            run_command(f'sudo -u postgres createuser -d -P {PG_USER}', check=False)
    else:
        print(f"User {PG_USER} already exists")
    
    # Create database - now that user exists
    print(f"Creating database {PG_DB}...")
    db_check = f'sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = \'{PG_DB}\'"'
    db_exists = run_command(db_check, capture_output=True, check=False)
    
    if "1" not in str(db_exists):
        print(f"Creating database {PG_DB}...")
        # First try with owner
        if not run_command(f'sudo -u postgres createdb -O {PG_USER} {PG_DB}', check=False):
            # If that fails, create without owner and grant later
            if run_command(f'sudo -u postgres createdb {PG_DB}', check=False):
                run_command(f'sudo -u postgres psql -c "ALTER DATABASE {PG_DB} OWNER TO {PG_USER};"', check=False)
    else:
        print(f"Database {PG_DB} already exists")
    
    # Grant privileges
    print("Granting privileges...")
    grant_script = f'GRANT ALL PRIVILEGES ON DATABASE {PG_DB} TO {PG_USER}; ALTER ROLE {PG_USER} CREATEDB;'
    run_command(f'sudo -u postgres psql -c "{grant_script}"', check=False)
    
    # Update pg_hba.conf for password authentication
    print("Configuring PostgreSQL authentication...")
    pg_hba_locations = [
        "/etc/postgresql/*/main/pg_hba.conf",
        "/var/lib/pgsql/data/pg_hba.conf",
        "/usr/local/var/postgres/pg_hba.conf"
    ]
    
    import glob
    for location_pattern in pg_hba_locations:
        for pg_hba_path in glob.glob(location_pattern):
            if os.path.exists(pg_hba_path):
                print(f"Updating {pg_hba_path}...")
                try:
                    # Backup original file
                    run_command(f"sudo cp {pg_hba_path} {pg_hba_path}.backup", check=False)
                    
                    # Update authentication method for local connections
                    sed_cmd = f"sudo sed -i 's/local.*all.*all.*peer/local   all             all                                     md5/' {pg_hba_path}"
                    run_command(sed_cmd, check=False)
                    
                    # Restart PostgreSQL to apply changes
                    run_command("sudo systemctl restart postgresql", check=False)
                    time.sleep(3)
                    break
                except:
                    print(f"Could not update {pg_hba_path}")
    
    # Test the connection with the new user
    print("Testing connection with new user...")
    test_connection_cmd = f'PGPASSWORD="{PG_PASSWORD}" psql -U {PG_USER} -d {PG_DB} -c "SELECT current_database();"'
    if run_command(test_connection_cmd, check=False, capture_output=True):
        print("✅ PostgreSQL setup complete!")
        print(f"You can connect using: PGPASSWORD='{PG_PASSWORD}' psql -U {PG_USER} -d {PG_DB}")
        return True
    else:
        print("⚠️  PostgreSQL setup completed but connection test failed.")
        print("You may need to configure pg_hba.conf for password authentication manually.")
        return True  # Continue anyway as the setup might still work

def install_python_venv_packages():
    """Install python3-venv package on Unix systems"""
    print("Installing python3-venv package...")
    
    # Get Python version
    python_version_output = run_command("python3 --version", capture_output=True, check=False)
    if not python_version_output:
        print("Python3 not found!")
        return False
    
    print(f"Detected Python: {python_version_output}")
    
    # Extract version number
    import re
    version_match = re.search(r'Python (\d+\.\d+)', str(python_version_output))
    if version_match:
        python_version = version_match.group(1)
        print(f"Python version: {python_version}")
    else:
        python_version = None
    
    if check_command_exists("apt"):
        if python_version:
            # Try version-specific package first
            print(f"Installing python{python_version}-venv...")
            if run_command(f"sudo apt install -y python{python_version}-venv", check=False):
                return True
        
        # Fallback to generic package
        print("Installing python3-venv...")
        return run_command("sudo apt install -y python3-venv", check=False)
    
    elif check_command_exists("dnf"):
        print("Installing python3-virtualenv...")
        return run_command("sudo dnf install -y python3-virtualenv", check=False)
    
    elif check_command_exists("pacman"):
        print("Installing python-virtualenv...")
        return run_command("sudo pacman -S --noconfirm python-virtualenv", check=False)
    
    elif check_command_exists("brew"):
        print("Python venv should be available with Homebrew Python")
        return True
    
    else:
        print("No supported package manager found for installing python3-venv")
        return False

def setup_python_venv():
    """Setup Python virtual environment"""
    print("Setting up Python virtual environment...")
    
    os_type = get_os_type()
    
    if os_type == "unix":
        # Check if python3-venv is available
        python_version = run_command("python3 --version", capture_output=True, check=False)
        print(f"Detected Python: {python_version}")
        
        # Test if venv module is available
        test_venv = run_command("python3 -m venv --help", capture_output=True, check=False)
        if not test_venv:
            print("python3-venv not found. Installing...")
            if not install_python_venv_packages():
                print("Failed to install python3-venv package.")
                print("Please install manually:")
                print("  sudo apt install python3-venv  # On Ubuntu/Debian")
                print("  sudo dnf install python3-virtualenv  # On Fedora")
                print("  sudo pacman -S python-virtualenv  # On Arch")
                return False
    
    # Remove existing venv if it's corrupted
    if os.path.exists(VENV_DIR):
        print("Removing existing virtual environment...")
        shutil.rmtree(VENV_DIR)
    
    # Create virtual environment
    print("Creating virtual environment...")
    python_cmd = "python" if os_type == "windows" else "python3"
    if not run_command(f"{python_cmd} -m venv {VENV_DIR}"):
        print("Failed to create virtual environment.")
        print("Please ensure python3-venv is installed:")
        if os_type == "unix":
            print("  sudo apt install python3-venv")
        return False
    
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
        print("Installing basic Django requirements...")
        # Install basic requirements if no requirements.txt found
        run_command(f"{pip_path} install django psycopg2-binary python-dotenv")
    
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
        
        # Check if Django settings are properly configured
        print("Checking Django configuration...")
        settings_check = run_command(f"{python_cmd} manage.py check", check=False)
        if not settings_check:
            print("Django configuration check failed. Please check your settings.py")
            print("Make sure your database settings are correct:")
            print(f"  - Database: {PG_DB}")
            print(f"  - User: {PG_USER}")
            print(f"  - Password: {PG_PASSWORD}")
            print("  - Host: localhost")
            print("  - Port: 5432")
        
        run_command(f"{python_cmd} manage.py makemigrations", check=False)
        run_command(f"{python_cmd} manage.py migrate", check=False)
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
        except KeyboardInterrupt:
            print("Django server stopped by user")
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
    script_dir = os.path.dirname(os.path.abspath(__file__))
    frontend_path = os.path.join(script_dir, "frontend")
    
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
                os.chdir(frontend_path)
                subprocess.run(["npm", "run", "dev"], check=True)
            except subprocess.CalledProcessError:
                try:
                    subprocess.run(["npm", "start"], check=True)
                except subprocess.CalledProcessError:
                    print("Failed to start React development server")
            except KeyboardInterrupt:
                print("React server stopped by user")
        
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
        # Step 0: Update system packages first (Unix only)
        if os_type == "unix":
            print("\n--- Updating system packages ---")
            update_system_packages()
        
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
            print("Django migrations failed - but continuing...")
        
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
        print(f"\nDatabase connection info:")
        print(f"  Database: {PG_DB}")
        print(f"  User: {PG_USER}")
        print(f"  Password: {PG_PASSWORD}")
        print(f"  Host: localhost")
        print(f"  Port: 5432")
        print("\nPress Ctrl+C to stop all servers")
        
        # Keep the main thread alive
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\nShutting down servers...")
            
    except Exception as e:
        print(f"An error occurred: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()