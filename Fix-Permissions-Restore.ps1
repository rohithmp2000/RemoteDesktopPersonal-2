# Fix Permissions and Restore Libraries
# CRITICAL: Run this as ADMINISTRATOR

Write-Host "=== Fixing Permissions & Restoring Libraries ===" -ForegroundColor Cyan

$destRoot = "C:\inetpub\RemoteDesktop\wwwroot"
$sourceRoot = "D:\Rohith Personal\Remote Desktop Personal-2\Server\wwwroot"

# 1. Attempt to fix permissions on wwwroot
# This allows the script to create folders
Write-Host "`n[1] Granting Permissions..." -ForegroundColor Yellow
try {
    icacls "C:\inetpub\RemoteDesktop" /grant "Users:(OI)(CI)F" /T
    icacls "C:\inetpub\RemoteDesktop\wwwroot" /grant "Users:(OI)(CI)F" /T
    Write-Host "✅ Permissions updated." -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Failed to update permissions. Ensure you are running as Administrator." -ForegroundColor Red
}

# 2. Create Directories explicitly
Write-Host "`n[2] Creating Directories..." -ForegroundColor Yellow

$msgpackDir = "$destRoot\lib\msgpack\dist.es5+umd"
$signalrDir = "$destRoot\lib\microsoft\signalr-protocol-msgpack\dist\browser"

if (-not (Test-Path $msgpackDir)) {
    Write-Host "Creating: $msgpackDir"
    New-Item -Path $msgpackDir -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path $signalrDir)) {
    Write-Host "Creating: $signalrDir"
    New-Item -Path $signalrDir -ItemType Directory -Force | Out-Null
}

# 3. Copy Files
Write-Host "`n[3] Copying Files..." -ForegroundColor Yellow

# MsgPack
$msgpackSource = "$sourceRoot\lib\msgpack\dist.es5+umd\msgpack.min.js"
$msgpackDest = "$msgpackDir\msgpack.min.js"

if (Test-Path $msgpackSource) {
    Copy-Item $msgpackSource $msgpackDest -Force
    if (Test-Path $msgpackDest) {
        Write-Host "✅ Restored msgpack.min.js" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Failed to copy msgpack.min.js (Check Permissions)" -ForegroundColor Red
    }
}
else {
    Write-Host "❌ Source msgpack.min.js not found!" -ForegroundColor Red
}

# SignalR Protocol
$signalrSource = "$sourceRoot\lib\microsoft\signalr-protocol-msgpack\dist\browser\signalr-protocol-msgpack.min.js"
$signalrDest = "$signalrDir\signalr-protocol-msgpack.min.js"

if (Test-Path $signalrSource) {
    Copy-Item $signalrSource $signalrDest -Force
    if (Test-Path $signalrDest) {
        Write-Host "✅ Restored signalr-protocol-msgpack.min.js" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Failed to copy signalr-protocol-msgpack.min.js (Check Permissions)" -ForegroundColor Red
    }
}
else {
    Write-Host "❌ Source signalr-protocol-msgpack.min.js not found!" -ForegroundColor Red
}

Write-Host "`n=== Process Complete ===" -ForegroundColor Cyan
