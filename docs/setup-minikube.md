# Minikube Setup Guide

This guide sets up a local Kubernetes cluster using Minikube to replicate the AWS EKS demo environment.

## Prerequisites

- Docker Desktop installed and running
- PowerShell with Administrator privileges
- 4+ CPU cores and 8+ GB RAM available

## Step 1: Install Minikube

If not already installed:

```powershell
# Using Chocolatey
choco install minikube

# Or download from: https://minikube.sigs.k8s.io/docs/start/
```

Verify installation:
```powershell
minikube version
```

## Step 2: Start Minikube Cluster

**Important:** Ensure Docker Desktop is running before proceeding.

```powershell
# Verify Docker is running
docker version

# If Docker is not running, start Docker Desktop and wait ~30 seconds
# Then verify again: docker version
```

Start cluster with sufficient resources:

```powershell
minikube start --cpus=4 --memory=8192 --driver=docker
```

Enable required addons:

```powershell
minikube addons enable ingress
minikube addons enable metrics-server
```

Wait for ingress controller to be ready (~1-2 minutes):

```powershell
kubectl wait --namespace ingress-nginx `
  --for=condition=ready pod `
  --selector=app.kubernetes.io/component=controller `
  --timeout=120s
```

## Step 3: Create Namespaces

Apply namespace manifests:

```powershell
kubectl apply -f k8s/dev/00-namespace.yaml
kubectl apply -f k8s/staging/00-namespace.yaml
kubectl apply -f k8s/prod/00-namespace.yaml
```

## Step 4: Create Secrets

### PostgreSQL Secrets

Create database credentials in all namespaces:

```powershell
# Set your password
$DB_PASSWORD = "your-secure-password"

# Create secrets
kubectl create secret generic postgres-secret --from-literal=password=$DB_PASSWORD -n dev
kubectl create secret generic postgres-secret --from-literal=password=$DB_PASSWORD -n staging
kubectl create secret generic postgres-secret --from-literal=password=$DB_PASSWORD -n prod
```

### TLS Secrets

Create TLS certificates using existing certs (or generate new ones):

```powershell
# Using existing certificates from local Docker setup
kubectl create secret tls dataops-tls `
  --cert=infra/local/certs/nginx.crt `
  --key=infra/local/certs/nginx.key `
  -n dev

kubectl create secret tls dataops-tls `
  --cert=infra/local/certs/nginx.crt `
  --key=infra/local/certs/nginx.key `
  -n staging

kubectl create secret tls dataops-tls `
  --cert=infra/local/certs/nginx.crt `
  --key=infra/local/certs/nginx.key `
  -n prod
```

## Step 5: Deploy Applications

Deploy all three environments:

```powershell
# Dev environment
kubectl apply -f k8s/dev/

# Staging environment
kubectl apply -f k8s/staging/

# Prod environment
kubectl apply -f k8s/prod/
```

Wait for deployments to be ready:

```powershell
kubectl wait --for=condition=available --timeout=300s deployment/dataops-app -n dev
kubectl wait --for=condition=available --timeout=300s deployment/dataops-app -n staging
kubectl wait --for=condition=available --timeout=300s deployment/dataops-app -n prod
```

## Step 6: Configure Network Access

### Port-Forward to Ingress Controller

Open a new PowerShell window and run:

```powershell
kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 443:443 80:80
```

**Important:** Leave this window open. Port-forwarding must stay active to access services.

**Note on Service Type:** The ingress-nginx-controller is typically NodePort by default. You can optionally patch it to LoadBalancer for consistency:

```powershell
kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec": {"type": "LoadBalancer"}}'
```

This is not required for port-forwarding to work.

### Configure Hosts File

Add DNS entries to your hosts file:

**Location:** `C:\Windows\System32\drivers\etc\hosts`

Add these lines:

```
127.0.0.1 dev.dataops.local
127.0.0.1 staging.dataops.local
127.0.0.1 prod.dataops.local
```

**PowerShell command (run as Administrator):**

```powershell
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "`n127.0.0.1 dev.dataops.local`n127.0.0.1 staging.dataops.local`n127.0.0.1 prod.dataops.local"
```

## Step 7: Verify Setup

Check cluster status:

```powershell
kubectl config current-context  # Should show "minikube"
kubectl get nodes -o wide
kubectl get ns
```

Check deployments in all environments:

```powershell
kubectl -n dev get all
kubectl -n staging get all
kubectl -n prod get all
```

Check ingress resources:

```powershell
kubectl -n dev get ingress
kubectl -n staging get ingress
kubectl -n prod get ingress
```

Test HTTPS access:

```powershell
curl -k https://dev.dataops.local/health
curl -k https://staging.dataops.local/health
curl -k https://prod.dataops.local/health
```

Expected response: `{"status":"healthy","environment":"dev","database":"connected"}`

## Troubleshooting

### Port-Forward Errors

**Problem:** `error starting port-forward` or permission denied

**Solution:**
1. Ensure you're not running as Administrator (regular user is fine)
2. Run the port-forward command in a standard PowerShell window
3. If port 443 is in use, try forwarding to a different port:
   ```powershell
   kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8443:443 80:8080
   ```
   Then use `curl -k https://dev.dataops.local:8443/health --resolve dev.dataops.local:8443:127.0.0.1`

### Minikube Tunnel Issues (Alternative Method)

**Problem:** SSH tunnel errors like `exec: "ssh": executable file not found`

This occurs on Windows when SSH is not available. Solutions:

1. **Use port-forward instead** (recommended) - See Port-Forward section above
2. **Install SSH:**
   ```powershell
   choco install git  # Includes Git Bash with SSH
   # or
   choco install openssh
   ```
   Then retry: `minikube tunnel`

### Docker not running
```
Error: "The system cannot find the file specified" or "docker version exit status 1"
```

**Solution:**
1. Start Docker Desktop from Windows Start Menu
2. Wait 30-60 seconds for Docker to fully start
3. Verify: `docker version` should show client and server versions
4. Retry: `minikube start --cpus=4 --memory=8192 --driver=docker`

### Ingress not working
```powershell
# Check ingress controller status
kubectl get pods -n ingress-nginx

# Restart ingress addon if needed
minikube addons disable ingress
minikube addons enable ingress
```

### Tunnel not routing traffic
```powershell
# Verify tunnel is running with admin privileges
# Check tunnel status
minikube tunnel --cleanup

# Restart tunnel
minikube tunnel
```

### Pods not starting (ImagePullBackOff)
```powershell
# Check pod status
kubectl -n dev describe pod <pod-name>

# Verify Docker Hub images are accessible
docker pull sniqi/dataops-demo:dev-latest
```

### Database connection issues
```powershell
# Check postgres pod logs
kubectl -n dev logs -l app=postgres

# Verify secret exists
kubectl -n dev get secret postgres-secret
```

## Next Steps

Once setup is complete, proceed to [demo-notes-minikube.md](demo-notes-minikube.md) to run the demo.

To cleanup the environment, see [cleanup-minikube.ps1](../scripts/cleanup-minikube.ps1).
