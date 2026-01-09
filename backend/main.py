import os
import time
from datetime import datetime, timedelta
from typing import List, Optional, Union

from fastapi import FastAPI, Depends, HTTPException, status, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr
from sqlalchemy import create_engine, Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Enum as SqlEnum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship
import enum
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-for-local-dev-12345")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 1 week

# Database setup - Using SQLite for local testing
# Database setup
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")

# Fallback to SQLite if no DATABASE_URL is provided
if not SQLALCHEMY_DATABASE_URL:
    SQLALCHEMY_DATABASE_URL = "sqlite:///./agri_stock.db"

# Handle PostgreSQL prefix fix if needed (for Render/Heroku)
if SQLALCHEMY_DATABASE_URL.startswith("postgres://"):
    SQLALCHEMY_DATABASE_URL = SQLALCHEMY_DATABASE_URL.replace("postgres://", "postgresql://", 1)

print(f"Connecting to database: {SQLALCHEMY_DATABASE_URL.split('@')[-1] if '@' in SQLALCHEMY_DATABASE_URL else 'sqlite'}")

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, 
    pool_pre_ping=True,  # Important for MySQL to handle lost connections
    connect_args={"check_same_thread": False} if SQLALCHEMY_DATABASE_URL.startswith("sqlite") else {}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Models (Database)
class DBUser(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    full_name = Column(String)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class DBProduct(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String, nullable=True)
    category = Column(String, index=True)
    unit_price = Column(Float)
    stock_quantity = Column(Float, default=0.0) # Changed to Float
    min_stock_level = Column(Integer, default=5)
    supplier_name = Column(String, nullable=True)
    supplier_contact = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, onupdate=datetime.utcnow)

class DBTransaction(Base):
    __tablename__ = "transactions"
    id = Column(Integer, primary_key=True, index=True)
    type = Column(String)  # 'sale' or 'purchase'
    party_name = Column(String)
    phone_number = Column(String)
    product_name = Column(String)
    quantity = Column(Float)
    unit_price = Column(Float)
    base_price = Column(Float)
    gst_percentage = Column(Float)
    gst_amount = Column(Float)
    total_amount = Column(Float)
    date = Column(DateTime, default=datetime.utcnow)
    invoice_number = Column(String, nullable=True)
    quantity_unit = Column(String, default="kg") # "kg" or "L"

class DBInvoice(Base):
    __tablename__ = "invoices"
    id = Column(Integer, primary_key=True, index=True)
    invoice_number = Column(String, unique=True, index=True)
    date_of_sale = Column(DateTime, default=datetime.utcnow)
    customer_name = Column(String)
    customer_phone = Column(String)
    item_name = Column(String)
    quantity = Column(Float) # Changed to Float
    unit_price = Column(Float)
    base_price = Column(Float)
    gst_percentage = Column(Float)
    gst_amount = Column(Float)
    total_price = Column(Float)
    quantity_unit = Column(String, default="kg")

# ... (DBCustomer remains same) ...

# ...

class ProductBase(BaseModel):
    name: str
    description: Optional[str] = None
    category: str
    unit_price: float
    stock_quantity: float # Changed to float
    min_stock_level: int = 5
    supplier_name: Optional[str] = None
    supplier_contact: Optional[str] = None

# ...

class InvoiceResponse(BaseModel):
    invoice_number: str
    date_of_sale: datetime
    customer_name: str
    customer_phone: str
    item_name: str
    quantity: float # Changed to float
    unit_price: float
    base_price: float
    gst_percentage: float
    gst_amount: float
    total_price: float
    quantity_unit: str = "kg"

    class Config:
        from_attributes = True

class StockChange(BaseModel):
    quantity_change: float # Changed to float

# ...

