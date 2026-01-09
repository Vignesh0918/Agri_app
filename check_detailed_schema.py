
import sqlite3
import os

db_path = "backend/agri_stock.db"
if not os.path.exists(db_path):
    print(f"File {db_path} not found")
    exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

def check_table(table):
    print(f"\n--- Table: {table} ---")
    cursor.execute(f"PRAGMA table_info({table})")
    cols = cursor.fetchall()
    for c in cols:
        print(f"ID: {c[0]}, Name: '{c[1]}', Type: {c[2]}")

check_table("invoices")
check_table("transactions")

conn.close()
