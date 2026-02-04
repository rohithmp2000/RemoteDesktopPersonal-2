# Fix Missing Client Libraries (Verified Paths)
# Run this on the SERVER

Write-Host "=== Restoring Missing Libraries ===" -ForegroundColor Cyan

# Define verified source paths (from D: drive project)
$sourceRoot = "D:\Rohith Personal\Remote Desktop Personal-2\Server\wwwroot"
$destRoot = "C:\inetpub\RemoteDesktop\wwwroot"

# 1. Restore msgpack.min.js
$msgpackRelPath = "lib\msgpack\dist.es5+umd\msgpack.min.js"
$msgpackSource = Join-Path $sourceRoot $msgpackRelPath
$msgpackDest = Join-Path $destRoot $msgpackRelPath

if (Test-Path $msgpackSource) {
    Write-Host "Found source: $msgpackSource" -ForegroundColor Green
    
    # Create destination directory if needed
    $destDir = Split-Path $msgpackDest
    if (-not (Test-Path $destDir)) {
        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
        Write-Host "Created directory: $destDir" -ForegroundColor Yellow
    }
    
    Copy-Item $msgpackSource $msgpackDest -Force
    Write-Host "✅ Restored msgpack.min.js" -ForegroundColor Green
}
else {
    Write-Host "❌ Source msgpack.min.js NOT FOUND at $msgpackSource" -ForegroundColor Red
}

# 2. Restore signalr-protocol-msgpack.min.js
$signalrRelPath = "lib\microsoft\signalr-protocol-msgpack\dist\browser\signalr-protocol-msgpack.min.js"
$signalrSource = Join-Path $sourceRoot $signalrRelPath
$signalrDest = Join-Path $destRoot $signalrRelPath

if (Test-Path $signalrSource) {
    Write-Host "Found source: $signalrSource" -ForegroundColor Green
    
    # Create destination directory if needed
    $destDir = Split-Path $signalrDest
    if (-not (Test-Path $destDir)) {
        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
        Write-Host "Created directory: $destDir" -ForegroundColor Yellow
    }
    
    Copy-Item $signalrSource $signalrDest -Force
    Write-Host "✅ Restored signalr-protocol-msgpack.min.js" -ForegroundColor Green
}
else {
    Write-Host "❌ Source signalr-protocol-msgpack.min.js NOT FOUND at $signalrSource" -ForegroundColor Red
}

# 3. Verify Files match
Get-Item $msgpackDest, $signalrDest -ErrorAction SilentlyContinue | Select-Object FullName, Length | Format-Table -AutoSize
