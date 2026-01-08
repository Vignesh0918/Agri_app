import requests
import uuid

# Production URL
BASE_URL = "https://agri-stock-backend.onrender.com/api"

def test_auth():
    # 1. Signup
    test_email = f"test_{uuid.uuid4().hex[:6]}@example.com"
    test_password = "password123"
    
    print(f"--- Testing Signup with {test_email} ---")
    signup_data = {
        "email": test_email,
        "full_name": "Test User",
        "password": test_password
    }
    
    try:
        r_signup = requests.post(f"{BASE_URL}/auth/signup", json=signup_data)
        print(f"Signup Status: {r_signup.status_code}")
        print(f"Signup Response: {r_signup.text}")
        
        if r_signup.status_code != 200:
            return
            
        # 2. Login
        print(f"\n--- Testing Login with {test_email} ---")
        login_data = {
            "username": test_email,
            "password": test_password
        }
        
        r_login = requests.post(f"{BASE_URL}/auth/login", json=login_data)
        print(f"Login Status: {r_login.status_code}")
        print(f"Login Response: {r_login.text}")
        
        if "access_token" in r_login.json():
            print("\n- AUTH FLOW WORKS ON PRODUCTION!")
            token = r_login.json()["access_token"]
            
            # 3. Test /me
            print("\n--- Testing /auth/me ---")
            headers = {"Authorization": f"Bearer {token}"}
            r_me = requests.get(f"{BASE_URL}/auth/me", headers=headers)
            print(f"Me Status: {r_me.status_code}")
            print(f"Me Response: {r_me.text}")
        else:
            print("\n- LOGIN FAILED!")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_auth()
