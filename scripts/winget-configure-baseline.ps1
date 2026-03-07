# Requires -Version 5.1
# Step: 00-winget-configure.ps1
# Compatible with Windows PowerShell 5.1
# https://learn.microsoft.com/en-us/windows/package-manager/configuration/
# https://woshub.com/winget-dsc-configure/
# https://learn.microsoft.com/en-us/windows/package-manager/configuration/create

param(
    [Parameter(Mandatory=$true)][string]$RepoRoot,
    [switch]$WhatIf,
    [switch]$DisableInteractivity,
    [switch]$VerboseWinget
)

Write-Host ""
Write-Host "==============================="
Write-Host "Running winget-configure.ps1"
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "==============================="
Write-Host ""

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Write-Host ("PowerShell: {0}  Edition: {1}" -f $PSVersionTable.PSVersion, $PSVersionTable.PSEdition)

function Get-WingetExe {
    $exe = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
    if (-not (Test-Path $exe)) { throw "winget not found. Install/repair 'App Installer' then rerun." }
    return $exe
}

$cfgPath = Join-Path $RepoRoot ".config\baseline.dsc.winget"
if (-not (Test-Path $cfgPath)) { throw "Missing config file: $cfgPath" }

$winget = Get-WingetExe

$args = @("configure", "-f", $cfgPath, "--accept-configuration-agreements")
if ($WhatIf) { $args += "--what-if" }
if ($DisableInteractivity) { $args += "--disable-interactivity" }
if ($VerboseWinget) { $args += "--verbose-logs" }

Write-Host "Running: winget $($args -join ' ')"
& $winget @args

if ($LASTEXITCODE -ne 0) {
    throw "winget configure failed (exit $LASTEXITCODE)"
}