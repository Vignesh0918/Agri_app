
import sqlite3
import os

db_path = "backend/verified_stock.db"
if not os.path.exists(db_path):
    print(f"File {db_path} not found")
    exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

for table in ['transactions', 'invoices']:
    print(f"Fixing table: {table}")
    cursor.execute(f"PRAGMA table_info({table})")
    columns = [row[1] for row in cursor.fetchall()]
    
    if 'quantity_unit' not in columns:
        print(f"  Adding 'quantity_unit' to {table}...")
        cursor.execute(f"ALTER TABLE {table} ADD COLUMN quantity_unit TEXT DEFAULT 'kg'")
    else:
        print(f"  Column exists in {table}")

conn.commit()
conn.close()
print("DONE")
