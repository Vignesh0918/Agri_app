
import sqlite3
import os

db_path = "agri_stock.db"

def fix_database():
    if not os.path.exists(db_path):
        print(f"Database file {db_path} not found.")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Check invoices table
    print("Checking 'invoices' table...")
    cursor.execute("PRAGMA table_info(invoices)")
    columns = [row[1] for row in cursor.fetchall()]
    
    if 'quantity_unit' not in columns:
        print("Adding 'quantity_unit' column to 'invoices' table...")
        try:
            cursor.execute("ALTER TABLE invoices ADD COLUMN quantity_unit TEXT DEFAULT 'kg'")
            print("Successfully added 'quantity_unit' to 'invoices'.")
        except Exception as e:
            print(f"Error adding column to 'invoices': {e}")
    else:
        print("'quantity_unit' already exists in 'invoices'.")

    # Check transactions table (just in case)
    print("\nChecking 'transactions' table...")
    cursor.execute("PRAGMA table_info(transactions)")
    columns = [row[1] for row in cursor.fetchall()]
    
    if 'quantity_unit' not in columns:
        print("Adding 'quantity_unit' column to 'transactions' table...")
        try:
            cursor.execute("ALTER TABLE transactions ADD COLUMN quantity_unit TEXT DEFAULT 'kg'")
            print("Successfully added 'quantity_unit' to 'transactions'.")
        except Exception as e:
            print(f"Error adding column to 'transactions': {e}")
    else:
        print("'quantity_unit' already exists in 'transactions'.")

    conn.commit()
    conn.close()
    print("\nDatabase fix completed.")

if __name__ == "__main__":
    fix_database()
