# Test Remote Control Setup
# Run this on the CLIENT machine to verify desktop client is available

Write-Host "=== Remote Control Diagnostics ===" -ForegroundColor Cyan

# 1. Check if Desktop client exists
Write-Host "`n[1] Checking Desktop client..." -ForegroundColor Yellow
$desktopPath = "C:\Program Files\Remotely\Desktop\AMD_Color.exe"
if (Test-Path $desktopPath) {
    $desktopFile = Get-Item $desktopPath
    Write-Host "Desktop client found: $($desktopFile.FullName)" -ForegroundColor Green
    Write-Host "Size: $([math]::Round($desktopFile.Length/1KB, 2)) KB" -ForegroundColor Green
}
else {
    Write-Host "Desktop client NOT found at: $desktopPath" -ForegroundColor Red
    Write-Host "This is required for remote control!" -ForegroundColor Red
}

# 2. Check if agent service is running
Write-Host "`n[2] Checking Agent service..." -ForegroundColor Yellow
$service = Get-Service Remotely_Service -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "Service Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq 'Running') { 'Green' } else { 'Red' })
    Write-Host "Start Type: $($service.StartType)" -ForegroundColor Green
}
else {
    Write-Host "Service not found!" -ForegroundColor Red
}

# 3. Check connection info
Write-Host "`n[3] Checking connection configuration..." -ForegroundColor Yellow
$connectionInfo = "C:\Program Files\Remotely\ConnectionInfo.json"
if (Test-Path $connectionInfo) {
    $config = Get-Content $connectionInfo | ConvertFrom-Json
    Write-Host "Server: $($config.Host)" -ForegroundColor Green
    Write-Host "Organization: $($config.OrganizationID)" -ForegroundColor Green
    Write-Host "Device ID: $($config.DeviceID)" -ForegroundColor Green
}
else {
    Write-Host "ConnectionInfo.json not found!" -ForegroundColor Red
}

# 4. Test if desktop client can be launched
Write-Host "`n[4] Testing Desktop client launch..." -ForegroundColor Yellow
if (Test-Path $desktopPath) {
    try {
        # Try to get file version
        $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($desktopPath)
        Write-Host "Desktop client version: $($versionInfo.FileVersion)" -ForegroundColor Green
        
        # Check dependencies
        $desktopDir = Split-Path $desktopPath
        $dllCount = (Get-ChildItem $desktopDir -Filter "*.dll").Count
        Write-Host "Desktop dependencies: $dllCount DLL files" -ForegroundColor Green
    }
    catch {
        Write-Host "Error checking desktop client: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "Cannot test - desktop client not found" -ForegroundColor Red
}

# 5. Check firewall rules
Write-Host "`n[5] Checking Windows Firewall..." -ForegroundColor Yellow
$firewallRules = Get-NetFirewallRule -DisplayName "*Remotely*" -ErrorAction SilentlyContinue
if ($firewallRules) {
    foreach ($rule in $firewallRules) {
        Write-Host "Rule: $($rule.DisplayName) - Enabled: $($rule.Enabled)" -ForegroundColor Green
    }
}
else {
    Write-Host "No Remotely firewall rules found" -ForegroundColor Yellow
    Write-Host "This might block remote control connections" -ForegroundColor Yellow
}

# 6. Check if desktop client can connect to server
Write-Host "`n[6] Testing server connectivity..." -ForegroundColor Yellow
if (Test-Path $connectionInfo) {
    $config = Get-Content $connectionInfo | ConvertFrom-Json
    try {
        $response = Invoke-WebRequest -Uri $config.Host -UseBasicParsing -TimeoutSec 5
        Write-Host "Server reachable: $($config.Host) - Status: $($response.StatusCode)" -ForegroundColor Green
    }
    catch {
        Write-Host "Cannot reach server: $($config.Host)" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

Write-Host "`n=== Diagnostics Complete ===" -ForegroundColor Cyan
Write-Host "`nIf desktop client is missing or has issues, you may need to rebuild and reinstall." -ForegroundColor Yellow
