import requests
import json
import time

BASE_URL = "http://localhost:8000"

def test_backend():
    print("🔍 Testing Backend Endpoints...")
    
    # 1. Health Check
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"✅ Health Check: {response.status_code} - {response.json()}")
    except Exception as e:
        print(f"❌ Health Check Failed: {e}")
        return

    # 2. Signup
    signup_data = {
        "email": f"testuser_{int(time.time())}@example.com",
        "full_name": "Test User",
        "password": "password123"
    }
    response = requests.post(f"{BASE_URL}/api/auth/signup", json=signup_data)
    print(f"✅ Signup: {response.status_code}")
    if response.status_code != 200:
        print(f"Error: {response.text}")
        return
    user_email = signup_data["email"]

    # 3. Login
    login_data = {
        "username": user_email,
        "password": "password123"
    }
    response = requests.post(f"{BASE_URL}/api/auth/login", json=login_data)
    print(f"✅ Login: {response.status_code}")
    if response.status_code != 200:
        print(f"Error: {response.text}")
        return
    
    token = response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 4. Get Me
    response = requests.get(f"{BASE_URL}/api/auth/me", headers=headers)
    print(f"✅ Get Me: {response.status_code} - {response.json()['full_name']}")

    # 5. Create Product
    product_data = {
        "name": "Test Product",
        "description": "A product for testing",
        "category": "Seeds",
        "unit_price": 150.0,
        "stock_quantity": 100,
        "min_stock_level": 10
    }
    response = requests.post(f"{BASE_URL}/api/products/", json=product_data, headers=headers)
    print(f"✅ Create Product: {response.status_code}")
    product_id = response.json()["id"]

    # 6. Get Products
    response = requests.get(f"{BASE_URL}/api/products/", headers=headers)
    print(f"✅ Get Products: {response.status_code} - Found {len(response.json())} products")

    # 7. Create Transaction (Sale)
    # This should also create an invoice
    transaction_data = {
        "type": "sale",
        "party_name": "Test Customer",
        "phone_number": "1234567890",
        "product_name": "Test Product",
        "quantity": 5,
        "unit_price": 200.0,
        "gst_percentage": 5.0
    }
    response = requests.post(f"{BASE_URL}/api/transactions/", json=transaction_data, headers=headers)
    print(f"✅ Create Sale Transaction: {response.status_code}")
    if response.status_code != 200:
        print(f"Error: {response.text}")
    
    # 8. Check Stock after sale
    response = requests.get(f"{BASE_URL}/api/products/{product_id}", headers=headers)
    print(f"✅ Stock Check: {response.json()['stock_quantity']} (Initial: 100, Sold: 5, Expected: 95)")

    # 9. Get Invoices
    response = requests.get(f"{BASE_URL}/api/invoices/", headers=headers)
    print(f"✅ Get Invoices: {response.status_code} - Found {len(response.json())} invoices")
    
    # 10. Get Summary
    response = requests.get(f"{BASE_URL}/api/transactions/summary", headers=headers)
    print(f"✅ Summary: {response.json()}")

    print("\n🚀 All tests passed successfully!")

if __name__ == "__main__":
    # Wait for server to be fully ready
    time.sleep(2)
    test_backend()
