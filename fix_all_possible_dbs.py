
import sqlite3
import os

db_paths = ["agri_stock.db", "backend/agri_stock.db"]

def fix_all_dbs():
    for db_path in db_paths:
        if not os.path.exists(db_path):
            print(f"Skipping {db_path} (not found)")
            continue

        print(f"\nFixing database: {db_path}")
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        for table in ['transactions', 'invoices']:
            cursor.execute(f"PRAGMA table_info({table})")
            columns = [row[1] for row in cursor.fetchall()]
            
            if 'quantity_unit' not in columns:
                print(f"  Adding 'quantity_unit' to {table}...")
                try:
                    cursor.execute(f"ALTER TABLE {table} ADD COLUMN quantity_unit TEXT DEFAULT 'kg'")
                except Exception as e:
                    print(f"  Error: {e}")
            else:
                print(f"  'quantity_unit' already exists in {table}")
                
        conn.commit()
        conn.close()

if __name__ == "__main__":
    fix_all_dbs()
