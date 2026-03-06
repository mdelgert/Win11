# unattend-01.ps1
#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# Purpose:
#   Copy the repo bundled inside the unattend ISO to C:\Setup\win11
#   and run setup.ps1 from the local copied folder.
#
# Expected ISO layout:
#   <ISO ROOT>\autounattend.xml
#   <ISO ROOT>\version.txt
#   <ISO ROOT>\repo\setup.ps1
#
# Example destination after copy:
#   C:\Setup\win11\setup.ps1
#
# Logs:
#   C:\Setup\logs\autounattend.log
#   C:\Setup\logs\autounattend-transcript.log
#
# Notes:
#   - No network required
#   - No Git required
#   - Safe for repeated runs
#   - Intended to be called from autounattend.xml as a first-logon script

$destRoot       = "C:\Setup"
$repoFolder     = Join-Path $destRoot "win11"
$logDir         = Join-Path $destRoot "logs"
$logFile        = Join-Path $logDir "autounattend.log"
$transcriptFile = Join-Path $logDir "autounattend-transcript.log"

function New-FolderIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    New-FolderIfMissing -Path $logDir

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp $Message"

    Write-Host $entry
    Add-Content -Path $logFile -Value $entry -ErrorAction SilentlyContinue
}

function Get-IsoRoot {
    $drives = Get-PSDrive -PSProvider FileSystem

    foreach ($drive in $drives) {
        $marker = Join-Path $drive.Root "autounattend.xml"
        if (Test-Path -Path $marker) {
            return $drive.Root
        }
    }

    return $null
}

$transcriptStarted = $false

try {
    New-FolderIfMissing -Path $destRoot
    New-FolderIfMissing -Path $logDir

    Start-Transcript -Path $transcriptFile -Append | Out-Null
    $transcriptStarted = $true

    Write-Log "Bootstrap starting"

    $isoRoot = Get-IsoRoot
    if (-not $isoRoot) {
        throw "Could not locate ISO drive containing autounattend.xml"
    }

    Write-Log "ISO root found at: $isoRoot"

    $sourceRepo = Join-Path $isoRoot "repo"
    if (-not (Test-Path -Path $sourceRepo)) {
        throw "Repo folder not found on ISO: $sourceRepo"
    }

    $setupScript = Join-Path $sourceRepo "setup.ps1"
    if (-not (Test-Path -Path $setupScript)) {
        throw "setup.ps1 not found in ISO repo folder: $setupScript"
    }

    if (Test-Path -Path $repoFolder) {
        Write-Log "Removing existing destination folder: $repoFolder"
        Remove-Item -Path $repoFolder -Recurse -Force
    }

    Write-Log "Copying repo from $sourceRepo to $repoFolder"
    Copy-Item -Path $sourceRepo -Destination $repoFolder -Recurse -Force

    $localSetupScript = Join-Path $repoFolder "setup.ps1"
    if (-not (Test-Path -Path $localSetupScript)) {
        throw "setup.ps1 not found after copy: $localSetupScript"
    }

    $versionFile = Join-Path $isoRoot "version.txt"
    if (Test-Path -Path $versionFile) {
        $version = Get-Content -Path $versionFile -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($version) {
            Write-Log "ISO version: $version"
        }
    }

    Write-Log "Running setup.ps1"
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $localSetupScript

    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "setup.ps1 exited with code ${exitCode}"
    }

    Write-Log "Bootstrap finished successfully"

    if ($transcriptStarted) {
        Stop-Transcript | Out-Null
        $transcriptStarted = $false
    }

    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"

    if ($transcriptStarted) {
        Stop-Transcript | Out-Null
        $transcriptStarted = $false
    }

    exit 1
}