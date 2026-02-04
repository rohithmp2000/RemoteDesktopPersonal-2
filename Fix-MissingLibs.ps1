# Fix Missing Client Libraries
# Run this on the SERVER

Write-Host "=== Checking Missing Libraries ===" -ForegroundColor Cyan

# Define expected paths
$wwwroot = "C:\inetpub\RemoteDesktop\wwwroot"
$msgpackPath = "$wwwroot\lib\msgpack\dist.es5+umd\msgpack.min.js"
$signalrProtoPath = "$wwwroot\lib\microsoft\signalr-protocol-msgpack\dist\browser\signalr-protocol-msgpack.min.js"

# Check MsgPack
if (Test-Path $msgpackPath) {
    Write-Host "✅ msgpack.min.js found at expected path." -ForegroundColor Green
}
else {
    Write-Host "❌ msgpack.min.js MISSING at: $msgpackPath" -ForegroundColor Red
    
    # Try to find it in the source folder (D: drive workspace)
    # Note: We are assuming the source is available. If not, we might need to download it.
    
    # Try generic search in source
    $sourcePath = "E:\RemoteDesktopPersonal\Server\wwwroot\lib\msgpack\dist.es5+umd\msgpack.min.js" 
    # (Using E: based on user's previous logs, but we'll try to be smart)
    
    if (-not (Test-Path $sourcePath)) {
        $sourcePath = "D:\Rohith Personal\Remote Desktop Personal-2\Server\wwwroot\lib\msgpack\dist.es5+umd\msgpack.min.js"
    }
    
    if (Test-Path $sourcePath) {
        Write-Host "   Found source file at: $sourcePath" -ForegroundColor Yellow
        Write-Host "   Restoring..." -ForegroundColor Yellow
        
        # Ensure directory exists
        $destDir = Split-Path $msgpackPath
        if (-not (Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory -Force | Out-Null }
        
        Copy-Item $sourcePath $msgpackPath -Force
        Write-Host "   ✅ Restored msgpack.min.js" -ForegroundColor Green
    }
    else {
        Write-Host "   ❌ Could not find source file to restore from!" -ForegroundColor Red
        Write-Host "   You may need to run 'libman restore' in the project or manually copy the file." -ForegroundColor Red
    }
}

# Check SignalR Protocol
if (Test-Path $signalrProtoPath) {
    Write-Host "✅ signalr-protocol-msgpack.min.js found." -ForegroundColor Green
}
else {
    Write-Host "❌ signalr-protocol-msgpack.min.js MISSING!" -ForegroundColor Red
    # Try generic search in source
    $sourcePath = "E:\RemoteDesktopPersonal\Server\wwwroot\lib\microsoft\signalr-protocol-msgpack\dist\browser\signalr-protocol-msgpack.min.js" 
    
    if (-not (Test-Path $sourcePath)) {
        $sourcePath = "D:\Rohith Personal\Remote Desktop Personal-2\Server\wwwroot\lib\microsoft\signalr-protocol-msgpack\dist\browser\signalr-protocol-msgpack.min.js"
    }

    if (Test-Path $sourcePath) {
        Write-Host "   Found source file at: $sourcePath" -ForegroundColor Yellow
        Write-Host "   Restoring..." -ForegroundColor Yellow
        
        # Ensure directory exists
        $destDir = Split-Path $signalrProtoPath
        if (-not (Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory -Force | Out-Null }
        
        Copy-Item $sourcePath $signalrProtoPath -Force
        Write-Host "   ✅ Restored signalr-protocol-msgpack.min.js" -ForegroundColor Green
    }
}

# Verify IIS MIME config again (just in case)
Write-Host "`n=== Verifying IIS Configuration ===" -ForegroundColor Cyan
$webConfig = Get-Content "C:\inetpub\RemoteDesktop\web.config" -Raw
if ($webConfig -match '<mimeMap fileExtension=".js" mimeType="application/javascript" />') {
    Write-Host "✅ web.config has .js MIME type" -ForegroundColor Green
}
else {
    Write-Host "⚠️ web.config might be missing MIME type for .js" -ForegroundColor Yellow
}
