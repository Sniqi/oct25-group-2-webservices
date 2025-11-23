# Restore Script for DataOps Project
# Usage: .\scripts\restore.ps1 -BackupFile .\backups\backup-2023....sql

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFile
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $BackupFile)) {
    Write-Error "❌ File not found: $BackupFile"
    exit 1
}

Write-Host "⚠️  WARNING: This will overwrite the current database 'dataopsdb'."
Write-Host "Starting restore from $BackupFile..."

try {
    # We use 'cat' (Get-Content) piped to docker exec -i psql
    # cmd /c is used to handle the pipe reliably

    $restoreCommand = "type $BackupFile | docker exec -i dataops-db psql -U dataops -d dataopsdb"

    cmd /c $restoreCommand

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Restore completed successfully."
    } else {
        Write-Error "❌ Restore failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Error "❌ An error occurred: $_"
}
