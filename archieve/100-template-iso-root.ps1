#Requires -Version 5.1
Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: 100-template-iso-root.ps1"
Write-Host "Description: Template for future scripts. Copy and paste this code into a new .ps1 file and modify as needed."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "=============================================================="
Write-Host ""

function Get-IsoRoot {
    $drives = Get-PSDrive -PSProvider FileSystem

    foreach ($drive in $drives) {
        $versionMarker = Join-Path $drive.Root "unattend.version.txt"
        $autounattendMarker = Join-Path $drive.Root "autounattend.xml"
        
        if ((Test-Path -Path $versionMarker) -and (Test-Path -Path $autounattendMarker)) {
            return $drive.Root
        }
    }

    return $null
}

$isoRoot = Get-IsoRoot

Write-Host "ISO Root Directory: $isoRoot"

# Start-Sleep -Seconds 2