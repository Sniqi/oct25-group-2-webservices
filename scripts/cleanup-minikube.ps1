# Minikube Cleanup Script
# This script cleans up the local Kubernetes environment

Write-Host "=== Minikube Cleanup ===" -ForegroundColor Cyan

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Warn if not running as admin
if (-not (Test-Administrator)) {
    Write-Host "⚠️  Not running as Administrator. Some operations may require elevated privileges." -ForegroundColor Yellow
}

# Step 1: Delete Kubernetes resources
Write-Host "`n1. Deleting Kubernetes namespaces and resources..." -ForegroundColor Green

$namespaces = @("dev", "staging", "prod")
foreach ($ns in $namespaces) {
    $exists = kubectl get namespace $ns --ignore-not-found
    if ($exists) {
        Write-Host "   Deleting namespace: $ns" -ForegroundColor Gray
        kubectl delete namespace $ns --timeout=60s
    }
}

# Step 2: Stop kubectl port-forward processes
Write-Host "`n2. Checking for running port-forward processes..." -ForegroundColor Green

$pfProcesses = Get-Process -Name "kubectl" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*port-forward*" }
if ($pfProcesses) {
    Write-Host "   Found port-forward processes. Stopping..." -ForegroundColor Gray
    $pfProcesses | Stop-Process -Force
    Write-Host "   ✓ Port-forward processes stopped" -ForegroundColor Gray
} else {
    Write-Host "   No port-forward processes found" -ForegroundColor Gray
}

# Also check for minikube tunnel (alternative)
$tunnelProcesses = Get-Process -Name "minikube" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*tunnel*" }
if ($tunnelProcesses) {
    Write-Host "   Found minikube tunnel processes. Stopping..." -ForegroundColor Gray
    $tunnelProcesses | Stop-Process -Force
    Write-Host "   ✓ Tunnel processes stopped" -ForegroundColor Gray
}

# Step 3: Stop minikube cluster
Write-Host "`n3. Stopping minikube cluster..." -ForegroundColor Green

$minikubeStatus = minikube status --format='{{.Host}}' 2>$null
if ($minikubeStatus -eq "Running") {
    minikube stop
    Write-Host "   ✓ Cluster stopped" -ForegroundColor Gray
} else {
    Write-Host "   Cluster is not running" -ForegroundColor Gray
}

# Step 4: Delete minikube cluster (optional)
Write-Host "`n4. Do you want to DELETE the entire minikube cluster?" -ForegroundColor Yellow
Write-Host "   This will remove all data and require full setup again." -ForegroundColor Yellow
$deleteCluster = Read-Host "   Delete cluster? (y/N)"

if ($deleteCluster -eq "y" -or $deleteCluster -eq "Y") {
    Write-Host "   Deleting minikube cluster..." -ForegroundColor Gray
    minikube delete
    Write-Host "   ✓ Cluster deleted" -ForegroundColor Gray
} else {
    Write-Host "   Cluster preserved (use 'minikube start' to restart)" -ForegroundColor Gray
}

# Step 5: Hosts file cleanup instructions
Write-Host "`n5. Hosts file cleanup" -ForegroundColor Green
Write-Host "   The following entries should be removed from your hosts file:" -ForegroundColor Gray
Write-Host "   Location: C:\Windows\System32\drivers\etc\hosts" -ForegroundColor Gray
Write-Host ""
Write-Host "   127.0.0.1 dev.dataops.local" -ForegroundColor DarkGray
Write-Host "   127.0.0.1 staging.dataops.local" -ForegroundColor DarkGray
Write-Host "   127.0.0.1 prod.dataops.local" -ForegroundColor DarkGray
Write-Host ""

if (Test-Administrator) {
    $removeHosts = Read-Host "   Remove hosts file entries automatically? (y/N)"
    if ($removeHosts -eq "y" -or $removeHosts -eq "Y") {
        $hostsPath = "C:\Windows\System32\drivers\etc\hosts"
        $hostsContent = Get-Content $hostsPath
        $newContent = $hostsContent | Where-Object {
            $_ -notmatch "dev\.dataops\.local" -and
            $_ -notmatch "staging\.dataops\.local" -and
            $_ -notmatch "prod\.dataops\.local"
        }
        $newContent | Set-Content $hostsPath
        Write-Host "   ✓ Hosts file entries removed" -ForegroundColor Gray
    } else {
        Write-Host "   Manual removal required" -ForegroundColor Gray
    }
} else {
    Write-Host "   ⚠️  Run as Administrator to automatically remove hosts entries" -ForegroundColor Yellow
    Write-Host "   Or manually edit: C:\Windows\System32\drivers\etc\hosts" -ForegroundColor Gray
}

# Summary
Write-Host "`n=== Cleanup Summary ===" -ForegroundColor Cyan
Write-Host "✓ Kubernetes resources deleted" -ForegroundColor Green
Write-Host "✓ Minikube cluster stopped" -ForegroundColor Green
if ($deleteCluster -eq "y" -or $deleteCluster -eq "Y") {
    Write-Host "✓ Minikube cluster deleted" -ForegroundColor Green
}
Write-Host ""
Write-Host "To restart the demo:" -ForegroundColor White
Write-Host "  1. Follow setup-minikube.md" -ForegroundColor Gray
Write-Host "  2. Or run: minikube start" -ForegroundColor Gray
Write-Host ""
