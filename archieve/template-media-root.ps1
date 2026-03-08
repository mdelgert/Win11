#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ScriptSet = "",
    [string]$TestParam = ""
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: template-media-root.ps1"
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
        $versionMarker = Join-Path $drive.Root "media.version.txt"
        
        if (Test-Path -Path $versionMarker) {
            return $drive.Root
        }
    }

    return $null
}

Write-Host "Searching for ISO root directory..."
$isoRoot = Get-IsoRoot

Write-Host "ISO root directory: $isoRoot"

Start-Sleep -Seconds 1