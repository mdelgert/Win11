#Requires -Version 5.1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: winget-update.ps1"
Write-Host "Description: Upgrade Winget from local ISO media."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "=============================================================="
Write-Host ""

function Get-IsoRoot {
    $drives = Get-PSDrive -PSProvider FileSystem

    foreach ($drive in $drives) {
        $versionMarker = Join-Path $drive.Root "unattend.version.txt"
        
        if (Test-Path -Path $versionMarker) {
            return $drive.Root
        }
    }

    return $null
}

$isoRoot = Get-IsoRoot
$installerPath = Join-Path $isoRoot "media\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

try {
    if (-not (Test-Path -Path $installerPath)) {
        throw "Installer not found: $installerPath"
    }

    Write-Host "Installing Winget silently from: $installerPath"
    Add-AppxPackage -Path $installerPath -ForceApplicationShutdown -ForceUpdateFromAnyVersion -ErrorAction Stop

    $wingetCommand = Get-Command -Name winget.exe -ErrorAction SilentlyContinue
    if ($wingetCommand) {
        Write-Host "Winget install/update complete. Command path: $($wingetCommand.Source)"
    }
    else {
        Write-Host "Install completed, but winget is not yet visible in this session. A sign-out or reboot may be required."
    }
}
catch {
    Write-Host "Winget update failed: $($_.Exception.Message)"
    exit 1
}