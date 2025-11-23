from fastapi import FastAPI
import os

app = FastAPI()

@app.get("/")
def read_root():
    return {
        "message": "Hello from DataOps Project!",
        "environment": os.getenv("ENV", "local"),
        "version": "1.0.0"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}
