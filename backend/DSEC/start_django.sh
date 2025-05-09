#!/bin/bash

APP_NAME="psql"
PG_USER="dsec360"
PG_PASSWORD="dsec360@123"
PG_DB="dsec360"
POSTGRES_PASSWORD="dsec360@123"

# Check if PostgreSQL is installed
if command -v $APP_NAME >/dev/null 2>&1; then
    echo "PostgreSQL is already installed."
else
    echo "PostgreSQL is not installed."

    if [ -x "$(command -v apt)" ]; then
        echo "Installing PostgreSQL with apt..."
        sudo apt update
        sudo apt install -y postgresql postgresql-contrib
    elif [ -x "$(command -v dnf)" ]; then
        echo "Installing PostgreSQL with dnf..."
        sudo dnf install -y postgresql-server postgresql-contrib
    elif [ -x "$(command -v pacman)" ]; then
        echo "Installing PostgreSQL with pacman..."
        sudo pacman -Sy --noconfirm postgresql
    else
        echo "No supported package manager found. Please install PostgreSQL manually."
        exit 1
    fi

    echo "PostgreSQL installation complete."
fi

# Create user if it doesn't exist
sudo -u postgres psql <<EOF
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$PG_USER') THEN
        CREATE ROLE $PG_USER WITH LOGIN PASSWORD '$PG_PASSWORD';
    END IF;
END
\$\$;
EOF

# Create database if it doesn't exist
DB_EXISTS=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = '$PG_DB'")
if [ "$DB_EXISTS" != "1" ]; then
    echo "Creating database $PG_DB..."
    sudo -u postgres createdb -O "$PG_USER" "$PG_DB"
else
    echo "Database $PG_DB already exists."
fi

# Grant privileges and alter role
sudo -u postgres psql <<EOF
GRANT ALL PRIVILEGES ON DATABASE $PG_DB TO $PG_USER;
ALTER ROLE $PG_USER CREATEDB;
EOF

# Set password for postgres role
echo "Setting password for 'postgres' user..."
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$POSTGRES_PASSWORD';"

# Find the actual path to pg_hba.conf
echo "Locating pg_hba.conf..."
HBA_PATH=$(sudo -u postgres psql -t -P format=unaligned -c "SHOW hba_file;" | xargs)

if [ -f "$HBA_PATH" ]; then
    echo "pg_hba.conf found at $HBA_PATH"
    echo "Backing up original pg_hba.conf..."
    sudo cp "$HBA_PATH" "${HBA_PATH}.bak"

    echo "Updating authentication method to 'md5'..."
    sudo sed -i 's/^\(local\s\+all\s\+all\s\+\)peer/\1md5/' "$HBA_PATH"
    sudo sed -i 's/^\(local\s\+all\s\+postgres\s\+\)peer/\1md5/' "$HBA_PATH"

    echo "Restarting PostgreSQL..."
    sudo systemctl restart postgresql
else
    echo "Could not find pg_hba.conf at expected location. Please update it manually."
    exit 1
fi


sudo systemctl start postgresql
sudo systemctl enable postgresql

echo "PostgreSQL setup complete. You can now connect using:"
echo "psql -U $PG_USER -d $PG_DB"

# Exit on error
set -e

# Define your virtual environment directory
VENV_DIR="venv"

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv $VENV_DIR
fi

# Activate virtual environment
echo "Activating virtual environment..."
source $VENV_DIR/bin/activate

# Install dependencies
if [ -f "requirements.txt" ]; then
    echo "Installing dependencies from requirements.txt..."
    pip install --upgrade pip
    pip install -r requirements.txt
else
    echo "No requirements.txt found."
fi

# Run migrations
echo "Making and applying migrations..."
python manage.py makemigrations
python manage.py migrate

# Start the Django server
echo "Starting Django server at http://127.0.0.1:8000/"
python manage.py runserver
