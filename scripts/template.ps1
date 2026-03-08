#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ScriptSet = "",
    [string]$TestParam = ""
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: template.ps1"
Write-Host "Description: Simple template script."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "ScriptSet: $ScriptSet"
Write-Host "TestParam: $TestParam"
Write-Host "=============================================================="
Write-Host ""

function Get-IsoRoot {
    $drives = Get-PSDrive -PSProvider FileSystem

    foreach ($drive in $drives) {
        $autounattendFile = Join-Path -Path $drive.Root -ChildPath "autounattend.xml"
        $versionMarker = Join-Path -Path $drive.Root -ChildPath "unattend.version.txt"

        if ((Test-Path -Path $autounattendFile) -and (Test-Path -Path $versionMarker)) {
            return $drive.Root
        }
    }

    return $null
}

# Example usage of Get-IsoRoot function
$isoRoot = Get-IsoRoot
if ([string]::IsNullOrWhiteSpace($isoRoot)) {
    Write-Host "ISO media root not found."
} else {
    Write-Host "ISO media root found at: $isoRoot"
}

Start-Sleep -Seconds 1