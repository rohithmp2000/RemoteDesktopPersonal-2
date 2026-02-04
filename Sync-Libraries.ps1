# Sync Libraries using Robocopy
# Run this as ADMINISTRATOR

$sourceDir = "D:\Rohith Personal\Remote Desktop Personal-2\Server\wwwroot\lib"
$destDir = "C:\inetpub\RemoteDesktop\wwwroot\lib"

Write-Host "Syncing libraries from Source to IIS..." -ForegroundColor Cyan
Write-Host "Source: $sourceDir"
Write-Host "Dest:   $destDir"

# Use Robocopy to mirror the lib folder
# /E = recursive
# /IS = include same files (to be safe)
# /IT = include tweaked files
# /NJH = No Job Header
# /NJS = No Job Summary (cleaner output)
# /NP = No Progress bar (cleaner logs)

robocopy "$sourceDir" "$destDir" /E /IS /IT /NP

if ($LASTEXITCODE -lt 8) {
    Write-Host "`n✅ Sync Complete!" -ForegroundColor Green
    Write-Host "Refresh your browser and test remote control." -ForegroundColor Cyan
}
else {
    Write-Host "`n❌ Robocopy reported errors. Check permissions." -ForegroundColor Red
}
