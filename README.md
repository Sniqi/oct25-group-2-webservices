# DataOps & Cloud Architecture Project

This project demonstrates a modern DataOps infrastructure, simulated locally using Docker and Terraform, and prepared for future deployment to the AWS Cloud.

## Architecture

The infrastructure is fully managed as Code (IaC) using **Terraform** and runs locally within Docker containers.

### Components
*   **Web App (FastAPI)**: A Python-based REST API.
*   **Database (PostgreSQL)**: Persistent data storage for the app.
*   **Reverse Proxy (Nginx)**: Acts as an entrypoint and load balancer in front of the app.
*   **Monitoring (Prometheus)**: Collects metrics from the app (e.g., request rates).
*   **Visualization (Grafana)**: Dashboards for analyzing metrics.

### Data Flow
1.  User -> **Nginx** (Port 8080) -> **App**
2.  **App** -> **PostgreSQL** (Store/Read data)
3.  **Prometheus** -> **App** (Scrape metrics)
4.  User -> **Grafana** (Port 3000) -> **Prometheus** (Visualize data)

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
    *   **Web App**: [http://localhost:8080](http://localhost:8080)
    *   **DB Test**: [http://localhost:8080/db-test](http://localhost:8080/db-test) (Creates entries in the DB)
    *   **Prometheus**: [http://localhost:9090](http://localhost:9090)
    *   **Grafana**: [http://localhost:3000](http://localhost:3000) (Login: `admin` / `admin`)

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
│   │   ├── main.tf      # Definition of Docker Resources
│   │   ├── nginx.conf   # Load Balancer Config
│   │   └── prometheus.yml # Monitoring Config
│   └── aws/             # (Planned) AWS Configurations
└── .github/workflows/   # CI/CD Pipelines
```
