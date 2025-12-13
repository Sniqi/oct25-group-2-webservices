# AWS EKS runbook (internal-only demo)

This repo provisions a single EKS cluster in `eu-west-3` and uses namespaces (`dev`, `staging`, `prod`) for environment separation.

## CI/CD deployment (recommended)

The CI pipeline pushes Docker images with:
- Moving tags: `dev-latest`, `staging-latest`, `latest`
- Immutable tag: `sha-<short>` (e.g. `sha-1a2b3c4`) for exact promotion

Deploy is handled by GitHub Actions:
- staging: workflow `Deploy (staging)` runs on pushes to the `staging` branch (or manually)
- prod: workflow `Deploy (prod)` is manual and should be protected by an approval rule (GitHub Environments)

### How to pick the `sha-...` image tag

The CI pipeline always pushes an immutable tag in the format `sha-<short>` where `<short>` is the first 7 chars of the git commit SHA.

Examples:
- If your commit is `1a2b3c4d5e...`, the image tag is `sha-1a2b3c4`.

Where to find it:
- In GitHub: use the commit SHA of the staging run you approved/promoted.
- Locally: `git rev-parse --short HEAD`

Promotion flow:
- Deploy to staging from the `staging` branch (auto) → that deploy uses `sha-${GITHUB_SHA::7}`.
- For prod: run `Deploy (prod)` and set `image_tag` to the exact staging tag you tested (e.g. `sha-1a2b3c4`).

Required GitHub secrets:
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

Recommended: Configure GitHub Environments `staging` and `prod`, and require reviewers for `prod`.

## Prereqs

- Terraform
- AWS CLI authenticated (see next section)
- `kubectl`
- `openssl` available in PATH (e.g. via Git for Windows or WSL)

## 0) Configure AWS credentials (required)

Terraform uses the normal AWS credential chain (same as the AWS CLI).

### Access keys (IAM user)

```bash
aws configure
```

If you prefer a named profile (recommended when you have multiple accounts):

```bash
aws configure --profile dataops
```

Set:
- **AWS Access Key ID** / **AWS Secret Access Key**
- **Default region name**: `eu-west-3`

Verify:

```bash
aws sts get-caller-identity
```

If you used a named profile:

```bash
aws sts get-caller-identity --profile dataops
```

```powershell
$env:AWS_PROFILE = "dataops"
```

## Note on networking (EIP quota)

This Terraform setup disables the NAT Gateway by default to avoid `AddressLimitExceeded`
Elastic IP quota errors. Because of that, the EKS cluster + node group are placed into
the public subnets so nodes can reach the EKS API and pull images.

## 1) Provision EKS (Terraform)

From the repo root:

```bash
cd infra/aws/dev
terraform init
terraform apply
```

## 2) Configure kubectl context

```bash
aws eks update-kubeconfig --region eu-west-3 --name dataops-eks
kubectl get nodes
```

## 3) Create namespaces

```bash
kubectl apply -f k8s/dev/00-namespace.yaml
kubectl apply -f k8s/staging/00-namespace.yaml
kubectl apply -f k8s/prod/00-namespace.yaml
```

## 4) Create required secrets (NOT committed to git)

### 4.1 Postgres password secret (per namespace)

```bash
kubectl -n dev create secret generic postgres-secret --from-literal=password='CHANGE_ME'
kubectl -n staging create secret generic postgres-secret --from-literal=password='CHANGE_ME'
kubectl -n prod create secret generic postgres-secret --from-literal=password='CHANGE_ME'
```

### 4.2 Self-signed TLS secret for Ingress (per namespace)

Create one cert that covers all three demo hostnames:

```bash
mkdir -p .tmp-tls
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout .tmp-tls/tls.key -out .tmp-tls/tls.crt -subj "/CN=prod.dataops.local" -addext "subjectAltName=DNS:dev.dataops.local,DNS:staging.dataops.local,DNS:prod.dataops.local"

```

Create the TLS secret in each namespace:

```bash
kubectl -n dev create secret tls dataops-tls --cert=.tmp-tls/tls.crt --key=.tmp-tls/tls.key
kubectl -n staging create secret tls dataops-tls --cert=.tmp-tls/tls.crt --key=.tmp-tls/tls.key
kubectl -n prod create secret tls dataops-tls --cert=.tmp-tls/tls.crt --key=.tmp-tls/tls.key
```

## 5) Deploy Postgres + app + ingress

IMPORTANT: in `k8s/*/20-app.yaml`, replace `DOCKER_USERNAME` with your Docker Hub username.
Note: Docker image names must be lowercase, otherwise Kubernetes can show `InvalidImageName`.

Image tags by environment:
- `dev` uses `:dev-latest`
- `staging` uses `:staging-latest`
- `prod` uses `:latest`

For a more robust promotion flow, deploy using the immutable SHA tag that CI always pushes (e.g. `:sha-<gitsha>`), then promote the *same* SHA from staging to prod.

```bash
kubectl -n dev apply -f k8s/dev/10-postgres.yaml
kubectl -n dev apply -f k8s/dev/20-app.yaml
kubectl -n dev apply -f k8s/dev/30-ingress.yaml

kubectl -n staging apply -f k8s/staging/10-postgres.yaml
kubectl -n staging apply -f k8s/staging/20-app.yaml
kubectl -n staging apply -f k8s/staging/30-ingress.yaml

kubectl -n prod apply -f k8s/prod/10-postgres.yaml
kubectl -n prod apply -f k8s/prod/20-app.yaml
kubectl -n prod apply -f k8s/prod/30-ingress.yaml
```

## 6) Demo access via port-forward (no public exposure)

Port-forward the ingress controller HTTPS port locally:

```bash
kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8443:443
```

Then call the API over HTTPS (curl example for `prod`):

```bash
curl -k https://prod.dataops.local:8443/health --resolve prod.dataops.local:8443:127.0.0.1
curl -k https://prod.dataops.local:8443/db-test --resolve prod.dataops.local:8443:127.0.0.1
```

To test `dev` / `staging`, swap the hostname accordingly.
