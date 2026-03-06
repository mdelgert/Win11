Write-Host ""
Write-Host "==============================="
Write-Host "Running step 00-autologon-download.ps1"
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "==============================="
Write-Host ""

# Configuration
$autoLogonUrl = "https://download.sysinternals.com/files/AutoLogon.zip"
$downloadPath = "C:\Setup"
$zipFile = Join-Path -Path $downloadPath -ChildPath "AutoLogon.zip"
$extractPath = Join-Path -Path $downloadPath -ChildPath "AutoLogon"

# Ensure download directory exists
if (-not (Test-Path -Path $downloadPath)) {
    New-Item -ItemType Directory -Path $downloadPath -Force | Out-Null
}

# Enable TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Download AutoLogon
Write-Host "Downloading AutoLogon from Sysinternals..."
try {
    Invoke-WebRequest -Uri $autoLogonUrl -OutFile $zipFile -UseBasicParsing -ErrorAction Stop
    Write-Host "Download complete: $zipFile"
}
catch {
    Write-Host "ERROR: Failed to download AutoLogon - $($_.Exception.Message)"
    exit 1
}

# Extract AutoLogon
Write-Host "Extracting AutoLogon..."
try {
    if (Test-Path -Path $extractPath) {
        Remove-Item -Path $extractPath -Recurse -Force
    }
    Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force -ErrorAction Stop
    Write-Host "Extracted to: $extractPath"
}
catch {
    Write-Host "ERROR: Failed to extract AutoLogon - $($_.Exception.Message)"
    exit 1
}

Write-Host "AutoLogon setup complete"
