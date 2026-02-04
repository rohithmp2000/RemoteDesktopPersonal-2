# Fix IIS 500 Error (Duplicate MIME Types)
# Run this on the SERVER

Write-Host "Fixing web.config (Duplicate MIME Types)..." -ForegroundColor Cyan

$webConfigPath = "C:\inetpub\RemoteDesktop\web.config"

# Create robust web.config with <remove> tags
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
        <!-- Remove potential duplicates first to avoid 500.19 errors -->
        <remove fileExtension=".js" />
        <mimeMap fileExtension=".js" mimeType="application/javascript" />
        
        <remove fileExtension=".json" />
        <mimeMap fileExtension=".json" mimeType="application/json" />
        
        <remove fileExtension=".zip" />
        <mimeMap fileExtension=".zip" mimeType="application/octet-stream" />
        
        <remove fileExtension=".ps1" />
        <mimeMap fileExtension=".ps1" mimeType="application/octet-stream" />
        
        <remove fileExtension=".sh" />
        <mimeMap fileExtension=".sh" mimeType="application/octet-stream" />
        
        <remove fileExtension=".vue" />
        <mimeMap fileExtension=".vue" mimeType="application/javascript" />
      </staticContent>
      
      <security>
        <requestFiltering>
          <requestLimits maxAllowedContentLength="3221225472" />
        </requestFiltering>
      </security>
    </system.webServer>
  </location>
  
  <!-- Allow direct access to Content folder -->
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

$webConfigContent | Out-File $webConfigPath -Encoding UTF8

# Restart IIS
iisreset

Write-Host "`nWeb.config fixed!" -ForegroundColor Green
Write-Host "The <remove> tags prevent 'Duplicate MIME Type' errors." -ForegroundColor Cyan
