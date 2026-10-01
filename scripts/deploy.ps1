param(
    [string]$Version = "latest"
)

$NewImage = "rollback-app:$Version"
$PreviousImage = "rollback-app:previous"

$TestContainer = "rollback-app-test"
$LiveContainer = "rollback-app"

Write-Host "======================================"
Write-Host "       AUTOMATIC DEPLOYMENT"
Write-Host "======================================"

Write-Host "New image: $NewImage"

# Save currently running version
$liveExists = docker ps -a --filter "name=^$LiveContainer$" --format "{{.Names}}"

if ($liveExists -eq $LiveContainer) {

    Write-Host "Saving current version..."

    $currentImage = docker inspect $LiveContainer `
        --format "{{.Image}}"

    docker tag $currentImage $PreviousImage
}

# Remove old test container
docker rm -f $TestContainer 2>$null

# Start new version on port 5001
Write-Host "Starting new version for testing..."

docker run -d `
    --name $TestContainer `
    -p 5001:5000 `
    -e APP_VERSION=$Version `
    $NewImage

if ($LASTEXITCODE -ne 0) {
    Write-Host "New version failed to start."
    exit 1
}

Start-Sleep -Seconds 5

# Health check
Write-Host "Checking new version..."

$healthy = $false

try {

    $response = Invoke-WebRequest `
        -Uri "http://localhost:5001/health" `
        -UseBasicParsing `
        -TimeoutSec 10

    if ($response.StatusCode -eq 200) {
        $healthy = $true
    }

}
catch {
    Write-Host "Health check failed."
}

# New version failed
if (-not $healthy) {

    Write-Host ""
    Write-Host "======================================"
    Write-Host "       NEW VERSION FAILED"
    Write-Host "       STARTING ROLLBACK"
    Write-Host "======================================"

    docker logs $TestContainer

    docker rm -f $TestContainer

    if (docker image inspect $PreviousImage 2>$null) {
        & ".\scripts\rollback.ps1" -PreviousImage $PreviousImage
    }
    else {
        Write-Host "No previous version available."
    }

    exit 1
}

# New version passed
Write-Host ""
Write-Host "New version passed health check."

# Remove test container
docker rm -f $TestContainer

# Remove current production container
docker rm -f $LiveContainer 2>$null

# Start new production version
Write-Host "Deploying new version to port 5000..."

docker run -d `
    --name $LiveContainer `
    -p 5000:5000 `
    -e APP_VERSION=$Version `
    $NewImage

if ($LASTEXITCODE -ne 0) {

    Write-Host "Production deployment failed."

    & ".\scripts\rollback.ps1" -PreviousImage $PreviousImage

    exit 1
}

Start-Sleep -Seconds 5

# Final health check
try {

    $response = Invoke-WebRequest `
        -Uri "http://localhost:5000/health" `
        -UseBasicParsing `
        -TimeoutSec 10

    if ($response.StatusCode -eq 200) {

        Write-Host ""
        Write-Host "======================================"
        Write-Host "       DEPLOYMENT SUCCESSFUL"
        Write-Host "======================================"

        exit 0
    }

}
catch {
    Write-Host "Production health check failed."
}

# Final rollback
Write-Host ""
Write-Host "Production health check failed."
Write-Host "Starting automatic rollback..."

& ".\scripts\rollback.ps1" -PreviousImage $PreviousImage

exit 1
