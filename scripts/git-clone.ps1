#Requires -Version 5.1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: git-clone.ps1"
Write-Host "Description: Clone the source repository."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "=============================================================="
Write-Host ""

# Clone the repository
$repoUrl = "https://github.com/mdelgert/win11.git"
$destinationPath = "C:\source\win11"

git clone $repoUrl $destinationPath

Start-Sleep -Seconds 1