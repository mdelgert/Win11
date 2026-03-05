#Requires -Version 5.1
# =========================================
# Win11 Machine Setup (PS 5.1 compatible)
#
# Main entrypoint: setup.ps1 (repo root)
#
# Folder layout:
#   setup.ps1
#   steps\
#       00-winget-configure.ps1
#       10-*.ps1
#       20-*.ps1
#   .config\
#       baseline.dsc.winget
#
# Notes:
# - Steps run in the order listed in $Steps (no auto-discovery).
# - Designed to be robust under Set-StrictMode.
# - Step failure is detected by exceptions (PowerShell) and/or exit codes (native EXEs).
# =========================================

param(
    [switch]$WhatIf,
    [switch]$DisableInteractivity,
    [switch]$VerboseWinget
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Folder containing ordered step scripts
$StepsDir = Join-Path $PSScriptRoot "steps"

# Ordered list of steps to run (filenames only)
$Steps = @(
    # "00-winget-configure.ps1"
    "10-step1.ps1"
    "20-step2.ps1"
    "30-step3.ps1"
)

function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) { throw "Run in an elevated PowerShell (Run as Administrator)." }
}

function Ensure-Folder([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-Header([string]$RepoRoot, [string]$StepsDir, [string]$LogFile) {
    Write-Host "RepoRoot: $RepoRoot"
    Write-Host "StepsDir: $StepsDir"
    Write-Host "LogFile:  $LogFile"
    Write-Host ("PowerShell: {0}  Edition: {1}" -f $PSVersionTable.PSVersion, $PSVersionTable.PSEdition)
}

function Invoke-StepScript {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$StepName,
        [Parameter(Mandatory=$true)][string]$RepoRoot,
        [switch]$WhatIf,
        [switch]$DisableInteractivity,
        [switch]$VerboseWinget
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing step: $Path"
    }

    Write-Host ""
    Write-Host "=== Running step: $StepName ==="

    # Under StrictMode, $LASTEXITCODE may be undefined unless a native EXE runs.
    # Capture whether it's defined BEFORE running the step.
    $hadLastExitCode = Test-Path variable:LASTEXITCODE
    $prevLastExitCode = if ($hadLastExitCode) { $global:LASTEXITCODE } else { $null }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        & $Path `
            -RepoRoot $RepoRoot `
            -WhatIf:$WhatIf `
            -DisableInteractivity:$DisableInteractivity `
            -VerboseWinget:$VerboseWinget

        # If the step threw, we'd be in catch. Reaching here means PowerShell side succeeded.
    }
    catch {
        $sw.Stop()
        Write-Host ("!!! Step threw an error: {0} ({1}s)" -f $StepName, [int]$sw.Elapsed.TotalSeconds)
        throw
    }

    $sw.Stop()

    # If the step ran a native EXE and set LASTEXITCODE, detect non-zero exit.
    if (Test-Path variable:LASTEXITCODE) {
        $currentExit = $global:LASTEXITCODE

        # Only treat it as a failure if it changed during this step and is non-zero.
        # This avoids false failures when a previous step left LASTEXITCODE set.
        $changed =
            (-not $hadLastExitCode) -or
            ($prevLastExitCode -ne $currentExit)

        if ($changed -and $currentExit -ne 0) {
            throw "Step failed: $StepName (native exit $currentExit)"
        }
    }

    Write-Host ("--- Step complete: {0} ({1}s)" -f $StepName, [int]$sw.Elapsed.TotalSeconds)
}

# --------- MAIN ---------
Assert-Admin

$RepoRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path

# Logs outside the repo
$LogRoot  = "C:\ProgramData\Win11Setup\Logs"
Ensure-Folder $LogRoot

$runId   = (Get-Date).ToString("yyyyMMdd-HHmmss")
$logFile = Join-Path $LogRoot "setup-$runId.log"

Start-Transcript -Path $logFile -Append | Out-Null

try {
    Write-Header -RepoRoot $RepoRoot -StepsDir $StepsDir -LogFile $logFile

    # Fail fast if steps folder is missing
    if (-not (Test-Path -LiteralPath $StepsDir)) {
        throw "Steps folder not found: $StepsDir"
    }

    foreach ($step in $Steps) {
        $path = Join-Path $StepsDir $step

        Invoke-StepScript `
            -Path $path `
            -StepName $step `
            -RepoRoot $RepoRoot `
            -WhatIf:$WhatIf `
            -DisableInteractivity:$DisableInteractivity `
            -VerboseWinget:$VerboseWinget
    }

    Write-Host ""
    Write-Host "Setup complete."
}
catch {
    Write-Host ""
    Write-Host "SETUP FAILED."
    Write-Host $_.Exception.ToString()
    throw
}
finally {
    try { Stop-Transcript | Out-Null } catch {}
    Write-Host "Log saved: $logFile"
}