@app.post("/api/transactions/", response_model=TransactionResponse)
def create_transaction(transaction: TransactionCreate, db: Session = Depends(get_db)):
    base_price = transaction.quantity * transaction.unit_price
    gst_amount = base_price * (transaction.gst_percentage / 100)
    total_amount = base_price + gst_amount
    # Use milliseconds to prevent collision on rapid entries
    inv_num = f"INV-{int(time.time() * 1000)}" 
    
    db_transaction = DBTransaction(**transaction.dict(), base_price=base_price, gst_amount=gst_amount, total_amount=total_amount, invoice_number=inv_num)
    
    product = db.query(DBProduct).filter(DBProduct.name == transaction.product_name).first()
    if product:
        if transaction.type == "sale": product.stock_quantity -= transaction.quantity
        else: product.stock_quantity += transaction.quantity
        
    # Also create an Invoice record if it's a sale
    if transaction.type == "sale":
        db_invoice = DBInvoice(
            invoice_number=inv_num,
            date_of_sale=transaction.date or datetime.utcnow(),
            customer_name=transaction.party_name,
            customer_phone=transaction.phone_number,
            item_name=transaction.product_name,
            quantity=transaction.quantity, # Removed int casting
            unit_price=transaction.unit_price,
            base_price=base_price,
            gst_percentage=transaction.gst_percentage,
            gst_amount=gst_amount,
            total_price=total_amount,
            quantity_unit=transaction.quantity_unit
        )
        db.add(db_invoice)
        
        # AUTOMATIC CUSTOMER CREATION
        # Check if customer exists by phone
        existing_customer = db.query(DBCustomer).filter(DBCustomer.phone == transaction.phone_number).first()
        if not existing_customer:
            new_customer = DBCustomer(
                name=transaction.party_name,
                phone=transaction.phone_number
            )
            db.add(new_customer)
            print(f"DEBUG: Auto-created new customer: {transaction.party_name}")
    
    db.add(db_transaction)
    db.commit()
    db.refresh(db_transaction)
    return db_transaction

@app.get("/api/transactions/summary")
def get_summary(db: Session = Depends(get_db)):
    today = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    sales = db.query(DBTransaction).filter(DBTransaction.type == "sale", DBTransaction.date >= today).all()
    purchases = db.query(DBTransaction).filter(DBTransaction.type == "purchase", DBTransaction.date >= today).all()
    return {
        "today_sales_total": sum(t.total_amount for t in sales),
        "today_purchases_total": sum(t.total_amount for t in purchases),
        "today_sales_count": len(sales),
        "today_purchases_count": len(purchases)
    }

@app.get("/api/transactions/date-range/", response_model=List[TransactionResponse])
def get_transactions_by_date(start_date: str, end_date: str, db: Session = Depends(get_db)):
    try:
        start = datetime.fromisoformat(start_date.replace('Z', '').split('+')[0])
        end = datetime.fromisoformat(end_date.replace('Z', '').split('+')[0])
    except:
        raise HTTPException(status_code=400, detail="Invalid date format")
    return db.query(DBTransaction).filter(DBTransaction.date >= start, DBTransaction.date <= end).all()

@app.get("/api/customers/{phone}/transactions", response_model=List[TransactionResponse])
def get_customer_transactions(phone: str, db: Session = Depends(get_db)):
    return db.query(DBTransaction).filter(DBTransaction.phone_number == phone).order_by(DBTransaction.date.desc()).all()

@app.get("/api/dashboard/stats")
async def get_dashboard_stats(db: Session = Depends(get_db)):
    # Total products
    total_products = db.query(DBProduct).filter(DBProduct.is_active == True).count()
    
    # Low stock items
    low_stock_items = db.query(DBProduct).filter(
        DBProduct.is_active == True,
        DBProduct.stock_quantity <= DBProduct.min_stock_level
    ).count()
    
    # Low stock products list
    low_stock_list = db.query(DBProduct).filter(
        DBProduct.is_active == True,
        DBProduct.stock_quantity <= DBProduct.min_stock_level
    ).all()
    
    # Total Customers
    total_customers = db.query(DBCustomer).count()
    
    # Daily Transaction Summary
    today = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    sales = db.query(DBTransaction).filter(DBTransaction.type == "sale", DBTransaction.date >= today).all()
    purchases = db.query(DBTransaction).filter(DBTransaction.type == "purchase", DBTransaction.date >= today).all()
    
    # Total summary (for GST)
    all_invoices = db.query(DBInvoice).all()
    
    return {
        "total_products": total_products,
        "low_stock_items": low_stock_items,
        "total_customers": total_customers,
        "low_stock_products": [{"name": p.name, "quantity": p.stock_quantity} for p in low_stock_list],
        "today_sales_total": sum(t.total_amount for t in sales),
        "today_purchases_total": sum(t.total_amount for t in purchases),
        "total_sales": sum(t.total_amount for t in db.query(DBTransaction).filter(DBTransaction.type == "sale").all()),
        "total_gst_collected": sum(i.gst_amount for i in all_invoices)
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
