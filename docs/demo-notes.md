## Live demo

### A) AWS + kubectl; verify correct cluster; nodes are Ready
```powershell
aws sts get-caller-identity
aws eks update-kubeconfig --region eu-west-3 --name dataops-eks
kubectl config current-context

kubectl get ns
kubectl get nodes -o wide
```

### B) Verify dev resources
```powershell
kubectl -n dev get all
kubectl -n dev get ingress
kubectl -n dev get secret postgres-secret dataops-tls

kubectl -n staging get all
kubectl -n prod get all
```

### C) Start port-forward (run in background job)
```powershell
Get-Job -Name pf -ErrorAction SilentlyContinue | Remove-Job -ErrorAction SilentlyContinue
Start-Job -Name pf -ScriptBlock { kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8443:443 } | Out-Null
Start-Sleep -Seconds 2
Receive-Job -Name pf -Keep | Select-Object -First 3
```

### D) Prove App via HTTPS ingress
```powershell
curl -k https://dev.dataops.local:8443/health --resolve dev.dataops.local:8443:127.0.0.1
curl -k https://dev.dataops.local:8443/db-test --resolve dev.dataops.local:8443:127.0.0.1
```

### E) Failure injection: simulate pipeline shipping a bad image
Goal: show what happens when CI/CD promotes a broken image tag.

```powershell
kubectl -n dev set image deployment/dataops-app app=sniqi/dataops-demo:does-not-exist
kubectl -n dev get pods -l app=dataops-app
```

```powershell
curl -k https://dev.dataops.local:8443/health --resolve dev.dataops.local:8443:127.0.0.1
```

### F) Rollback: fast recovery
```powershell
kubectl -n dev rollout undo deployment/dataops-app
kubectl -n dev rollout status deployment/dataops-app --timeout=5s
kubectl -n dev get pods -l app=dataops-app
curl -k https://dev.dataops.local:8443/health --resolve dev.dataops.local:8443:127.0.0.1
```
