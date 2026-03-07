#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ScriptSet = "",
    [string]$TestParam = ""
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: winget-configure-enable.ps1"
Write-Host "Description: Enable winget configuration."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "ScriptSet: $ScriptSet"
Write-Host "TestParam: $TestParam"
Write-Host "=============================================================="
Write-Host ""

winget configure --enable

Start-Sleep -Seconds 1