# Sync Libraries using Robocopy (Self-Elevating)
# This script will automatically ask for Admin privileges

# 1. Auto-Elevation
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Restarting script as Administrator..." -ForegroundColor Yellow
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";
    $newProcess.Arguments = "& '$($MyInvocation.MyCommand.Definition)'";
    $newProcess.Verb = "runas";
    [System.Diagnostics.Process]::Start($newProcess);
    Exit;
}

Write-Host "✅ Running as Administrator" -ForegroundColor Green

# 2. Fix Permissions (Just in case)
$destRoot = "C:\inetpub\RemoteDesktop\wwwroot"
if (Test-Path $destRoot) {
    Write-Host "Unlocking permissions on $destRoot..." -ForegroundColor Yellow
    # Reset permissions to allow Administrators full control
    icacls "$destRoot" /grant "Administrators:(OI)(CI)F" /T | Out-Null
    icacls "$destRoot" /remove:d "Everyone" /T | Out-Null # Remove deny rules if any
}

# 3. Sync Files
$sourceDir = "D:\Rohith Personal\Remote Desktop Personal-2\Server\wwwroot\lib"
$destDir = "C:\inetpub\RemoteDesktop\wwwroot\lib"

Write-Host "`nSyncing libraries..." -ForegroundColor Cyan
Write-Host "Source: $sourceDir"
Write-Host "Dest:   $destDir"

# Robocopy with retry 
robocopy "$sourceDir" "$destDir" /E /IS /IT /NP /R:2 /W:2

if ($LASTEXITCODE -lt 8) {
    Write-Host "`n✅ Sync Complete!" -ForegroundColor Green
    Write-Host "Press any key to close..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
else {
    Write-Host "`n❌ Robocopy reported errors." -ForegroundColor Red
    Write-Host "Press any key to close..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
