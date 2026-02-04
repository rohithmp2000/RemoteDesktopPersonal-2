# Debug Script - Run on Server
# This will help diagnose the 500 error

Write-Host "=== Diagnostic Information ===" -ForegroundColor Cyan

# 1. Check if files exist
Write-Host "`n[1] Checking file existence..." -ForegroundColor Yellow
$zipPath = "C:\inetpub\RemoteDesktop\wwwroot\Content\Remotely-Win-x64.zip"
if (Test-Path $zipPath) {
    $file = Get-Item $zipPath
    Write-Host "File exists: $($file.FullName)" -ForegroundColor Green
    Write-Host "Size: $([math]::Round($file.Length/1MB, 2)) MB" -ForegroundColor Green
    Write-Host "Last Modified: $($file.LastWriteTime)" -ForegroundColor Green
}
else {
    Write-Host "File NOT found!" -ForegroundColor Red
}

# 2. Check permissions
Write-Host "`n[2] Checking permissions..." -ForegroundColor Yellow
icacls $zipPath

# 3. Check if Content directory is accessible
Write-Host "`n[3] Testing Content directory..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8585/Content/" -UseBasicParsing -ErrorAction Stop
    Write-Host "Content directory accessible: $($response.StatusCode)" -ForegroundColor Green
}
catch {
    Write-Host "Content directory error: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Check application logs for errors
Write-Host "`n[4] Checking recent application logs..." -ForegroundColor Yellow
$logPath = "C:\inetpub\RemoteDesktop\Logs\Remotely_Server.log"
if (Test-Path $logPath) {
    Get-Content $logPath -Tail 20 | Where-Object { $_ -match "error|exception|fail" -and $_ -notmatch "FailedToDeterminePort" }
}
else {
    Write-Host "Log file not found" -ForegroundColor Yellow
}

# 5. Check IIS application pool status
Write-Host "`n[5] Checking IIS Application Pool..." -ForegroundColor Yellow
Import-Module WebAdministration
$pool = Get-WebAppPoolState -Name "RemoteDesktopAppPool"
Write-Host "App Pool Status: $($pool.Value)" -ForegroundColor $(if ($pool.Value -eq 'Started') { 'Green' } else { 'Red' })

# 6. Test with curl (different method)
Write-Host "`n[6] Testing with curl..." -ForegroundColor Yellow
try {
    curl.exe -I "http://localhost:8585/Content/Remotely-Win-x64.zip" 2>&1 | Select-String "HTTP"
}
catch {
    Write-Host "Curl test failed: $_" -ForegroundColor Red
}

# 7. Check web.config
Write-Host "`n[7] Checking web.config static content settings..." -ForegroundColor Yellow
$webConfig = "C:\inetpub\RemoteDesktop\web.config"
if (Test-Path $webConfig) {
    [xml]$config = Get-Content $webConfig
    if ($config.configuration.'system.webServer'.staticContent) {
        Write-Host "Static content configured in web.config" -ForegroundColor Green
    }
    else {
        Write-Host "No static content configuration found in web.config" -ForegroundColor Yellow
    }
}
else {
    Write-Host "web.config not found" -ForegroundColor Red
}

Write-Host "`n=== End Diagnostics ===" -ForegroundColor Cyan
