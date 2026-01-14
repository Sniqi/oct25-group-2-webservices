# Live Demo - Minikube (Local Kubernetes)

This demo showcases Kubernetes orchestration, failure injection, and rollback capabilities using a local Minikube cluster.

## Prerequisites

- Minikube cluster running with all environments deployed `minikube start --cpus=4 --memory=8192 --driver=docker`
- Port-forwarding active: `kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 443:443 80:80`

---

## A) Verify Minikube Cluster

```powershell
# Check cluster status
minikube status

# List namespaces
kubectl get ns

# Check nodes
kubectl get nodes -o wide
```

Expected output:
- Current context: `minikube`
- Namespaces: `dev`, `staging`, `prod`, `ingress-nginx`, etc.
- Node status: `Ready`

---

## B) Verify Multi-Environment Resources

```powershell
# Dev environment
kubectl -n dev get all
kubectl -n dev get ingress
kubectl -n dev get secret postgres-secret dataops-tls

# Staging environment
kubectl -n staging get all

# Prod environment
kubectl -n prod get all
```

Expected: Deployments, StatefulSets, Services, and Ingresses in all three environments.

---

## C) Verify HTTPS Access via Ingress

Test application endpoints through NGINX Ingress Controller:

```powershell
# Dev environment - Health check
curl -k https://dev.dataops.local/health

# Staging environment
curl -k https://staging.dataops.local/health

# Prod environment
curl -k https://prod.dataops.local/health

# Dev environment - Database test
curl -k https://dev.dataops.local/db-test
```

Expected response:
```json
{"status":"healthy","environment":"dev","database":"connected"}
```

**Note:** The `-k` flag accepts the self-signed certificate.

---

## D) Failure Injection: Simulate Bad Image Deployment

**Goal:** Show what happens when CI/CD promotes a broken Docker image.

### Inject Failure

Deploy a non-existent image to simulate a failed release:

```powershell
kubectl -n dev set image deployment/dataops-app app=sniqi/dataops-demo:does-not-exist
```

### Observe Failure

```powershell
# Watch pod status
kubectl -n dev get pods -l app=dataops-app -w
```

Expected: Pod shows `ImagePullBackOff` or `ErrImagePull` status.

### Test Service Availability

```powershell
# Attempt to access service
curl -k https://dev.dataops.local/health
```

**Key Point:** Service remains available! Kubernetes keeps old pods running when new ones fail. This demonstrates zero-downtime deployment protection.

---

## E) Rollback: Fast Recovery

**Goal:** Demonstrate Kubernetes' built-in rollback capability for instant recovery.

### Execute Rollback

```powershell
kubectl -n dev rollout undo deployment/dataops-app
```

### Monitor Rollback Progress

```powershell
kubectl -n dev rollout status deployment/dataops-app --timeout=30s
```

### Verify Recovery

```powershell
# Check pod status
kubectl -n dev get pods -l app=dataops-app

# Test service
curl -k https://dev.dataops.local/health
curl -k https://dev.dataops.local/db-test
```

Expected: Application is fully operational.

---

## F) Database Persistence

Show data persistence across pod restarts:

```powershell
# Create test data
curl -k https://dev.dataops.local/db-test

# Delete postgres pod
kubectl -n dev delete pod -l app=postgres

# Wait for new pod

# Verify data still exists
curl -k https://dev.dataops.local/db-test
```

## G) Scaling

Demonstrate horizontal scaling:

```powershell
# Scale up to 3 replicas
kubectl -n dev scale deployment/dataops-app --replicas=3

# Watch pods being created
kubectl -n dev get pods -l app=dataops-app -w

# Test App
curl -k https://dev.dataops.local/db-test

# Scale back down
kubectl -n dev scale deployment/dataops-app --replicas=1
```
