import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    print("Error: DATABASE_URL not found in .env file.")
    exit(1)

if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

engine = create_engine(DATABASE_URL)

def apply_migrations():
    print(f"Connecting to: {DATABASE_URL.split('@')[-1] if '@' in DATABASE_URL else 'local db'}")
    
    with engine.connect() as conn:
        # 1. Check and add quantity_unit to invoices
        try:
            print("Checking 'invoices' table for 'quantity_unit' column...")
            conn.execute(text("ALTER TABLE invoices ADD COLUMN quantity_unit VARCHAR DEFAULT 'kg'"))
            conn.commit()
            print("✅ Added 'quantity_unit' column to 'invoices' table.")
        except Exception as e:
            if "already exists" in str(e).lower() or "duplicate column" in str(e).lower():
                print("ℹ️ 'quantity_unit' column already exists in 'invoices'.")
            else:
                print(f"⚠️ Error updating 'invoices': {e}")

        # 2. Check and add quantity_unit to transactions (just in case)
        try:
            print("Checking 'transactions' table for 'quantity_unit' column...")
            conn.execute(text("ALTER TABLE transactions ADD COLUMN quantity_unit VARCHAR DEFAULT 'kg'"))
            conn.commit()
            print("✅ Added 'quantity_unit' column to 'transactions' table.")
        except Exception as e:
            if "already exists" in str(e).lower() or "duplicate column" in str(e).lower():
                print("ℹ️ 'quantity_unit' column already exists in 'transactions'.")
            else:
                print(f"⚠️ Error updating 'transactions': {e}")

    print("\nMigration process completed.")

if __name__ == "__main__":
    apply_migrations()
