#Requires -Version 5.1
Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: 99-copy-source.ps1"
Write-Host "Description: Script to copy/refresh source files from the repository."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "=============================================================="
Write-Host ""

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

    $extractedFolder = Join-Path -Path $dest -ChildPath "win11-main"

    # Run setup script
    $setupScript = Join-Path -Path $extractedFolder -ChildPath "setup.ps1"

    # Print script path
    Write-Log "Setup script path: $setupScript"

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