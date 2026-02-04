# Fix MessagePack 500 Error
# Run this on the SERVER as Administrator

Write-Host "Fixing web.config to serve JavaScript files..." -ForegroundColor Cyan

$webConfigPath = "C:\inetpub\RemoteDesktop\web.config"
$webConfigBackup = "C:\inetpub\RemoteDesktop\web.config.backup2"

# Backup existing web.config
Copy-Item $webConfigPath $webConfigBackup -Force
Write-Host "Backed up web.config" -ForegroundColor Green

# Create proper web.config
$webConfigContent = @'
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
        <mimeMap fileExtension=".js" mimeType="application/javascript" />
        <mimeMap fileExtension=".json" mimeType="application/json" />
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
'@

# Save new web.config
$webConfigContent | Out-File $webConfigPath -Encoding UTF8
Write-Host "Updated web.config" -ForegroundColor Green

# Restart IIS
Write-Host "Restarting IIS..." -ForegroundColor Yellow
iisreset | Out-Null

Start-Sleep -Seconds 5

Write-Host "`nDone! Try remote control again." -ForegroundColor Cyan
Write-Host "The msgpack.min.js file should now load correctly." -ForegroundColor Green
