#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ScriptSet = "",
    [string]$TestParam = ""
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: git-config.ps1"
Write-Host "Description: Setup Git."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "ScriptSet: $ScriptSet"
Write-Host "TestParam: $TestParam"
Write-Host "=============================================================="
Write-Host ""

git config --global user.name "Matthew Elgert"  
git config --global user.email mdelgert@yahoo.com
git config --list

Start-Sleep -Seconds 1