import os
import subprocess
import sys

def run_backend():
    print("🚀 Starting Agri Stock Manager Backend...")
    
    # Check if we are in the backend directory
    if not os.path.exists("main.py"):
        if os.path.exists("backend/main.py"):
            os.chdir("backend")
        else:
            print("❌ Error: main.py not found. Please run this script from the project root or backend directory.")
            return

    # Check for requirements
    print("📦 Checking dependencies...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
    except subprocess.CalledProcessError:
        print("⚠️ Warning: Failed to install some requirements. Trying to continue...")

    # Run the server
    print("\n✅ Backend is starting on http://0.0.0.0:8000")
    print("📝 API Docs: http://localhost:8000/docs\n")
    
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

if __name__ == "__main__":
    run_backend()
