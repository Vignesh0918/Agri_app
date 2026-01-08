import socket
import os

def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

def print_instructions():
    ip = get_ip()
    print("\n" + "="*50)
    print("🌍 AGRI STOCK MANAGER - BACKEND SETUP")
    print("="*50)
    print(f"\nYour laptop's local IP address is: {ip}")
    print(f"The backend will be running at: http://{ip}:8000")
    print(f"\nIMPORTANT for Flutter App:")
    print(f"Update lib/services/api_service.dart with this IP:")
    print(f"return 'http://{ip}:8000';")
    print("\n" + "="*50 + "\n")

if __name__ == "__main__":
    print_instructions()
    import uvicorn
    from main import app
    uvicorn.run(app, host="0.0.0.0", port=8000)
