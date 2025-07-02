import sys
import json
import os
import re
from .generate import generate_mariadb_work_remote
from .generate import generate_mariadb_work
from .validate import validate_maria_db

import pymysql

def connect(user, password, host, port, database, domain=None):
    try:
        full_user = f"{domain}\\{user}" if domain else user
        conn = pymysql.connect(
            user=full_user,
            password=password,
            host=host,
            port=port,
            database=database,
            autocommit=True
        )
        print("✅ Connected to MariaDB via PyMySQL as", full_user)
        return conn
    except pymysql.MySQLError as e:
        print(f"❌ Connection Error: {e}")
        return None


def run_script_and_save_json(conn, script_path, json_path):
    print(f"Running script: {script_path}")
    cursor = conn.cursor()
    try:
        with open(script_path, 'r') as f:
            query = f.read()

        cursor.execute(query)
        row = cursor.fetchone()

        if row and row[0]:
            json_data = json.loads(row[0])
            with open(json_path, 'w', encoding='utf-8') as out_file:
                json.dump(json_data, out_file, indent=4)
            print(f"✅ JSON saved to {json_path}")
            return json_data  # ✅ Return parsed JSON
        else:
            print("⚠️ No JSON output returned.")
            return None
    except Exception as e:
        print(f"❌ Error running script: {e}")
        return None
    finally:
        cursor.close()
import os

def get_base_dir(override=None):
    if override and os.path.isdir(override):
        return os.path.abspath(override)  # user-defined, valid directory
    try:
        return os.path.dirname(os.path.abspath(__file__))  # script directory
    except NameError:
        return os.getcwd()  # fallback for environments like Jupyter

def convert_title_to_check_name(title: str) -> str:
        # Extract number (e.g., 1.2 or 2.1.5) and rest of the title
        match = re.match(r"(\d+(?:\.\d+)*)(?:\s+)(.+?)\s*\(Automated\)", title)
        if not match:
            return None  # invalid format

        number_part = match.group(1).replace('.', '_')  # 1.2 -> 1_2
        text_part = match.group(2)

        # Replace special chars with underscore-friendly equivalents
        text_part = re.sub(r"[^a-zA-Z0-9]", "_", text_part)
        text_part = re.sub(r"_+", "_", text_part).strip("_")

        return f"{number_part}_{text_part}_Automated_"


