
import sqlite3
import os

db_path = "agri_stock.db"
if not os.path.exists(db_path):
    print(f"Database file {db_path} not found.")
else:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    print("--- USERS ---")
    try:
        cursor.execute("SELECT email, full_name FROM users")
        users = cursor.fetchall()
        for user in users:
            print(f"Email: {user[0]}, Name: {user[1]}")
    except Exception as e:
        print(f"Error reading users: {e}")
        
    print("\n--- PRODUCTS ---")
    try:
        cursor.execute("SELECT name, stock_quantity FROM products")
        products = cursor.fetchall()
        for prod in products:
            print(f"Product: {prod[0]}, Stock: {prod[1]}")
    except Exception as e:
        print(f"Error reading products: {e}")
        
    conn.close()
