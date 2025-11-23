from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from prometheus_fastapi_instrumentator import Instrumentator # NEU
import os
import datetime
import time

app = FastAPI()

@app.get("/health")
def health_check():
    return {"status": "healthy"}

# Expose Prometheus metrics
Instrumentator().instrument(app).expose(app)
# -----------------------------------------

# Database Configuration
# These environment variables correspond to the configuration in infra/local/main.tf
DB_USER = os.getenv("DB_USER", "user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "password")
DB_HOST = os.getenv("DB_HOST", "localhost") # In Docker, this is the container name
DB_NAME = os.getenv("DB_NAME", "dbname")

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}"

# Retry logic for DB connection at startup
# Waits for the database container to be ready
engine = None
for i in range(10):
    try:
        engine = create_engine(DATABASE_URL)
        connection = engine.connect()
        connection.close()
        print("Database connection successful!")
        break
    except Exception as e:
        print(f"Waiting for database... ({i+1}/10)")
        time.sleep(2)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Database Model
class AccessLog(Base):
    __tablename__ = "access_logs"
    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    message = Column(String)

# Create tables
if engine:
    Base.metadata.create_all(bind=engine)

# Dependency Injection for DB Session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
def read_root():
    return {
        "message": "Hello from DataOps Project!",
        "environment": os.getenv("ENV", "local"),
        "db_status": "connected" if engine else "disconnected"
    }

@app.get("/db-test")
def test_db(db: Session = Depends(get_db)):
    if not engine:
        raise HTTPException(status_code=500, detail="Database not connected")

    # Create new entry
    new_log = AccessLog(message="API accessed")
    db.add(new_log)
    db.commit()

    # Read all entries
    logs = db.query(AccessLog).order_by(AccessLog.id.desc()).limit(5).all()
    return [{"id": l.id, "time": l.timestamp, "msg": l.message} for l in logs]
