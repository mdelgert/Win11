#Requires -Version 5.1
# =========================================
# Win11 Machine Setup (Windows PowerShell 5.1)
#
# - Main entrypoint: setup.ps1 (repo root)
# - Runs ordered step scripts from .\steps (explicit list, no auto-discovery)
# - Logs to: C:\Setup\logs
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
$ScriptsDirName = "scripts"
$LogRoot      = "C:\Setup\logs"

# Ordered list of scripts to run (filenames only, executed in this exact order)
$Scripts = @(
    "10-template.ps1"
    # "01-autologon-enable.ps1"
    # "01-autologon-download.ps1"
    # "00-winget-upgrade.ps1"
    # "02-winget-configure-enable.ps1"
    # "02-winget-configure-baseline.ps1"
    # "03-vscodemenu.ps1"
    # "05-ssh.ps1"
)
# ==========================

function Assert-Admin {
    if (-not (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
        try {
            Add-Content -LiteralPath $logFile -Value ("[{0}] Script is not running elevated." -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
        }
        catch {}
        throw "Run in an elevated PowerShell (Run as Administrator)."
    }
}

function New-FolderIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-Header([string]$RepoRoot, [string]$ScriptsDir, [string]$LogFile) {
    Write-Host "RepoRoot: $RepoRoot"
    Write-Host "StepsDir: $ScriptsDir"
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
$RepoRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$ScriptsDir = Join-Path $RepoRoot $ScriptsDirName

New-FolderIfMissing $LogRoot
$runId   = (Get-Date).ToString("yyyyMMdd-HHmmss")
$logFile = Join-Path $LogRoot "setup-$runId.log"

Start-Transcript -Path $logFile -Append | Out-Null

Assert-Admin

try {
    Write-Header -RepoRoot $RepoRoot -StepsDir $ScriptsDir -LogFile $logFile

    if (-not (Test-Path -LiteralPath $ScriptsDir)) {
        throw "Steps folder not found: $ScriptsDir"
    }

    if (-not $Scripts -or $Scripts.Count -eq 0) {
        throw "No steps defined in `$Scripts. Add filenames to the list at the top."
    }

    foreach ($step in $Scripts) {
        $path = Join-Path $ScriptsDir $step

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