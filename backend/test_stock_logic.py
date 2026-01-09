
import sqlite3
import os

db_path = "agri_stock.db"

def get_total_stock():
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("SELECT SUM(stock_quantity) FROM products WHERE is_active = 1")
    total = cursor.fetchone()[0] or 0.0
    conn.close()
    return total

def add_stock(product_name, qty):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("UPDATE products SET stock_quantity = stock_quantity + ? WHERE name = ?", (qty, product_name))
    conn.commit()
    conn.close()

print(f"Initial Total Stock: {get_total_stock()}")
print("Adding 10 units to 'urea'...")
add_stock('urea', 10.0)
print(f"New Total Stock: {get_total_stock()}")
