# =========================================================
# RemoteDesktopPersonal-2 Deployment Script
# FULLY AUTOMATED | JENKINS SAFE | NON-INTERACTIVE
# =========================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "=== RemoteDesktopPersonal-2 Deployment Started ===" -ForegroundColor Cyan

# ---------------------------------------------------------
# VARIABLES
# ---------------------------------------------------------
$ProjectRoot = "E:\RemoteDesktopPersonal-2"
$ServerProject = "$ProjectRoot\Server"
$IISRoot = "C:\inetpub\RemoteDesktop"
$ContentSrc = "$ServerProject\wwwroot\Content"
$ContentDest = "$IISRoot\wwwroot\Content"
$LibmanCache = "$env:LOCALAPPDATA\.librarymanager\cache\unpkg"

# ---------------------------------------------------------
# 1. STOP IIS
# ---------------------------------------------------------
Write-Host "Stopping IIS..." -ForegroundColor Yellow
iisreset /stop | Out-Null

# ---------------------------------------------------------
# 2. BUILD CLIENT PACKAGES
# ---------------------------------------------------------
Write-Host "Building client packages..." -ForegroundColor Yellow
Set-Location $ProjectRoot

if (!(Test-Path ".\Build-AllClients.ps1")) {
    throw "Build-AllClients.ps1 not found"
}

powershell -NoProfile -ExecutionPolicy Bypass -File ".\Build-AllClients.ps1"

# ---------------------------------------------------------
# 3. PUBLISH SERVER TO IIS
# ---------------------------------------------------------
Write-Host "Publishing server application..." -ForegroundColor Yellow
Set-Location $ServerProject

dotnet publish `
    -c Release `
    -o "$IISRoot" `
    /p:TypeScriptCompileBlocked=true `
    /nologo

# ---------------------------------------------------------
# 4. ENSURE CONTENT DIRECTORY EXISTS
# ---------------------------------------------------------
Write-Host "Ensuring Content directory exists..." -ForegroundColor Yellow
New-Item -Path $ContentDest -ItemType Directory -Force | Out-Null

# ---------------------------------------------------------
# 5. COPY CLIENT PACKAGES
# ---------------------------------------------------------
Write-Host "Copying client packages to IIS..." -ForegroundColor Yellow
Copy-Item "$ContentSrc\*" -Destination $ContentDest -Recurse -Force

# ---------------------------------------------------------
# 6. RESTORE CLIENT LIBRARIES (LIBMAN - SYSTEM SAFE)
# ---------------------------------------------------------
Write-Host "Restoring LibMan libraries..." -ForegroundColor Yellow
Set-Location $IISRoot

dotnet tool restore
dotnet libman restore --verbosity minimal

# ---------------------------------------------------------
# 7. FIX MSGPACK LOCATION
# ---------------------------------------------------------
Write-Host "Fixing msgpack library location..." -ForegroundColor Yellow
Copy-Item `
    "$IISRoot\wwwroot\lib\msgpack\dist.es5+umd\*" `
    -Destination "$IISRoot\wwwroot\lib\msgpack\" `
    -Recurse `
    -Force `
    -ErrorAction SilentlyContinue

# ---------------------------------------------------------
# 8. VERIFY DEPLOYED CONTENT
# ---------------------------------------------------------
Write-Host "Verifying deployed client files..." -ForegroundColor Yellow
Get-ChildItem $ContentDest -Recurse | Select-Object Name, Length

# ---------------------------------------------------------
# 9. SET IIS PERMISSIONS
# ---------------------------------------------------------
Write-Host "Setting IIS permissions..." -ForegroundColor Yellow
icacls "$IISRoot\wwwroot" /grant "Everyone:(OI)(CI)R" /T /C | Out-Null
icacls "$IISRoot\App_Data" /grant "IIS_IUSRS:(OI)(CI)F" /T /C 2>$null

# ---------------------------------------------------------
# 10. CLEAR LIBMAN CACHE
# ---------------------------------------------------------
Write-Host "Clearing LibMan cache..." -ForegroundColor Yellow
Remove-Item $LibmanCache -Recurse -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------
# 11. START IIS
# ---------------------------------------------------------
Write-Host "Starting IIS..." -ForegroundColor Yellow
iisreset /start | Out-Null

# ---------------------------------------------------------
# DONE
# ---------------------------------------------------------
Write-Host "=== Deployment Completed Successfully ===" -ForegroundColor Green
Write-Host "Access URL: https://10.200.50.90:8585/" -ForegroundColor Cyan

exit 0