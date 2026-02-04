<#
.SYNOPSIS
    Builds all client installers for the Remote Desktop application.
.DESCRIPTION
    This script builds the Agent and Desktop clients for all supported platforms:
    - Windows x64
    - Windows x86
    - Linux x64
    - macOS x64
    - macOS ARM64
.EXAMPLE
    .\Build-AllClients.ps1
    .\Build-AllClients.ps1 -PlatformsOnly "win-x64,linux-x64"
#>

param(
    [string]$PlatformsOnly = "",
    [switch]$SkipCleanup
)

$ErrorActionPreference = "Stop"

# Configuration
$SolutionDir = $PSScriptRoot
$OutputDir = Join-Path $SolutionDir "Server\wwwroot\Content"
$TempDir = Join-Path $SolutionDir "BuildTemp"

# Platform configurations
$Platforms = @(
    @{
        Name           = "win-x64"
        Runtime        = "win-x64"
        AgentProject   = "Agent\Agent.csproj"
        DesktopProject = "Desktop.Win\Desktop.Win.csproj"
        OutputFolder   = "Win-x64"
        ZipName        = "Remotely-Win-x64.zip"
        HasDesktop     = $true
    },
    @{
        Name           = "win-x86"
        Runtime        = "win-x86"
        AgentProject   = "Agent\Agent.csproj"
        DesktopProject = "Desktop.Win\Desktop.Win.csproj"
        OutputFolder   = "Win-x86"
        ZipName        = "Remotely-Win-x86.zip"
        HasDesktop     = $true
    },
    @{
        Name           = "linux-x64"
        Runtime        = "linux-x64"
        AgentProject   = "Agent\Agent.csproj"
        DesktopProject = "Desktop.Linux\Desktop.Linux.csproj"
        OutputFolder   = "Linux-x64"
        ZipName        = "Remotely-Linux.zip"
        HasDesktop     = $true
    },
    @{
        Name           = "osx-x64"
        Runtime        = "osx-x64"
        AgentProject   = "Agent\Agent.csproj"
        DesktopProject = $null
        OutputFolder   = "MacOS-x64"
        ZipName        = "Remotely-MacOS-x64.zip"
        HasDesktop     = $false
    },
    @{
        Name           = "osx-arm64"
        Runtime        = "osx-arm64"
        AgentProject   = "Agent\Agent.csproj"
        DesktopProject = $null
        OutputFolder   = "MacOS-arm64"
        ZipName        = "Remotely-MacOS-arm64.zip"
        HasDesktop     = $false
    }
)

# Filter platforms if specified
if ($PlatformsOnly) {
    $SelectedPlatforms = $PlatformsOnly -split ','
    $Platforms = $Platforms | Where-Object { $SelectedPlatforms -contains $_.Runtime }
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Build-Platform {
    param($Platform)
    
    Write-ColorOutput "`n========================================" "Cyan"
    Write-ColorOutput "Building $($Platform.Name)..." "Cyan"
    Write-ColorOutput "========================================" "Cyan"
    
    $BuildOutput = Join-Path $TempDir $Platform.OutputFolder
    
    # Clean output directory
    if (Test-Path $BuildOutput) {
        Remove-Item -Path $BuildOutput -Recurse -Force
    }
    New-Item -ItemType Directory -Path $BuildOutput -Force | Out-Null
    
    # Build Agent
    Write-ColorOutput "  [1/3] Building Agent..." "Yellow"
    $AgentPath = Join-Path $SolutionDir $Platform.AgentProject
    
    dotnet publish $AgentPath `
        -c Release `
        -r $Platform.Runtime `
        --self-contained `
        -o $BuildOutput `
        /p:PublishSingleFile=false `
        /p:DebugType=None `
        /p:DebugSymbols=false
    
    if ($LASTEXITCODE -ne 0) {
        throw "Agent build failed for $($Platform.Name)"
    }
    
    # Build Desktop Client if applicable
    if ($Platform.HasDesktop -and $Platform.DesktopProject) {
        Write-ColorOutput "  [2/3] Building Desktop Client..." "Yellow"
        $DesktopPath = Join-Path $SolutionDir $Platform.DesktopProject
        $DesktopOutput = Join-Path $BuildOutput "Desktop"
        
        dotnet publish $DesktopPath `
            -c Release `
            -r $Platform.Runtime `
            --self-contained `
            -o $DesktopOutput `
            /p:PublishSingleFile=false `
            /p:DebugType=None `
            /p:DebugSymbols=false
        
        if ($LASTEXITCODE -ne 0) {
            throw "Desktop build failed for $($Platform.Name)"
        }
    }
    else {
        Write-ColorOutput "  [2/3] Skipping Desktop Client (not applicable)" "Gray"
    }
    
    # Create ZIP package
    Write-ColorOutput "  [3/3] Creating ZIP package..." "Yellow"
    $ZipPath = Join-Path $OutputDir $Platform.ZipName
    
    if (Test-Path $ZipPath) {
        Remove-Item -Path $ZipPath -Force
    }
    
    Compress-Archive -Path "$BuildOutput\*" -DestinationPath $ZipPath -Force
    
    $ZipSize = (Get-Item $ZipPath).Length / 1MB
    $ZipSizeMB = [math]::Round($ZipSize, 2)
    Write-ColorOutput "  Package created: $($Platform.ZipName) ($ZipSizeMB MB)" "Green"
}

# Main execution
try {
    Write-ColorOutput "`n========================================" "Magenta"
    Write-ColorOutput "  Remote Desktop Client Builder" "Magenta"
    Write-ColorOutput "========================================" "Magenta"
    
    # Verify we're in the correct directory
    if (!(Test-Path (Join-Path $SolutionDir "Remotely.sln"))) {
        throw "Solution file not found. Please run this script from the solution directory."
    }
    
    # Create output directories
    if (!(Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    if (!(Test-Path $TempDir)) {
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    }
    
    # Build each platform
    $SuccessCount = 0
    $FailCount = 0
    
    foreach ($Platform in $Platforms) {
        try {
            Build-Platform -Platform $Platform
            $SuccessCount++
        }
        catch {
            Write-ColorOutput "  Build failed: $_" "Red"
            $FailCount++
        }
    }
    
    # Cleanup temp directory
    if (!$SkipCleanup -and (Test-Path $TempDir)) {
        Write-ColorOutput "`nCleaning up temporary files..." "Gray"
        Remove-Item -Path $TempDir -Recurse -Force
    }
    
    # Summary
    Write-ColorOutput "`n========================================" "Cyan"
    Write-ColorOutput "Build Summary" "Cyan"
    Write-ColorOutput "========================================" "Cyan"
    Write-ColorOutput "  Successful: $SuccessCount" "Green"
    Write-ColorOutput "  Failed: $FailCount" "Red"
    Write-ColorOutput "  Output: $OutputDir" "White"
    
    if ($FailCount -eq 0) {
        Write-ColorOutput "`nAll builds completed successfully!" "Green"
        
        Write-ColorOutput "`nNext Steps:" "Yellow"
        Write-ColorOutput "  1. Copy the installers to your IIS server's wwwroot/Content folder" "White"
        Write-ColorOutput "  2. Update the installation scripts with your server URL" "White"
        Write-ColorOutput "  3. Deploy to client systems" "White"
    }
    else {
        Write-ColorOutput "`nSome builds failed. Check the errors above." "Yellow"
        exit 1
    }
}
catch {
    Write-ColorOutput "`nBuild process failed: $_" "Red"
    Write-ColorOutput $_.ScriptStackTrace "Red"
    exit 1
}
