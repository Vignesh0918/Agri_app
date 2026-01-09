import os
import time
from datetime import datetime, timedelta
from typing import List, Optional, Union
import pytz

# Timezone Configuration
IST = pytz.timezone('Asia/Kolkata')

def get_ist_time():
    return datetime.now(IST)

def get_today_start():
    now = get_ist_time()
    return now.replace(hour=0, minute=0, second=0, microsecond=0)

from fastapi import FastAPI, Depends, HTTPException, status, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr
from sqlalchemy import create_engine, Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Enum as SqlEnum, func
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

# --- Models (Database) ---

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
    stock_quantity = Column(Float, default=0.0)
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
    quantity = Column(Float)
    unit_price = Column(Float)
    base_price = Column(Float)
    gst_percentage = Column(Float)
    gst_amount = Column(Float)
    total_price = Column(Float)
    quantity_unit = Column(String, default="kg") # "kg" or "L"

class DBCustomer(Base):
    __tablename__ = "customers"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    phone = Column(String, unique=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

# Create tables
Base.metadata.create_all(bind=engine)

# --- Pydantic Models (Schemas) ---

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

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class ProductBase(BaseModel):
    name: str
    description: Optional[str] = None
    category: str
    unit_price: float
    stock_quantity: float
    min_stock_level: int = 5
    supplier_name: Optional[str] = None
    supplier_contact: Optional[str] = None

class ProductCreate(ProductBase):
    pass

class ProductResponse(ProductBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    class Config:
        from_attributes = True

class TransactionCreate(BaseModel):
    type: str # 'sale' or 'purchase'
    party_name: str
    phone_number: str
    product_name: str
    quantity: float
    unit_price: float
    gst_percentage: float = 0.0
    date: Optional[datetime] = None
    quantity_unit: str = "kg"

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
    quantity_unit: str = "kg"
    class Config:
        from_attributes = True

class InvoiceResponse(BaseModel):
    invoice_number: str
    date_of_sale: datetime
    customer_name: str
    customer_phone: str
    item_name: str
    quantity: float
    unit_price: float
    base_price: float
    gst_percentage: float
    gst_amount: float
    total_price: float
    quantity_unit: str = "kg"
    class Config:
        from_attributes = True

class StockChange(BaseModel):
    quantity_change: float

class LoginRequest(BaseModel):
    username: str
    password: str

# --- FastAPI Initialization ---

app = FastAPI(title="Agri Stock Manager API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

pwd_context = CryptContext(schemes=["bcrypt", "pbkdf2_sha256", "sha256_crypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

# --- Helper Functions ---

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def verify_password(plain_password, hashed_password):
    try:
        # Passlib has issues with bcrypt on Python 3.13 for passwords > 72 bytes
        # or sometimes wrongly reporting the length.
        
        # If the hash starts with $2b$ (bcrypt), we can try direct bcrypt first
        if isinstance(hashed_password, str) and hashed_password.startswith('$2b$'):
            import bcrypt
            try:
                if bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8')):
                    return True
            except Exception:
                pass # Fallback to passlib
                
        return pwd_context.verify(plain_password, hashed_password)
    except ValueError as e:
        # Handle the specific bcrypt 72-byte limit error
        if "72 bytes" in str(e):
            import bcrypt
            # Bcrypt ignores everything after 72 bytes anyway
            truncated_password = plain_password.encode('utf-8')[:72]
            try:
                return bcrypt.checkpw(truncated_password, hashed_password.encode('utf-8'))
            except:
                return False
        return False
    except Exception as e:
        print(f"DEBUG: Unknown verification error: {str(e)}")
        return False

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        token_data = TokenData(email=email)
    except JWTError:
        raise credentials_exception
    user = db.query(DBUser).filter(DBUser.email == token_data.email).first()
    if user is None:
        raise credentials_exception
    return user

# --- Auth Routes ---

@app.post("/api/auth/signup", response_model=UserResponse)
def signup(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(DBUser).filter(DBUser.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    hashed_password = get_password_hash(user.password)
    new_user = DBUser(
        email=user.email,
        full_name=user.full_name,
        hashed_password=hashed_password
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.post("/api/auth/login")
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    print(f"DEBUG: Login attempt for: {request.username}")
    user = db.query(DBUser).filter(func.lower(DBUser.email) == func.lower(request.username)).first()
    if not user:
        print(f"DEBUG: User not found: {request.username}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    try:
        is_valid = verify_password(request.password, user.hashed_password)
        if not is_valid:
            print(f"DEBUG: Invalid password for user: {request.username}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except Exception as e:
        print(f"DEBUG: Error during password verification: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Verification error: {str(e)}")

    print(f"DEBUG: Login successful for: {request.username}")
    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer", "full_name": user.full_name}

@app.get("/api/auth/me", response_model=UserResponse)
async def read_users_me(current_user: DBUser = Depends(get_current_user)):
    return current_user

# --- Product Routes ---

@app.get("/api/products/", response_model=List[ProductResponse])
def get_products(
    skip: int = 0, 
    limit: int = 100, 
    category: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(DBProduct).filter(DBProduct.is_active == True)
    if category:
        query = query.filter(DBProduct.category == category)
    if search:
        query = query.filter(DBProduct.name.ilike(f"%{search}%"))
    return query.offset(skip).limit(limit).all()

@app.post("/api/products/", response_model=ProductResponse)
def create_product(product: ProductCreate, db: Session = Depends(get_db)):
    db_product = DBProduct(**product.dict())
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product

@app.get("/api/products/categories")
def get_categories(db: Session = Depends(get_db)):
    categories = db.query(DBProduct.category).distinct().all()
    return {"categories": [c[0] for c in categories if c[0]]}

@app.get("/api/products/low-stock")
def get_low_stock(db: Session = Depends(get_db)):
    products = db.query(DBProduct).filter(
        DBProduct.is_active == True,
        DBProduct.stock_quantity <= DBProduct.min_stock_level
    ).all()
    return [{"name": p.name, "quantity": p.stock_quantity} for p in products]

@app.get("/api/products/{product_id}", response_model=ProductResponse)
def get_product(product_id: int, db: Session = Depends(get_db)):
    product = db.query(DBProduct).filter(DBProduct.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product

@app.put("/api/products/{product_id}", response_model=ProductResponse)
def update_product(product_id: int, product_update: ProductCreate, db: Session = Depends(get_db)):
    db_product = db.query(DBProduct).filter(DBProduct.id == product_id).first()
    if not db_product:
        raise HTTPException(status_code=404, detail="Product not found")
    for var, value in vars(product_update).items():
        setattr(db_product, var, value)
    db.commit()
    db.refresh(db_product)
    return db_product

@app.patch("/api/products/{product_id}/stock")
def update_stock(product_id: int, change: StockChange, db: Session = Depends(get_db)):
    db_product = db.query(DBProduct).filter(DBProduct.id == product_id).first()
    if not db_product:
        raise HTTPException(status_code=404, detail="Product not found")
    db_product.stock_quantity += change.quantity_change
    db.commit()
    return {"status": "success", "product": db_product}

# --- Transaction Routes ---

@app.post("/api/transactions/", response_model=TransactionResponse)
def create_transaction(transaction: TransactionCreate, db: Session = Depends(get_db)):
    # 1. Calculate Amounts
    base_price = transaction.quantity * transaction.unit_price
    gst_amount = base_price * (transaction.gst_percentage / 100)
    total_amount = base_price + gst_amount
    
    # 2. Generate Invoice Number (Unique Millisecond ID)
    inv_num = f"INV-{int(datetime.now().timestamp() * 1000)}" 
    
    # 3. Handle Date (Use IST if not provided)
    txn_date = transaction.date if transaction.date else get_ist_time()
    if txn_date.tzinfo is not None:
        txn_date = txn_date.astimezone(IST).replace(tzinfo=None)
    
    # 4. Create Transaction Record
    db_transaction = DBTransaction(
        **transaction.dict(exclude={'date'}),
        date=txn_date,
        base_price=base_price, 
        gst_amount=gst_amount, 
        total_amount=total_amount, 
        invoice_number=inv_num
    )
    
    # 5. Update Stock
    product = db.query(DBProduct).filter(DBProduct.name == transaction.product_name).first()
    if product:
        if transaction.type == "sale": 
            product.stock_quantity -= transaction.quantity
        else: 
            product.stock_quantity += transaction.quantity
        db.add(product)
    
    # 6. Create Invoice (Sales only)
    if transaction.type == "sale":
        db_invoice = DBInvoice(
            invoice_number=inv_num,
            date_of_sale=txn_date,
            customer_name=transaction.party_name,
            customer_phone=transaction.phone_number,
            item_name=transaction.product_name,
            quantity=transaction.quantity,
            unit_price=transaction.unit_price,
            base_price=base_price,
            gst_percentage=transaction.gst_percentage,
            gst_amount=gst_amount,
            total_price=total_amount,
            quantity_unit=transaction.quantity_unit
        )
        db.add(db_invoice)
        
        # 7. Auto-Create Customer
        existing_customer = db.query(DBCustomer).filter(DBCustomer.phone == transaction.phone_number).first()
        if not existing_customer:
            new_customer = DBCustomer(
                name=transaction.party_name,
                phone=transaction.phone_number,
                created_at=txn_date
            )
            db.add(new_customer)

    try:
        db.add(db_transaction)
        db.commit()
        db.refresh(db_transaction)
        return db_transaction
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Transaction failed: {str(e)}")

@app.get("/api/transactions/summary")
def get_summary(db: Session = Depends(get_db)):
    today_start = get_today_start()
    sales = db.query(DBTransaction).filter(DBTransaction.type == "sale", DBTransaction.date >= today_start).all()
    purchases = db.query(DBTransaction).filter(DBTransaction.type == "purchase", DBTransaction.date >= today_start).all()
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

# --- Dashboard & Reports ---

@app.get("/api/dashboard/stats")
async def get_dashboard_stats(db: Session = Depends(get_db)):
    # Total distinct active products
    total_products = db.query(DBProduct).filter(DBProduct.is_active == True).count()
    
    # Total stock quantity (sum of all product quantities)
    total_stock_quantity = db.query(func.sum(DBProduct.stock_quantity)).filter(DBProduct.is_active == True).scalar() or 0.0
    
    # Low stock items count
    low_stock_items = db.query(DBProduct).filter(
        DBProduct.is_active == True,
        DBProduct.stock_quantity <= DBProduct.min_stock_level
    ).count()
    
    # Total Customers
    total_customers = db.query(DBCustomer).count()
    
    # Today's stats
    today_start = get_today_start()
    sales = db.query(DBTransaction).filter(DBTransaction.type == "sale", DBTransaction.date >= today_start).all()
    purchases = db.query(DBTransaction).filter(DBTransaction.type == "purchase", DBTransaction.date >= today_start).all()
    
    # Overall summary
    all_sales = db.query(DBTransaction).filter(DBTransaction.type == "sale").all()
    all_invoices = db.query(DBInvoice).all()
    
    return {
        "total_products": total_products,
        "total_stock": float(total_products),  # Use count instead of sum as requested
        "total_stock_quantity": total_stock_quantity, # Keep the sum for other uses
        "low_stock_items": low_stock_items,
        "total_customers": total_customers,
        "today_sales_total": sum((t.total_amount or 0.0) for t in sales),
        "today_purchases_total": sum((t.total_amount or 0.0) for t in purchases),
        "total_sales": sum((t.total_amount or 0.0) for t in all_sales),
        "total_gst_collected": sum((i.gst_amount or 0.0) for i in all_invoices),
        "total_invoices": len(all_invoices)
    }

@app.get("/api/transactions/", response_model=List[TransactionResponse])
def get_all_transactions(skip: int = 0, limit: int = 100, transaction_type: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(DBTransaction)
    if transaction_type:
        query = query.filter(DBTransaction.type == transaction_type)
    return query.order_by(DBTransaction.date.desc()).offset(skip).limit(limit).all()

@app.get("/api/customers/{phone}/transactions", response_model=List[TransactionResponse])
def get_customer_transactions(phone: str, db: Session = Depends(get_db)):
    return db.query(DBTransaction).filter(DBTransaction.phone_number == phone).order_by(DBTransaction.date.desc()).all()

@app.get("/api/invoices/", response_model=List[InvoiceResponse])
def get_invoices(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return db.query(DBInvoice).order_by(DBInvoice.date_of_sale.desc()).offset(skip).limit(limit).all()

@app.get("/api/invoices/summary")
def get_invoice_summary(db: Session = Depends(get_db)):
    all_invoices = db.query(DBInvoice).all()
    return {
        "total_sales": sum((i.total_price or 0.0) for i in all_invoices),
        "total_gst_collected": sum((i.gst_amount or 0.0) for i in all_invoices),
        "total_invoices": len(all_invoices)
    }

@app.get("/api/invoices/number/{invoice_number}", response_model=InvoiceResponse)
def get_invoice_by_num(invoice_number: str, db: Session = Depends(get_db)):
    invoice = db.query(DBInvoice).filter(DBInvoice.invoice_number == invoice_number).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
    return invoice

@app.post("/api/invoices/search", response_model=List[InvoiceResponse])
def search_invoices(search_data: dict, db: Session = Depends(get_db)):
    query_str = search_data.get("query", "")
    search_type = search_data.get("search_type", "customer")
    
    query = db.query(DBInvoice)
    if search_type == "customer":
        query = query.filter(DBInvoice.customer_name.ilike(f"%{query_str}%"))
    elif search_type == "invoice_number":
        query = query.filter(DBInvoice.invoice_number.ilike(f"%{query_str}%"))
    
    return query.all()

@app.get("/api/invoices/today/", response_model=List[InvoiceResponse])
def get_today_invoices(db: Session = Depends(get_db)):
    today_start = get_today_start()
    return db.query(DBInvoice).filter(DBInvoice.date_of_sale >= today_start).all()

@app.get("/api/customers/", response_model=List[dict])
def get_customers(db: Session = Depends(get_db)):
    customers = db.query(DBCustomer).all()
    return [{"id": c.id, "name": c.name, "phone": c.phone} for c in customers]

@app.get("/health")
def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
