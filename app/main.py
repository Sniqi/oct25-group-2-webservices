from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from prometheus_fastapi_instrumentator import Instrumentator
import os
import datetime
import time

app = FastAPI()

# Expose Prometheus metrics
Instrumentator().instrument(app).expose(app)

# Database Configuration
DB_USER = os.getenv("DB_USER", "user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "password")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "dbname")

# HIER DIE ÄNDERUNG: Prüfen ob DATABASE_URL direkt gesetzt ist
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}"

engine = None

# SQLite benötigt spezielle Argumente für Multithreading
connect_args = {"check_same_thread": False} if "sqlite" in DATABASE_URL else {}

# Retry logic (nur sinnvoll für Netzwerk-DBs wie Postgres)
if "sqlite" in DATABASE_URL:
    engine = create_engine(DATABASE_URL, connect_args=connect_args)
    print("Using SQLite database for testing.")
else:
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

class AccessLog(Base):
    __tablename__ = "access_logs"
    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    message = Column(String)

# Create tables if engine exists
if engine:
    Base.metadata.create_all(bind=engine)

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

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/db-test")
def test_db(db: Session = Depends(get_db)):
    if not engine:
        raise HTTPException(status_code=500, detail="Database not connected")

    new_log = AccessLog(message="API accessed")
    db.add(new_log)
    db.commit()

    logs = db.query(AccessLog).order_by(AccessLog.id.desc()).limit(5).all()
    return [{"id": l.id, "time": l.timestamp, "msg": l.message} for l in logs]
