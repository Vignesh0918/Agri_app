
import sqlite3
import os

paths = ["agri_stock.db", "backend/agri_stock.db"]

for p in paths:
    if os.path.exists(p):
        print(f"\n--- Database: {p} ---")
        conn = sqlite3.connect(p)
        cursor = conn.cursor()
        
        tables = ['transactions', 'invoices']
        for table in tables:
            print(f"  Table: {table}")
            cursor.execute(f"PRAGMA table_info({table})")
            columns = [row[1] for row in cursor.fetchall()]
            print(f"    Columns: {columns}")
            if 'quantity_unit' in columns:
                print(f"    ✅ 'quantity_unit' EXISTS")
            else:
                print(f"    ❌ 'quantity_unit' MISSING")
        conn.close()
    else:
        print(f"\n--- Database NOT FOUND: {p} ---")
