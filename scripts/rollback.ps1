param(
    [string]$PreviousImage = "rollback-app:previous"
)

Write-Host "======================================"
Write-Host "       AUTOMATIC ROLLBACK"
Write-Host "======================================"

Write-Host "Removing failed application..."

docker rm -f rollback-app 2>$null

Write-Host "Restoring previous working version..."

docker run -d `
    --name rollback-app `
    -p 5000:5000 `
    $PreviousImage

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Previous version could not be started."
    exit 1
}

Start-Sleep -Seconds 5

try {
    $response = Invoke-WebRequest `
        -Uri "http://localhost:5000/health" `
        -UseBasicParsing `
        -TimeoutSec 10

    if ($response.StatusCode -eq 200) {
        Write-Host "Previous version is healthy."
        Write-Host "ROLLBACK SUCCESSFUL."
        exit 0
    }
}
catch {
    Write-Host "Health check failed."
}

Write-Host "ROLLBACK FAILED."
exit 1
