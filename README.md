# DataOps & Cloud Architecture Project

This project demonstrates a modern DataOps infrastructure with two deployment options:
1. **Local Docker (Terraform)** - Full observability stack for development
2. **Local Kubernetes (Minikube)** - Multi-environment orchestration demo

Originally designed for AWS Cloud deployment (EKS), now adapted for local demonstration.

## Architecture

The infrastructure is fully managed as Code (IaC) using **Terraform** (Docker) or **Kubernetes manifests** (Minikube).

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

## 🚀 Quick Start

### Choose Your Environment

**Option 1: Local Docker (Development & Monitoring)**
- Best for: Development, observability testing, load testing
- Includes: Full monitoring stack (Prometheus, Grafana, Loki)
- See: [Local Docker Setup](#local-docker-setup) below

**Option 2: Local Kubernetes (Demo & Orchestration)**
- Best for: Demo, multi-environment testing, K8s features
- Includes: 3 environments (dev/staging/prod), rollback, self-healing
- See: [docs/setup-minikube.md](docs/setup-minikube.md)

---

## Local Docker Setup

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

---

## Local Kubernetes Setup (Minikube)

For demonstrating Kubernetes orchestration, multi-environment deployments, and DevOps practices:

### Quick Start

1. **Setup cluster** (one-time):
   ```powershell
   # See detailed guide: docs/setup-minikube.md
   minikube start --cpus=4 --memory=8192 --driver=docker
   minikube addons enable ingress
   # ... follow full setup guide
   ```

2. **Start port-forward** (keep running in separate PowerShell window):
   ```powershell
   kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 443:443 80:80
   ```

3. **Run demo** (in another PowerShell window):
   ```powershell
   # See: docs/demo-notes-minikube.md
   kubectl -n dev get all
   curl -k https://dev.dataops.local/health
   ```

4. **Cleanup**:
   ```powershell
   ./scripts/cleanup-minikube.ps1
   ```

### Documentation

*   **[Setup Guide](docs/setup-minikube.md)** - Complete installation & configuration
*   **[Demo Script](docs/demo-notes-minikube.md)** - Live demo with failure injection & rollback
*   **[Cleanup Script](scripts/cleanup-minikube.ps1)** - Reset environment

### What's Included

✅ 3 isolated environments (dev, staging, prod)
✅ NGINX Ingress with TLS certificates
✅ PostgreSQL StatefulSets with persistent storage
✅ Secrets management for credentials
✅ Zero-downtime deployment protection
✅ Instant rollback capabilities
✅ Self-healing pods

---

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
*   **Orchestration**: Kubernetes (Minikube for local)
*   **Infrastructure as Code**: Terraform (Docker), Kubernetes Manifests
*   **CI/CD**: GitHub Actions
*   **Database**: PostgreSQL 15
*   **Observability**: Prometheus, Grafana, Loki
*   **Ingress**: NGINX Ingress Controller

## 📂 Project Structure

```text
.
├── app/                 # Source Code of the Python Application
│   ├── main.py          # API Logic & DB Models
│   ├── Dockerfile       # Container Definition
│   └── requirements.txt # Python Dependencies
├── infra/
│   ├── local/           # Terraform Configuration for Local Docker Environment
│   │   ├── config/      # Configuration files (nginx.conf, prometheus.yml, etc.)
│   │   ├── certs/       # SSL Certificates
│   │   ├── main.tf      # Provider & Network Definition
│   │   ├── app.tf       # App & Nginx Resources
│   │   ├── database.tf  # Database Resources
│   │   └── monitoring.tf # Observability Stack (Prometheus, Loki, etc.)
│   └── aws/             # (Planned) AWS Configurations
├── k8s/                 # Kubernetes Manifests for Minikube
│   ├── dev/             # Development environment
│   ├── staging/         # Staging environment
│   └── prod/            # Production environment
├── docs/                # Documentation
│   ├── setup-minikube.md       # Minikube setup guide
│   ├── demo-notes-minikube.md  # Local K8s demo script
│   └── demo-notes.md           # Original AWS EKS demo script
├── scripts/             # Maintenance & Cleanup Scripts
│   ├── backup.ps1       # Database backup
│   ├── restore.ps1      # Database restore
│   └── cleanup-minikube.ps1  # Minikube cleanup
├── tests/
│   └── load/            # Locust Load Testing Scenarios
└── .github/workflows/   # CI/CD Pipelines
```
