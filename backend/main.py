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
    stock_quantity = Column(Integer, default=0)
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

class DBInvoice(Base):
    __tablename__ = "invoices"
    id = Column(Integer, primary_key=True, index=True)
    invoice_number = Column(String, unique=True, index=True)
    date_of_sale = Column(DateTime, default=datetime.utcnow)
    customer_name = Column(String)
    customer_phone = Column(String)
    item_name = Column(String)
    quantity = Column(Integer)
    unit_price = Column(Float)
    base_price = Column(Float)
    gst_percentage = Column(Float)
    gst_amount = Column(Float)
    total_price = Column(Float)

class DBCustomer(Base):
    __tablename__ = "customers"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    phone = Column(String, unique=True, index=True)
    email = Column(String, nullable=True)
    address = Column(String, nullable=True)
    gst_number = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

# Create tables
Base.metadata.create_all(bind=engine)

# Pydantic Models (API)
class UserBase(BaseModel):
    email: EmailStr
    full_name: str

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: int
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class ProductBase(BaseModel):
    name: str
    description: Optional[str] = None
    category: str
    unit_price: float
    stock_quantity: int
    min_stock_level: int = 5
    supplier_name: Optional[str] = None
    supplier_contact: Optional[str] = None

class ProductResponse(ProductBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class TransactionCreate(BaseModel):
    type: str
    party_name: str
    phone_number: str
    product_name: str
    quantity: float
    unit_price: float
    gst_percentage: float = 0.0
    date: Optional[datetime] = None

class TransactionResponse(BaseModel):
    id: int
    type: str
    party_name: str
    phone_number: str
    product_name: str
    quantity: float
    unit_price: float
    base_price: float
    gst_percentage: float
    gst_amount: float
    total_amount: float
    date: datetime
    invoice_number: Optional[str] = None

    class Config:
        from_attributes = True

class InvoiceResponse(BaseModel):
    invoice_number: str
    date_of_sale: datetime
    customer_name: str
    customer_phone: str
    item_name: str
    quantity: int
    unit_price: float
    base_price: float
    gst_percentage: float
    gst_amount: float
    total_price: float

    class Config:
        from_attributes = True

class StockChange(BaseModel):
    quantity_change: int

class CustomerBase(BaseModel):
    name: str
    phone: str
    email: Optional[str] = None
    address: Optional[str] = None
    gst_number: Optional[str] = None

class CustomerResponse(CustomerBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Auth Utilities
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login", auto_error=False)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    if not token:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None: raise Exception()
    except:
        raise HTTPException(status_code=401, detail="Could not validate credentials")
    
    user = db.query(DBUser).filter(DBUser.email == email).first()
    if user is None: raise HTTPException(status_code=401, detail="User not found")
    return user

# App Initialization
app = FastAPI(title="Agri Stock Manager Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health Check
@app.get("/health")
def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat(), "database": "connected"}

# Auth Endpoints
@app.post("/api/auth/signup")
async def signup(user: dict, db: Session = Depends(get_db)):
    print(f"DEBUG: signup data received: {user}")
    email = user.get("email")
    full_name = user.get("full_name")
    password = user.get("password")
    
    if not email or not password:
        raise HTTPException(status_code=400, detail="Email and password required")
        
    db_user = db.query(DBUser).filter(DBUser.email == email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
        
    try:
        hashed = pwd_context.hash(password)
        print(f"DEBUG: Password hashed. Length: {len(hashed)}")
    except Exception as e:
        print(f"DEBUG: Hashing failed: {e}")
        raise HTTPException(status_code=500, detail=f"Hashing error: {str(e)}")
        
    new_user = DBUser(email=email, full_name=full_name, hashed_password=hashed)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {
        "id": new_user.id,
        "email": new_user.email,
        "full_name": new_user.full_name,
        "is_active": new_user.is_active,
        "created_at": new_user.created_at.isoformat()
    }

@app.post("/api/auth/login")
async def login(data: dict, db: Session = Depends(get_db)):
    print(f"DEBUG: login attempt: {data.get('username')}")
    email = data.get("username") or data.get("email")
    password = data.get("password")
    if not email or not password:
        raise HTTPException(status_code=400, detail="Credentials required")
    user = db.query(DBUser).filter(DBUser.email == email).first()
    if not user:
        print(f"DEBUG: User not found: {email}")
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    
    if not pwd_context.verify(password, user.hashed_password):
        print(f"DEBUG: Password verification failed for: {email}")
        raise HTTPException(status_code=401, detail="Incorrect email or password")
        
    token = create_access_token(data={"sub": user.email})
    return {"access_token": token, "token_type": "bearer"}

@app.get("/api/auth/me", response_model=UserResponse)
def read_users_me(current_user: DBUser = Depends(get_current_user)):
    return current_user

# Product Endpoints
@app.get("/api/products/", response_model=List[ProductResponse])
def get_products(skip: int = 0, limit: int = 100, category: Optional[str] = None, search: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(DBProduct).filter(DBProduct.is_active == True)
    if category: query = query.filter(DBProduct.category == category)
    if search: query = query.filter(DBProduct.name.contains(search))
    return query.offset(skip).limit(limit).all()

@app.get("/api/products/categories")
def get_categories(db: Session = Depends(get_db)):
    categories = db.query(DBProduct.category).distinct().all()
    return {"categories": [c[0] for c in categories if c[0]]}

@app.get("/api/products/low-stock")
def get_low_stock(db: Session = Depends(get_db)):
    products = db.query(DBProduct).filter(DBProduct.stock_quantity <= DBProduct.min_stock_level).all()
    return [{"name": p.name, "quantity": p.stock_quantity} for p in products]

@app.post("/api/products/", response_model=ProductResponse)
def create_product(product: ProductBase, db: Session = Depends(get_db)):
    db_product = DBProduct(**product.dict())
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product

@app.get("/api/products/{product_id}", response_model=ProductResponse)
def get_product(product_id: int, db: Session = Depends(get_db)):
    product = db.query(DBProduct).filter(DBProduct.id == product_id).first()
    if not product: raise HTTPException(status_code=404, detail="Product not found")
    return product

@app.put("/api/products/{product_id}", response_model=ProductResponse)
def update_product(product_id: int, product_update: ProductBase, db: Session = Depends(get_db)):
    db_product = db.query(DBProduct).filter(DBProduct.id == product_id).first()
    if not db_product: raise HTTPException(status_code=404, detail="Product not found")
    for key, value in product_update.dict().items(): setattr(db_product, key, value)
    db.commit()
    db.refresh(db_product)
    return db_product

@app.delete("/api/products/{product_id}")
def delete_product(product_id: int, db: Session = Depends(get_db)):
    db_product = db.query(DBProduct).filter(DBProduct.id == product_id).first()
    if not db_product: raise HTTPException(status_code=404, detail="Product not found")
    db_product.is_active = False
    db.commit()
    return {"detail": "Product deleted"}

@app.patch("/api/products/{product_id}/stock")
def update_stock(product_id: int, stock_change: StockChange, db: Session = Depends(get_db)):
    db_product = db.query(DBProduct).filter(DBProduct.id == product_id).first()
    if not db_product: raise HTTPException(status_code=404, detail="Product not found")
    db_product.stock_quantity += stock_change.quantity_change
    db.commit()
    db.refresh(db_product)
    return {"product": db_product, "new_quantity": db_product.stock_quantity}

# Invoice Endpoints
@app.get("/api/invoices/", response_model=List[InvoiceResponse])
def get_invoices(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return db.query(DBInvoice).order_by(DBInvoice.date_of_sale.desc()).offset(skip).limit(limit).all()

@app.get("/api/invoices/number/{invoice_number}", response_model=InvoiceResponse)
def get_invoice_by_number(invoice_number: str, db: Session = Depends(get_db)):
    invoice = db.query(DBInvoice).filter(DBInvoice.invoice_number == invoice_number).first()
    if not invoice: raise HTTPException(status_code=404, detail="Invoice not found")
    return invoice

@app.post("/api/invoices/search", response_model=List[InvoiceResponse])
def search_invoices(data: dict, db: Session = Depends(get_db)):
    query_str = data.get("query", "")
    search_type = data.get("search_type", "customer")
    if search_type == "customer":
        return db.query(DBInvoice).filter(DBInvoice.customer_name.contains(query_str)).all()
    elif search_type == "phone":
        return db.query(DBInvoice).filter(DBInvoice.customer_phone.contains(query_str)).all()
    return db.query(DBInvoice).filter(DBInvoice.invoice_number.contains(query_str)).all()

@app.get("/api/invoices/today/", response_model=List[InvoiceResponse])
def get_today_invoices(db: Session = Depends(get_db)):
    today = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    return db.query(DBInvoice).filter(DBInvoice.date_of_sale >= today).all()

@app.get("/api/invoices/summary")
def get_invoice_summary(db: Session = Depends(get_db)):
    invoices = db.query(DBInvoice).all()
    return {
        "total_sales": sum(i.total_price for i in invoices),
        "total_gst_collected": sum(i.gst_amount for i in invoices),
        "total_invoices": len(invoices),
    }

# Customer Endpoints
@app.get("/api/customers/", response_model=List[CustomerResponse])
def get_customers(skip: int = 0, limit: int = 100, search: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(DBCustomer)
    if search:
        query = query.filter(DBCustomer.name.contains(search) | DBCustomer.phone.contains(search))
    return query.offset(skip).limit(limit).all()

@app.post("/api/customers/", response_model=CustomerResponse)
def create_customer(customer: CustomerBase, db: Session = Depends(get_db)):
    db_customer = db.query(DBCustomer).filter(DBCustomer.phone == customer.phone).first()
    if db_customer:
        raise HTTPException(status_code=400, detail="Customer with this phone already exists")
    
    new_customer = DBCustomer(**customer.dict())
    db.add(new_customer)
    db.commit()
    db.refresh(new_customer)
    return new_customer

# Transaction Endpoints
@app.get("/api/transactions/", response_model=List[TransactionResponse])
def get_transactions(skip: int = 0, limit: int = 100, transaction_type: Optional[str] = Query(None, alias="transaction_type"), search: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(DBTransaction)
    if transaction_type: query = query.filter(DBTransaction.type == transaction_type)
    if search: query = query.filter(DBTransaction.party_name.contains(search) | DBTransaction.product_name.contains(search))
    return query.order_by(DBTransaction.date.desc()).offset(skip).limit(limit).all()

@app.post("/api/transactions/", response_model=TransactionResponse)
def create_transaction(transaction: TransactionCreate, db: Session = Depends(get_db)):
    base_price = transaction.quantity * transaction.unit_price
    gst_amount = base_price * (transaction.gst_percentage / 100)
    total_amount = base_price + gst_amount
    inv_num = f"INV-{int(time.time())}"
    
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
            quantity=int(transaction.quantity),
            unit_price=transaction.unit_price,
            base_price=base_price,
            gst_percentage=transaction.gst_percentage,
            gst_amount=gst_amount,
            total_price=total_amount
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
