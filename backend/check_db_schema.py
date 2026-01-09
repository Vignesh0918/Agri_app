
import sqlite3
import os

db_path = "agri_stock.db"

def check_schema():
    if not os.path.exists(db_path):
        print(f"Database file {db_path} not found.")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    for table in ['invoices', 'transactions']:
        print(f"\nSchema for table: {table}")
        cursor.execute(f"PRAGMA table_info({table})")
        cols = cursor.fetchall()
        for col in cols:
            print(col)
            
    conn.close()

if __name__ == "__main__":
    check_schema()
