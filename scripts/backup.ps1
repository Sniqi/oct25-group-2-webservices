# Backup Script for DataOps Project
# Usage: .\scripts\backup.ps1

$ErrorActionPreference = "Stop"

# Ensure backups directory exists
$backupDir = Join-Path (Get-Location) "backups"
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$filename = "backup-$timestamp.sql"
$filepath = Join-Path $backupDir $filename

Write-Host "Starting backup of dataops-db..."

# Execute pg_dump inside the container and capture output
# We use cmd /c to handle the redirection properly if running from PS to Docker
# Alternatively, we can capture stdout.
# Note: We assume the container name is 'dataops-db' as defined in Terraform.

try {
    # Using --no-owner --no-acl to avoid permission issues on restore
    $dumpCommand = "docker exec -i dataops-db pg_dump -U dataops --clean --if-exists --no-owner --no-acl dataopsdb"
    
    # Invoke-Expression or direct execution
    # We pipe the output to a file. In PowerShell, we need to be careful with encoding.
    # Using cmd /c is often the most reliable way to handle binary/text piping from docker in Windows.
    cmd /c "$dumpCommand > $filepath"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Backup successful: $filepath"
    } else {
        Write-Error "❌ Backup failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Error "❌ An error occurred: $_"
}
