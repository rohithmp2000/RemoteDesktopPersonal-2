# Reinstall Remotely Client
# Run this as Administrator

$ErrorActionPreference = "Stop"

Write-Host "`nReinstalling Remotely Client..." -ForegroundColor Cyan

try {
    # Stop and remove existing service
    Write-Host "Stopping existing service..." -ForegroundColor Yellow
    Stop-Service -Name Remotely_Service -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    sc.exe delete Remotely_Service | Out-Null
    
    # Remove installation directory
    Write-Host "Removing old installation..." -ForegroundColor Yellow
    Remove-Item -Path "C:\Program Files\Remotely" -Recurse -Force -ErrorAction SilentlyContinue
    
    # Download and run fresh installer
    Write-Host "Downloading fresh installer..." -ForegroundColor Yellow
    $ServerUrl = "http://10.200.50.90:8585"
    $OrgId = "e8f4ad87-4a4b-4da1-bcb2-1788eaeb80e8"
    $InstallerUrl = "$ServerUrl/api/ClientDownloads/WindowsInstaller/$OrgId"
    
    Invoke-WebRequest -Uri $InstallerUrl -OutFile "$env:TEMP\Install-Remotely.ps1" -UseBasicParsing
    
    Write-Host "Running installer..." -ForegroundColor Yellow
    powershell.exe -ExecutionPolicy Bypass -File "$env:TEMP\Install-Remotely.ps1"
    
    # Verify installation
    Start-Sleep -Seconds 3
    $Service = Get-Service -Name Remotely_Service -ErrorAction SilentlyContinue
    
    if ($Service) {
        Write-Host "`nService Status: $($Service.Status)" -ForegroundColor $(if ($Service.Status -eq 'Running') { 'Green' } else { 'Yellow' })
        
        if ($Service.Status -ne 'Running') {
            Write-Host "Attempting to start service..." -ForegroundColor Yellow
            Start-Service -Name Remotely_Service
            Start-Sleep -Seconds 2
            $Service = Get-Service -Name Remotely_Service
            Write-Host "Service Status: $($Service.Status)" -ForegroundColor $(if ($Service.Status -eq 'Running') { 'Green' } else { 'Red' })
        }
        
        if ($Service.Status -eq 'Running') {
            Write-Host "`nSUCCESS! Remotely client is installed and running." -ForegroundColor Green
            Write-Host "The device should now appear in your server dashboard." -ForegroundColor Green
        }
        else {
            Write-Host "`nWARNING: Service installed but not running." -ForegroundColor Yellow
            Write-Host "Check the logs at: C:\Program Files\Remotely\Logs\" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "`nERROR: Service was not created." -ForegroundColor Red
    }
}
catch {
    Write-Host "`nERROR: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
