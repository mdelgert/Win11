#Requires -Version 5.1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: git-install.ps1"
Write-Host "Description: Winget script to install Git."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "ScriptSet: $ScriptSet"
Write-Host "TestParam: $TestParam"
Write-Host "=============================================================="
Write-Host ""



Start-Sleep -Seconds 1