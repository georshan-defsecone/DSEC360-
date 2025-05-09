#!/bin/bash

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
