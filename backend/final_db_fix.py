
import sqlite3
import os

db_path = "agri_stock.db"

def fix_db():
    if not os.path.exists(db_path):
        print(f"Database {db_path} not found.")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    tables = ['transactions', 'invoices']
    
    for table in tables:
        print(f"Checking table: {table}")
        cursor.execute(f"PRAGMA table_info({table})")
        columns = [row[1] for row in cursor.fetchall()]
        
        if 'quantity_unit' not in columns:
            print(f"Adding 'quantity_unit' to {table}...")
            try:
                # Use a default value of 'kg' to avoid nulls
                cursor.execute(f"ALTER TABLE {table} ADD COLUMN quantity_unit TEXT DEFAULT 'kg'")
                print(f"Successfully added column to {table}")
            except Exception as e:
                print(f"Error adding column to {table}: {e}")
        else:
            print(f"Column 'quantity_unit' already exists in {table}")
            
    conn.commit()
    conn.close()
    print("Database check completed.")

if __name__ == "__main__":
    fix_db()
