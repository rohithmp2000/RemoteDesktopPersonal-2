<#
.SYNOPSIS
    Quick deployment script for testing the Remotely agent on a local client.
.DESCRIPTION
    This script installs the Remotely agent on the local machine for testing purposes.
    It downloads the client from your server and installs it as a Windows service.
.PARAMETER ServerUrl
    The URL of your Remotely server (e.g., http://192.168.1.100:5000)
.PARAMETER OrganizationId
    Your organization ID (GUID). Get this from the server admin panel.
.PARAMETER DeviceAlias
    Optional friendly name for this device
.PARAMETER DeviceGroup
    Optional group name for organizing devices
.PARAMETER Uninstall
    Uninstall the agent instead of installing
.EXAMPLE
    .\Quick-Deploy.ps1 -ServerUrl "http://192.168.1.100:5000" -OrganizationId "your-org-id"
    .\Quick-Deploy.ps1 -ServerUrl "http://192.168.1.100:5000" -OrganizationId "your-org-id" -DeviceAlias "Test PC" -DeviceGroup "Testing"
    .\Quick-Deploy.ps1 -Uninstall
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ServerUrl = "",
    
    [Parameter(Mandatory = $false)]
    [string]$OrganizationId = "",
    
    [string]$DeviceAlias = "",
    [string]$DeviceGroup = "",
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

# Configuration
$InstallPath = "$env:ProgramFiles\Remotely"
$ServiceName = "AMD_Color_Agent_Service"
$LogPath = "$env:TEMP\Remotely_QuickDeploy.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    switch ($Level) {
        "ERROR" { Write-Host $LogMessage -ForegroundColor Red }
        "WARN" { Write-Host $LogMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $LogMessage -ForegroundColor Green }
        default { Write-Host $LogMessage -ForegroundColor White }
    }
    
    Add-Content -Path $LogPath -Value $LogMessage
}

