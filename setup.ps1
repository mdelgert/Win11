#Requires -Version 5.1
# =========================================
# Win11 Machine Setup (Windows PowerShell 5.1)
#
# - Main entrypoint: setup.ps1 (repo root)
# - Runs ordered step scripts from .\steps (explicit list, no auto-discovery)
# - Logs to: C:\ProgramData\Win11Setup\Logs
#
# IMPORTANT:
# This script must remain compatible with Windows PowerShell 5.1.
# Avoid PS 7+ features (e.g., ConvertFrom-Json -AsHashtable, ??, ForEach-Object -Parallel).
# =========================================

[CmdletBinding()]
param(
    [switch]$WhatIf,
    [switch]$DisableInteractivity,
    [switch]$VerboseWinget
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# ==========================
# USER CONFIG (edit here)
# ==========================
$StepsDirName = "steps"
$LogRoot      = "C:\ProgramData\Win11Setup\Logs"

# Ordered list of steps to run (filenames only, executed in this exact order)
$Steps = @(
    # "01-winget-configure.ps1"
    # "02-winget-configure.ps1"
    "10-step1.ps1"
    "20-step2.ps1"
    "30-step3.ps1"
)
# ==========================

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
    Write-Host ("Flags: WhatIf={0} DisableInteractivity={1} VerboseWinget={2}" -f $WhatIf, $DisableInteractivity, $VerboseWinget)
}

function Invoke-StepScript {
    [CmdletBinding()]
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

    # StrictMode-safe handling of LASTEXITCODE:
    # - It might be undefined unless a native EXE has run.
    # - We snapshot whether it existed and its previous value.
    $hadLastExitCode = Test-Path variable:LASTEXITCODE
    $prevLastExitCode = if ($hadLastExitCode) { $global:LASTEXITCODE } else { $null }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $Path `
            -RepoRoot $RepoRoot `
            -WhatIf:$WhatIf `
            -DisableInteractivity:$DisableInteractivity `
            -VerboseWinget:$VerboseWinget
    }
    catch {
        $sw.Stop()
        Write-Host ("!!! Step threw an error: {0} ({1}s)" -f $StepName, [int]$sw.Elapsed.TotalSeconds)
        throw
    }
    finally {
        $sw.Stop()
    }

    # If the step ran a native EXE, LASTEXITCODE may have changed.
    if (Test-Path variable:LASTEXITCODE) {
        $currentExit = $global:LASTEXITCODE
        $changed =
            (-not $hadLastExitCode) -or
            ($prevLastExitCode -ne $currentExit)

        if ($changed -and $currentExit -ne 0) {
            throw "Step failed: $StepName (native exit $currentExit)"
        }
    }

    Write-Host ("--- Step complete: {0} ({1}s)" -f $StepName, [int]$sw.Elapsed.TotalSeconds)
}

# -------------------------
# MAIN
# -------------------------
Assert-Admin

$RepoRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$StepsDir = Join-Path $RepoRoot $StepsDirName

Ensure-Folder $LogRoot
$runId   = (Get-Date).ToString("yyyyMMdd-HHmmss")
$logFile = Join-Path $LogRoot "setup-$runId.log"

Start-Transcript -Path $logFile -Append | Out-Null

try {
    Write-Header -RepoRoot $RepoRoot -StepsDir $StepsDir -LogFile $logFile

    if (-not (Test-Path -LiteralPath $StepsDir)) {
        throw "Steps folder not found: $StepsDir"
    }

    if (-not $Steps -or $Steps.Count -eq 0) {
        throw "No steps defined in `$Steps. Add filenames to the list at the top."
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