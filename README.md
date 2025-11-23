# DataOps & Cloud Architecture Project

This project demonstrates a modern DataOps infrastructure, simulated locally using Docker and Terraform, and prepared for future deployment to the AWS Cloud.

## Architecture

The infrastructure is fully managed as Code (IaC) using **Terraform** and runs locally within Docker containers.

### Components
*   **Web App (FastAPI)**: A Python-based REST API.
*   **Database (PostgreSQL)**: Persistent data storage for the app.
*   **Reverse Proxy (Nginx)**: Acts as an entrypoint and load balancer in front of the app.
*   **Monitoring (Prometheus)**: Collects metrics from the app (e.g., request rates).
*   **Alerting (Alertmanager)**: Manages alerts triggered by Prometheus.
*   **Logging (Loki & Promtail)**: Centralized log aggregation (Promtail collects, Loki stores).
*   **Visualization (Grafana)**: Dashboards for analyzing metrics and logs.
*   **Load Testing (Locust)**: Simulates user traffic to test system performance.

### Data Flow
1.  User -> **Nginx** (Port 8443 HTTPS) -> **App**
2.  **App** -> **PostgreSQL** (Store/Read data)
3.  **Prometheus** -> **App** (Scrape metrics)
4.  **Promtail** -> **Docker Socket** (Read logs) -> **Loki**
5.  User -> **Grafana** (Port 3000) -> **Prometheus/Loki** (Visualize metrics & logs)
6.  User -> **Locust** (Port 8089) -> **App** (Generate Load)

## 🚀 Quick Start (Local)

### Prerequisites
*   Docker Desktop installed & running
*   Terraform installed
*   Git installed

### Installation
1.  **Clone Repository**
    ```bash
    git clone <repo-url>
    cd oct25-group-2-webservices
    ```

2.  **Start Infrastructure**
    ```bash
    cd infra/local
    terraform init
    terraform apply
    # Confirm with 'yes'
    ```

3.  **Access**
    *   **Web App**: [https://localhost:8443](https://localhost:8443) (Accept self-signed cert warning)
    *   **DB Test**: [https://localhost:8443/db-test](https://localhost:8443/db-test) (Creates entries in the DB)
    *   **Prometheus**: [http://localhost:9090](http://localhost:9090)
    *   **Alertmanager**: [http://localhost:9093](http://localhost:9093)
    *   **Grafana**: [http://localhost:3000](http://localhost:3000) (Login: `admin` / `admin`)
    *   **Locust (Load Test)**: [http://localhost:8089](http://localhost:8089)

## 🧪 Load Testing & Maintenance

### Load Testing (Locust)
1.  Open [http://localhost:8089](http://localhost:8089).
2.  Enter number of users (e.g., 50) and spawn rate (e.g., 5).
3.  Host is pre-configured as `http://dataops-nginx:80`.
4.  Click **Start Swarming** to simulate traffic.

### Backup & Restore
PowerShell scripts are available in `scripts/` to manage the database.

*   **Backup**:
    ```powershell
    ./scripts/backup.ps1
    ```
    Creates a SQL dump in the `backups/` folder.

*   **Restore**:
    ```powershell
    ./scripts/restore.ps1 -BackupFile backups/backup-YYYYMMDD-HHMMSS.sql
    ```
    Restores the database from a specific file.

## 🔄 CI/CD Pipeline (GitHub Actions)

The project uses an automated pipeline (`.github/workflows/ci.yml`) triggered by every push to the `dev`, `staging`, or `main` branches.

1.  **Build**: Creates a Docker Image from the `app/` folder.
2.  **Push**: Uploads the image to Docker Hub.
    *   Branch `dev` -> Tag `dev-latest`
    *   Branch `staging` -> Tag `staging-latest`
    *   Branch `main` -> Tag `latest`

## 🛠 Tech Stack

*   **Application**: Python, FastAPI, SQLAlchemy
*   **Containerization**: Docker
*   **Infrastructure as Code**: Terraform
*   **CI/CD**: GitHub Actions
*   **Database**: PostgreSQL 15
*   **Observability**: Prometheus, Grafana

## 📂 Project Structure

```text
.
├── app/                 # Source Code of the Python Application
│   ├── main.py          # API Logic & DB Models
│   ├── Dockerfile       # Container Definition
│   └── requirements.txt # Python Dependencies
├── infra/
│   ├── local/           # Terraform Configuration for Local Environment
│   │   ├── config/      # Configuration files (nginx.conf, prometheus.yml, etc.)
│   │   ├── certs/       # SSL Certificates
│   │   ├── main.tf      # Provider & Network Definition
│   │   ├── app.tf       # App & Nginx Resources
│   │   ├── database.tf  # Database Resources
│   │   └── monitoring.tf # Observability Stack (Prometheus, Loki, etc.)
│   └── aws/             # (Planned) AWS Configurations
├── scripts/             # Maintenance Scripts (Backup/Restore)
├── tests/
│   └── load/            # Locust Load Testing Scenarios
└── .github/workflows/   # CI/CD Pipelines
```
