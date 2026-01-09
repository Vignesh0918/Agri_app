
import requests
import json

data = {
    'type': 'sale', 
    'party_name': 'Test Customer', 
    'phone_number': '1234567890', 
    'product_name': 'urea', 
    'quantity': 1.0, 
    'unit_price': 100.0, 
    'gst_percentage': 18.0, 
    'quantity_unit': 'kg'
}

try:
    r = requests.post('http://localhost:8000/api/transactions/', json=data)
    print(f"Status Code: {r.status_code}")
    print(f"Response: {r.text}")
except Exception as e:
    print(f"Request failed: {e}")
