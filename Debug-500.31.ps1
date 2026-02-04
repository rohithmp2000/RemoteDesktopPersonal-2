# Debug 500.31 Error
# Run this on the SERVER

Write-Host "=== Diagnosing 500.31 Error ===" -ForegroundColor Cyan

# 1. Check for critical files
Write-Host "`n[1] Check Published Files" -ForegroundColor Yellow
$dllPath = "C:\inetpub\RemoteDesktop\Remotely.Server.dll"
$configPath = "C:\inetpub\RemoteDesktop\Remotely.Server.runtimeconfig.json"
$depsPath = "C:\inetpub\RemoteDesktop\Remotely.Server.deps.json"

if (Test-Path $dllPath) { Write-Host "✅ Remotely.Server.dll found" -ForegroundColor Green } else { Write-Host "❌ Remotely.Server.dll MISSING" -ForegroundColor Red }
if (Test-Path $configPath) { Write-Host "✅ Runtime Config found" -ForegroundColor Green } else { Write-Host "❌ Runtime Config MISSING" -ForegroundColor Red }
if (Test-Path $depsPath) { Write-Host "✅ Deps JSON found" -ForegroundColor Green } else { Write-Host "❌ Deps JSON MISSING" -ForegroundColor Red }

# 2. Check Installed Runtimes
Write-Host "`n[2] Check .NET Runtimes" -ForegroundColor Yellow
try {
    dotnet --list-runtimes
}
catch {
    Write-Host "❌ 'dotnet' command not found!" -ForegroundColor Red
}

# 3. Check Runtime Config Content (to see required version)
if (Test-Path $configPath) {
    Write-Host "`n[3] Required Runtime Version" -ForegroundColor Yellow
    Get-Content $configPath -Raw
}

# 4. Try Dry Run (CRITICAL STEP)
Write-Host "`n[4] Attempting Manual Launch (Dry Run)" -ForegroundColor Yellow
Write-Host "This will show the exact error why it fails to start." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop if it starts successfully." -ForegroundColor Gray
Start-Sleep -Seconds 2

try {
    Set-Location "C:\inetpub\RemoteDesktop"
    dotnet .\Remotely.Server.dll
}
catch {
    Write-Host "Manual launch failed: $_" -ForegroundColor Red
}
