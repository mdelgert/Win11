#Requires -Version 5.1
<#
File: 100-template.ps1

Purpose:
  Template for future child scripts that are called by setup.ps1.

How this template is intended to be used:
  - Copy this file to a new script in the .\scripts folder
  - Rename it to match the ordering you want, for example:
      10-base.ps1
      20-tools.ps1
      30-post-reboot.ps1
  - Replace the example logic with the real work for that script

Expected caller:
  This script is intended to be called by setup.ps1, which may pass:
    -RepoRoot
    -WhatIf
    -DisableInteractivity
    -VerboseWinget

Why these parameters are included:
  Keeping a consistent parameter pattern across child scripts makes it easier
  for setup.ps1 to call all scripts the same way.

Test parameter:
  -TestParam is included so you can quickly verify that parameter passing works.

Typical manual test:
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\100-template.ps1 -TestParam hello

Example launcher-style test:
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\100-template.ps1 `
    -RepoRoot C:\Setup\win11 `
    -WhatIf `
    -DisableInteractivity `
    -VerboseWinget:$false `
    -TestParam hello

Suggested conventions for new scripts:
  - Keep each script focused on one job
  - Throw on failure instead of silently continuing
  - Prefer small helper functions over repeated code
  - Write clear console messages so transcript logs are useful
  - If a reboot is required, let setup.ps1 resume with another ScriptSet
  - Avoid PowerShell 7+ features so the script remains 5.1 compatible

Notes:
  - This script currently only prints values and sleeps for 1 second
  - Safe to use as a starting point for future scripts
#>

[CmdletBinding()]
param(
    [string]$RepoRoot = "",
    [switch]$WhatIf,
    [switch]$DisableInteractivity,
    [switch]$VerboseWinget,
    [string]$TestParam = "",
    [string]$ScriptSet = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host ""
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: 100-template.ps1"
Write-Host "Description: Template for future child scripts."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "RepoRoot: $RepoRoot"
Write-Host "WhatIf: $WhatIf"
Write-Host "DisableInteractivity: $DisableInteractivity"
Write-Host "VerboseWinget: $VerboseWinget"
Write-Host "TestParam: $TestParam"
Write-Host "ScriptSet: $ScriptSet"
Write-Host "=============================================================="
Write-Host ""

Write-Section "Template script starting"

if ($WhatIf) {
    Write-Host "WhatIf flag is set."
}

if ($DisableInteractivity) {
    Write-Host "DisableInteractivity flag is set."
}

if ($VerboseWinget) {
    Write-Host "VerboseWinget flag is set."
}

if (-not [string]::IsNullOrWhiteSpace($TestParam)) {
    Write-Host "Received TestParam value: $TestParam"
}
else {
    Write-Host "No TestParam value was provided."
}

Start-Sleep -Seconds 1

Write-Section "Template script completed successfully"