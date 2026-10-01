import pandas as pd
from pathlib import Path
from sqlalchemy import create_engine
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

# -----------------------------
# CONFIG
# -----------------------------

CSV_PATH = Path("data/raw/db_name.csv") # IMPORTANT: update with your actual CSV file path
TABLE_NAME = "UK_online_retail_db"

DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_NAME = os.getenv("DB_NAME")

# -----------------------------
# CREATE DATABASE CONNECTION
# -----------------------------

engine = create_engine(
    f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

# -----------------------------
# READ CSV
# -----------------------------

df = pd.read_csv(CSV_PATH)

print("CSV loaded successfully.")
print(f"Rows: {df.shape[0]}")
print(f"Columns: {df.shape[1]}")
print(df.head())

# -----------------------------
# UPLOAD TO MYSQL
# -----------------------------

df.to_sql(
    name=TABLE_NAME,
    con=engine,
    if_exists="replace",   # replaces table in case it was already created
    index=False
)

print(f"Data uploaded successfully to table: {TABLE_NAME}")