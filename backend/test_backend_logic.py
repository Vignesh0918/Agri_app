import requests
import json

BASE_URL = "http://localhost:8000/api"

def get_stats():
    try:
        r = requests.get(f"{BASE_URL}/dashboard/stats")
        print(f"Stats: {r.json()}")
        return r.json()
    except Exception as e:
        print(f"Error getting stats: {e}")
        return None

def create_product():
    p = {
        "name": "Test Product New",
        "category": "Seeds", 
        "unit_price": 100.0,
        "stock_quantity": 10.0,
        "min_stock_level": 5
    }
    r = requests.post(f"{BASE_URL}/products/", json=p)
    print(f"Created Product: {r.status_code}")
    return r.json()

def create_sale(product_name):
    t = {
        "type": "sale",
        "party_name": "Test Customer",
        "phone_number": "9999999999",
        "product_name": product_name,
        "quantity": 5.0,
        "unit_price": 100.0,
        "gst_percentage": 0.0,
        "quantity_unit": "kg"
    }
    r = requests.post(f"{BASE_URL}/transactions/", json=t)
    print(f"Created Sale: {r.status_code}")
    return r.json()

print("--- 1. Initial Stats ---")
initial = get_stats()

print("\n--- 2. Add Stock (New Product) ---")
product = create_product()

print("\n--- 3. Stats After Stock Add ---")
after_stock = get_stats()

print("\n--- 4. Make Sale ---")
create_sale(product['name'])

print("\n--- 5. Stats After Sale ---")
final = get_stats()
