# Verwende ein offizielles Python Runtime Image als Basis
FROM python:3.9-slim

# Arbeitsverzeichnis im Container setzen
WORKDIR /app

# Abhängigkeiten kopieren und installieren
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Den Rest des App-Codes kopieren
COPY . .

# Port 8000 freigeben
EXPOSE 8000

# Befehl zum Starten der App
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
