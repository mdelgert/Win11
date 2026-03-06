# 01-user-once-source.ps1 - Download and run source from the repository
#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# https://schneegans.de/windows/unattend-generator/
# Will be called from autounattend.xml as first user script, will download the repository, extract it and run the setup script
# C:\Windows\Setup\Scripts\unattend-01.ps1

# Configuration
$repoZip = "https://github.com/mdelgert/win11/archive/refs/heads/main.zip"
$dest = "C:\Setup"
$zipFile = Join-Path -Path $dest -ChildPath "repo.zip"
$log = Join-Path -Path $dest -ChildPath "logs\autounattend.log"

# Remove existing dest folder if it exists to ensure a clean state
if (Test-Path -Path $dest) {
    Remove-Item -Path $dest -Recurse -Force
}

# Ensure logs directory exists
$logDir = Split-Path -Path $log -Parent
if (-not (Test-Path -Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp $Message"
    Write-Host $logEntry
    Add-Content -Path $log -Value $logEntry -ErrorAction SilentlyContinue
}

function Test-NetworkReady {
    param(
        [string]$HostName = "github.com",
        [int]$Port = 443,
        [int]$TimeoutSeconds = 300,
        [int]$RetryIntervalSeconds = 5
    )
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $asyncResult = $tcpClient.BeginConnect($HostName, $Port, $null, $null)
            $wait = $asyncResult.AsyncWaitHandle.WaitOne(3000, $false)
            if ($wait -and $tcpClient.Connected) {
                $tcpClient.Close()
                return $true
            }
            $tcpClient.Close()
        }
        catch {
            # Connection failed, will retry
        }
        Start-Sleep -Seconds $RetryIntervalSeconds
    }
    return $false
}

# Main execution
try {
    Write-Log "Bootstrap starting"

    # Wait for network connectivity
    Write-Log "Waiting for network connectivity..."
    if (-not (Test-NetworkReady)) {
        throw "Network connectivity timeout - unable to reach github.com"
    }
    Write-Log "Network ready"

    # Enable TLS 1.2 for secure downloads
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Download repository
    Write-Log "Downloading repository zip"
    Invoke-WebRequest -Uri $repoZip -OutFile $zipFile -UseBasicParsing -ErrorAction Stop

    # Extract repository
    Write-Log "Extracting repository"
    Expand-Archive -Path $zipFile -DestinationPath $dest -Force -ErrorAction Stop

    # Rename extracted folder from win11-main to win11
    $extractedFolder = Join-Path -Path $dest -ChildPath "win11-main"
    $repoFolder = Join-Path -Path $dest -ChildPath "win11"
    
    if (Test-Path -Path $extractedFolder) {
        if (Test-Path -Path $repoFolder) {
            Remove-Item -Path $repoFolder -Recurse -Force
        }
        Rename-Item -Path $extractedFolder -NewName "win11" -Force
        Write-Log "Renamed folder to win11"
    }

    # Remove the zip file after extraction
    # if (Test-Path -Path $zipFile) {
    #     Remove-Item -Path $zipFile -Force -ErrorAction SilentlyContinue
    # }

    # Run setup script
    $setupScript = Join-Path -Path $repoFolder -ChildPath "setup.ps1"

    if (Test-Path -Path $setupScript) {
        Write-Log "Running setup.ps1"
        & powershell.exe -ExecutionPolicy Bypass -File $setupScript
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            Write-Log "setup.ps1 exited with code: $exitCode"
        }
    }
    else {
        throw "Setup script not found: $setupScript"
    }

    Write-Log "Bootstrap finished successfully"
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}