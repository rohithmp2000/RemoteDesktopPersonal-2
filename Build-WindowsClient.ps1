# Simple Client Builder
# Builds Windows x64 client only (most common)

$ErrorActionPreference = "Stop"

$SolutionDir = "d:\Rohith Personal\Remote Desktop Personal-2"
$OutputDir = Join-Path $SolutionDir "Server\wwwroot\Content"
$TempDir = Join-Path $SolutionDir "BuildTemp\Win-x64"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Building Windows x64 Client" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

try {
    # Clean temp directory
    if (Test-Path $TempDir) {
        Write-Host "Cleaning temp directory..." -ForegroundColor Yellow
        Remove-Item -Path $TempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    
    # Build Agent
    Write-Host "[1/3] Building Agent..." -ForegroundColor Yellow
    dotnet publish "$SolutionDir\Agent\Agent.csproj" `
        -c Release `
        -r win-x64 `
        --self-contained `
        -o $TempDir `
        /p:PublishSingleFile=false `
        /p:DebugType=None `
        /p:DebugSymbols=false
    
    if ($LASTEXITCODE -ne 0) {
        throw "Agent build failed"
    }
    
    # Build Desktop Client
    Write-Host "[2/3] Building Desktop Client..." -ForegroundColor Yellow
    $DesktopOutput = Join-Path $TempDir "Desktop"
    dotnet publish "$SolutionDir\Desktop.Win\Desktop.Win.csproj" `
        -c Release `
        -r win-x64 `
        --self-contained `
        -o $DesktopOutput `
        /p:PublishSingleFile=false `
        /p:DebugType=None `
        /p:DebugSymbols=false
    
    if ($LASTEXITCODE -ne 0) {
        throw "Desktop build failed"
    }
    
    # Create ZIP package
    Write-Host "[3/3] Creating ZIP package..." -ForegroundColor Yellow
    $ZipPath = Join-Path $OutputDir "Remotely-Win-x64.zip"
    
    if (Test-Path $ZipPath) {
        Remove-Item -Path $ZipPath -Force
    }
    
    Compress-Archive -Path "$TempDir\*" -DestinationPath $ZipPath -Force
    
    $ZipSize = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
    Write-Host "`nSUCCESS! Package created: Remotely-Win-x64.zip ($ZipSize MB)" -ForegroundColor Green
    Write-Host "Location: $ZipPath" -ForegroundColor Green
    
    # Cleanup
    Write-Host "`nCleaning up temp files..." -ForegroundColor Gray
    Remove-Item -Path (Join-Path $SolutionDir "BuildTemp") -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "`nDone! The client package is ready for deployment." -ForegroundColor Green
}
catch {
    Write-Host "`nERROR: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
