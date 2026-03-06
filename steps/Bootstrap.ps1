# Bootstrap.ps1 - Download and run the setup script from the repository
# Requires -Version 5.1
$ErrorActionPreference = "Stop"

$repoZip = "https://github.com/mdelgert/win11/archive/refs/heads/main.zip"
$zipFile = "C:\Setup\repo.zip"
$dest    = "C:\Setup"
$log     = "C:\Setup\bootstrap.log"

function Log($msg){
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time $msg" | Tee-Object -FilePath $log -Append
}

Log "Bootstrap starting"

# wait for network
Log "Waiting for network"
while (!(Test-NetConnection github.com -Port 443 -InformationLevel Quiet)) {
    Start-Sleep 5
}

Log "Network ready"

# enable TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# download repo
Log "Downloading repo zip"
Invoke-WebRequest $repoZip -OutFile $zipFile -UseBasicParsing

# create destination
if (!(Test-Path $dest)){
    New-Item -ItemType Directory -Path $dest | Out-Null
}

Log "Extracting repo"
Expand-Archive $zipFile $dest -Force

$repoFolder = "$dest\win11-main"

Log "Running setup.ps1"
powershell -ExecutionPolicy Bypass -File "$repoFolder\setup.ps1"

Log "Bootstrap finished"