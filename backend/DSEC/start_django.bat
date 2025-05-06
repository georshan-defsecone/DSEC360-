@echo off
SET VENV_DIR=venv

REM Check if virtual environment exists
IF NOT EXIST %VENV_DIR%\Scripts\activate.bat (
    echo Creating virtual environment...
    python -m venv %VENV_DIR%
)

REM Activate virtual environment
CALL %VENV_DIR%\Scripts\activate.bat

REM Install dependencies
IF EXIST requirements.txt (
    echo Installing dependencies from requirements.txt...
    python -m pip install --upgrade pip
    pip install -r requirements.txt
) ELSE (
    echo No requirements.txt found.
)

REM Run Django migrations
echo Making and applying migrations...
python manage.py makemigrations
python manage.py migrate

REM Start Django development server
echo Starting Django server at http://127.0.0.1:8000/
python manage.py runserver
