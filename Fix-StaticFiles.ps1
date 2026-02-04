# Fix Static Files - Run on Server as Administrator
# This configures IIS to serve ZIP files directly

Write-Host "Configuring IIS to serve static files..." -ForegroundColor Cyan

# 1. Update web.config to allow IIS to serve static files
$webConfigPath = "C:\inetpub\RemoteDesktop\web.config"
$webConfigBackup = "C:\inetpub\RemoteDesktop\web.config.backup"

# Backup existing web.config
Copy-Item $webConfigPath $webConfigBackup -Force

# Read current web.config
[xml]$webConfig = Get-Content $webConfigPath

# Add static content handling
$staticContentXml = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath="dotnet" 
                  arguments=".\Remotely.Server.dll" 
                  stdoutLogEnabled="true" 
                  stdoutLogFile=".\logs\stdout" 
                  hostingModel="inprocess">
        <environmentVariables>
          <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
        </environmentVariables>
      </aspNetCore>
      <staticContent>
        <mimeMap fileExtension=".zip" mimeType="application/octet-stream" />
        <mimeMap fileExtension=".ps1" mimeType="application/octet-stream" />
        <mimeMap fileExtension=".sh" mimeType="application/octet-stream" />
      </staticContent>
      <security>
        <requestFiltering>
          <requestLimits maxAllowedContentLength="3221225472" />
        </requestFiltering>
      </security>
    </system.webServer>
  </location>
  <location path="Content">
    <system.webServer>
      <handlers>
        <clear />
        <add name="StaticFile" path="*" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
      </handlers>
    </system.webServer>
  </location>
</configuration>
"@

# Save new web.config
$staticContentXml | Out-File $webConfigPath -Encoding UTF8

Write-Host "web.config updated" -ForegroundColor Green

# 2. Restart IIS
Write-Host "Restarting IIS..." -ForegroundColor Yellow
iisreset | Out-Null

Start-Sleep -Seconds 5

# 3. Test
Write-Host "`nTesting ZIP file access..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8585/Content/Remotely-Win-x64.zip" -Method Head -UseBasicParsing
    Write-Host "SUCCESS! ZIP file is now accessible." -ForegroundColor Green
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Content Length: $([math]::Round($response.Headers.'Content-Length'/1MB, 2)) MB" -ForegroundColor Green
}
catch {
    Write-Host "Still getting error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nRestoring backup..." -ForegroundColor Yellow
    Copy-Item $webConfigBackup $webConfigPath -Force
    iisreset | Out-Null
}

Write-Host "`nDone!" -ForegroundColor Cyan
