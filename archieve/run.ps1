# setup\run.ps1
# Simple runner: runs an ordered list of step scripts.
# Logs to: C:\ProgramData\Win11Setup\Logs

param(
    [switch]$WhatIf,
    [switch]$DisableInteractivity,
    [switch]$VerboseWinget
)

$ErrorActionPreference = "Stop"

# ====== STEP LIST (edit this only) ======
$Steps = @(
    "setup\steps\10-step1.ps1",
    "setup\steps\20-step2.ps1"
)
# =======================================

function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) { throw "Run in an elevated PowerShell (Run as Administrator)." }
}

function Ensure-Folder([string]$Path) {
    if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}

Assert-Admin

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$LogRoot  = "C:\ProgramData\Win11Setup\Logs"
Ensure-Folder $LogRoot

$runId   = (Get-Date).ToString("yyyyMMdd-HHmmss")
$logFile = Join-Path $LogRoot "setup-$runId.log"

Start-Transcript -Path $logFile -Append | Out-Null
Write-Host "RepoRoot: $RepoRoot"
Write-Host "LogFile:  $logFile"

try {
    foreach ($rel in $Steps) {
        $path = Join-Path $RepoRoot $rel
        if (-not (Test-Path $path)) { throw "Missing step: $path" }

        Write-Host ""
        Write-Host "=== Running step: $rel ==="

        # Pass runner flags down to each step script
        & $path -RepoRoot $RepoRoot -WhatIf:$WhatIf -DisableInteractivity:$DisableInteractivity -VerboseWinget:$VerboseWinget

        if ($LASTEXITCODE -ne 0) {
            throw "Step failed: $rel (exit $LASTEXITCODE)"
        }
    }

    Write-Host ""
    Write-Host "DONE."
}
finally {
    try { Stop-Transcript | Out-Null } catch {}
    Write-Host "Log saved: $logFile"
}