function Test-Administrator {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Stop-RemotelyService {
    Write-Log "Stopping Remotely service..."
    
    if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    
    # Kill any remaining processes
    Get-Process -Name "Remotely_Agent" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process -Name "AMD_Color_Agent" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process -Name "AMD_Color" -ErrorAction SilentlyContinue | Stop-Process -Force
}

function Uninstall-Remotely {
    Write-Log "Starting uninstallation..." "WARN"
    
    Stop-RemotelyService
    
    # Remove service
    if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
        Write-Log "Removing service..."
        sc.exe delete $ServiceName | Out-Null
    }
    
    # Remove installation directory
    if (Test-Path $InstallPath) {
        Write-Log "Removing installation directory..."
        Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Remove firewall rule
    Remove-NetFirewallRule -Name "Remotely Desktop Unattended" -ErrorAction SilentlyContinue
    
    Write-Log "Uninstallation complete!" "SUCCESS"
}

function Install-Remotely {
    Write-Log "Starting installation..."
    
    # Validate parameters
    if ([string]::IsNullOrWhiteSpace($ServerUrl)) {
        throw "ServerUrl is required. Use -ServerUrl parameter."
    }
    
    if ([string]::IsNullOrWhiteSpace($OrganizationId)) {
        throw "OrganizationId is required. Use -OrganizationId parameter."
    }
    
    # Normalize server URL
    $ServerUrl = $ServerUrl.TrimEnd('/')
    
    # Detect platform
    $Platform = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    Write-Log "Detected platform: $Platform"
    
    # Test server connectivity
    Write-Log "Testing connection to server: $ServerUrl"
    try {
        $TestUrl = "$ServerUrl/Content/Remotely-Win-$Platform.zip"
        $Response = Invoke-WebRequest -Uri $TestUrl -Method Head -UseBasicParsing -TimeoutSec 10
        Write-Log "Server is reachable" "SUCCESS"
    }
    catch {
        throw "Cannot connect to server at $ServerUrl. Error: $_"
    }
    
    # Preserve existing device ID if present
    $DeviceId = [System.Guid]::NewGuid().ToString()
    if ((Test-Path "$InstallPath\ConnectionInfo.json")) {
        Write-Log "Found existing installation, preserving device ID..."
        try {
            $ExistingConfig = Get-Content "$InstallPath\ConnectionInfo.json" | ConvertFrom-Json
            if ($ExistingConfig.DeviceID) {
                $DeviceId = $ExistingConfig.DeviceID
                Write-Log "Using existing device ID: $DeviceId"
            }
        }
        catch {
            Write-Log "Could not read existing config, using new device ID" "WARN"
        }
    }
    
    # Stop existing service
    Stop-RemotelyService
    
    # Download client
    Write-Log "Downloading client from server..."
    $DownloadUrl = "$ServerUrl/Content/Remotely-Win-$Platform.zip"
    $ZipPath = "$env:TEMP\Remotely-Win-$Platform.zip"
    
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        Write-Log "Download complete" "SUCCESS"
    }
    catch {
        throw "Failed to download client: $_"
    }
    
    # Verify download
    if (!(Test-Path $ZipPath)) {
        throw "Downloaded file not found at $ZipPath"
    }
    
    $FileSize = (Get-Item $ZipPath).Length / 1MB
    Write-Log "Downloaded file size: $([math]::Round($FileSize, 2)) MB"
    
    # Extract files
    Write-Log "Extracting files to $InstallPath..."
    
    # Clean install directory (except ConnectionInfo.json)
    if (Test-Path $InstallPath) {
        Get-ChildItem -Path $InstallPath | Where-Object { $_.Name -ne "ConnectionInfo.json" } | Remove-Item -Recurse -Force
    }
    else {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    }
    
    Expand-Archive -Path $ZipPath -DestinationPath $InstallPath -Force
    
    # Create connection configuration
    Write-Log "Creating connection configuration..."
    $ConnectionInfo = @{
        DeviceID                = $DeviceId
        Host                    = $ServerUrl
        OrganizationID          = $OrganizationId
        ServerVerificationToken = ""
    } | ConvertTo-Json
    
    $ConnectionInfo | Out-File "$InstallPath\ConnectionInfo.json" -Force
    
    # Register device with optional alias and group
    if ($DeviceAlias -or $DeviceGroup) {
        Write-Log "Registering device with server..."
        try {
            $DeviceInfo = @{
                DeviceAlias     = $DeviceAlias
                DeviceGroupName = $DeviceGroup
                OrganizationID  = $OrganizationId
                DeviceID        = $DeviceId
            } | ConvertTo-Json
            
            Invoke-RestMethod -Method Post -Uri "$ServerUrl/api/devices" -Body $DeviceInfo -ContentType "application/json" -UseBasicParsing
            Write-Log "Device registered successfully" "SUCCESS"
        }
        catch {
            Write-Log "Could not register device (this is optional): $_" "WARN"
        }
    }
    
    # Install Windows Service
    Write-Log "Installing Windows service..."
    
    $ServicePath = "`"$InstallPath\AMD_Color_Agent.exe`""
    $ServiceDescription = "Background service that maintains a connection to the Remotely server. Used for remote support and maintenance."
    
    # Remove existing service if present
    if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
        sc.exe delete $ServiceName | Out-Null
        Start-Sleep -Seconds 2
    }
    
    New-Service -Name $ServiceName `
        -BinaryPathName $ServicePath `
        -DisplayName "AMD_Color_Agent Service" `
        -Description $ServiceDescription `
        -StartupType Automatic | Out-Null
    
    # Configure service recovery
    sc.exe failure $ServiceName reset=5 actions=restart/5000 | Out-Null
    
    # Start service
    Write-Log "Starting service..."
    Start-Service -Name $ServiceName
    
    # Wait and verify
    Start-Sleep -Seconds 3
    $Service = Get-Service -Name $ServiceName
    
    if ($Service.Status -eq "Running") {
        Write-Log "Service started successfully!" "SUCCESS"
    }
    else {
        Write-Log "Service status: $($Service.Status)" "WARN"
    }
    
    # Cleanup
    Remove-Item -Path $ZipPath -Force -ErrorAction SilentlyContinue
    
    Write-Log "Installation complete!" "SUCCESS"
    Write-Log "Device ID: $DeviceId"
    Write-Log "Server: $ServerUrl"
    Write-Log "Organization: $OrganizationId"
    Write-Log ""
    Write-Log "The device should now appear in your server dashboard." "SUCCESS"
}

# Main execution
try {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Remotely Quick Deployment Script      ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    # Check administrator privileges
    if (!(Test-Administrator)) {
        Write-Log "This script requires administrator privileges!" "ERROR"
        Write-Log "Please run PowerShell as Administrator and try again." "ERROR"
        exit 1
    }
    
    Write-Log "Log file: $LogPath"
    Write-Log ""
    
    if ($Uninstall) {
        Uninstall-Remotely
    }
    else {
        Install-Remotely
    }
    
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
catch {
    Write-Log "ERROR: $_" "ERROR"
    Write-Log $_.ScriptStackTrace "ERROR"
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
