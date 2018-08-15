# escape=`

# Stage 0: prepare files
FROM microsoft/aspnet:4.7.2-windowsservercore-1803 AS prepare

ARG SITECORE_PACKAGE
ARG XCONNECT_PACKAGE

SHELL ["powershell", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';"]

ADD files/ /Files/
ADD scripts/ /Scripts/

RUN /Scripts/Expand-Zip.ps1 -FileName "/Files/$Env:SITECORE_PACKAGE" -OutputDir '/Files/Output' -Regex '.dacpac$'; `
    /Scripts/Expand-Zip.ps1 -FileName "/Files/$Env:XCONNECT_PACKAGE" -OutputDir '/Files/Output' -Regex '.dacpac$'; `
    /Scripts/Expand-Zip.ps1 -FileName "/Files/$Env:XCONNECT_PACKAGE" -OutputDir '/Files/Output/SqlShardingDeploymentTool' -Regex 'collectiondeployment';

# Stage 1: create actual image
FROM microsoft/mssql-server-windows-express:2016-sp1-windowsservercore-10.0.14393.1715

SHELL ["powershell", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';"]

ARG DB_PREFIX
ARG HOST_NAME

ENV ACCEPT_EULA "Y"

# Add files
COPY --from=prepare /Files/Output/ /Files/
COPY --from=prepare /Scripts/Install-Databases.ps1 /Scripts/Install-Databases.ps1

# Install databases

RUN /Scripts/Install-Databases.ps1 `
        -SQL_package_exe '\Program Files (x86)\Microsoft SQL Server\*\DAC\bin\SqlPackage.exe' `
        -SQL_sharding_tool '\Files\SqlShardingDeploymentTool\Sitecore.Xdb.Collection.Database.SqlShardingDeploymentTool.exe' `
        -DB_Prefix $env:DB_PREFIX `
        -Verbose; `
     Remove-Item \Files -Recurse -Force; `
     Remove-Item \Scripts -Recurse -Force;