#Requires -Version 5.1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: git-install.ps1"
Write-Host "Description: Winget script to install Git for Windows."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "ScriptSet: $ScriptSet"
Write-Host "TestParam: $TestParam"
Write-Host "=============================================================="
Write-Host ""

winget install Git.Git --source winget --silent --accept-source-agreements --accept-package-agreements 

Start-Sleep -Seconds 1