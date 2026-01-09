
import requests
import json
import time

BASE_URL = "http://localhost:8000/api"

def test_full_sale_cycle():
    print("--- Testing Full Sale Cycle ---")
    
    # 1. Check current products
    print("\n1. Fetching products...")
    prods = requests.get(f"{BASE_URL}/products/").json()
    if not prods:
        print("No products found to test. Creating 'Urea'...")
        p_data = {
            "name": "Urea",
            "category": "Fertilizer",
            "unit_price": 500,
            "stock_quantity": 100,
            "min_stock_level": 10
        }
        requests.post(f"{BASE_URL}/products/", json=p_data)
        prods = requests.get(f"{BASE_URL}/products/").json()
    
    product = prods[0]
    p_name = product['name']
    initial_stock = product['stock_quantity']
    print(f"Testing with Product: {p_name}, Initial Stock: {initial_stock}")

    # 2. Check current dashboard stats
    print("\n2. Fetching dashboard stats before sale...")
    stats_before = requests.get(f"{BASE_URL}/dashboard/stats").json()
    initial_sales_total = stats_before.get('today_sales_total', 0)
    print(f"Initial Today Sales Total: Indian Rupee {initial_sales_total}")

    # 3. Perform a Sale
    print("\n3. Performing a Sale...")
    sale_data = {
        "type": "sale",
        "party_name": "Test Customer",
        "phone_number": "9876543210",
        "product_name": p_name,
        "quantity": 5,
        "unit_price": 500,
        "gst_percentage": 18,
        "quantity_unit": "kg"
    }
    sale_res = requests.post(f"{BASE_URL}/transactions/", json=sale_data)
    
    if sale_res.status_code != 200:
        print(f"❌ SALE FAILED! Status: {sale_res.status_code}")
        print(f"Error detail: {sale_res.text}")
        return
    
    print("✅ Sale successful!")
    txn = sale_res.json()
    print(f"Generated Invoice: {txn.get('invoice_number')}")

    # 4. Verify Stock Decrease
    print("\n4. Verifying Stock Decrease...")
    prods_after = requests.get(f"{BASE_URL}/products/").json()
    product_after = next(p for p in prods_after if p['name'] == p_name)
    new_stock = product_after['stock_quantity']
    print(f"New Stock: {new_stock}")
    if new_stock == initial_stock - 5:
        print("✅ Stock decreased correctly!")
    else:
        print(f"❌ Stock didn't decrease correctly! (Expected {initial_stock - 5})")

    # 5. Verify Dashboard Update
    print("\n5. Verifying Dashboard Stats Update...")
    stats_after = requests.get(f"{BASE_URL}/dashboard/stats").json()
    new_sales_total = stats_after.get('today_sales_total', 0)
    print(f"New Today Sales Total: Indian Rupee {new_sales_total}")
    if new_sales_total > initial_sales_total:
        print("✅ Dashboard sales total updated!")
    else:
        print("❌ Dashboard sales total NOT updated!")

    # 6. Verify Invoice Generation
    print("\n6. Verifying Invoice exists...")
    inv_res = requests.get(f"{BASE_URL}/invoices/").json()
    inv_exists = any(i['invoice_number'] == txn.get('invoice_number') for i in inv_res)
    if inv_exists:
        print("✅ Invoice found in history!")
    else:
        print("❌ Invoice NOT found in history!")

if __name__ == "__main__":
    try:
        test_full_sale_cycle()
    except Exception as e:
        print(f"Test crashed: {e}")
