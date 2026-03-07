#Requires -Version 5.1
# =========================================
# File: setup.ps1
#
# Purpose:
#   Main entrypoint for Windows 11 machine setup.
#   Runs ordered groups of scripts from the .\scripts folder.
#
# Features:
#   - Uses a single entry script for all phases
#   - Supports multiple named script groups via -ScriptSet
#   - Writes a transcript log file
#   - Writes timestamped log entries for key events
#   - Can be reused after reboot by calling the same script
#
# Folder layout:
#   repo-root\
#     setup.ps1
#     scripts\
#       00-remove-autologoncount.ps1
#       10-base.ps1
#       20-tools.ps1
#       ...
#
# Log location:
#   C:\Setup\logs
#
# PowerShell compatibility:
#   This script is intended for Windows PowerShell 5.1.
#   Avoid PowerShell 7+ only features.
#
# Typical usage:
#
#   Run default group:
#     powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Setup\win11\setup.ps1
#
#   Run a specific group:
#     powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Setup\win11\setup.ps1 -ScriptSet resume
#
#   Dry run style flag forwarding:
#     powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Setup\win11\setup.ps1 -ScriptSet apps -WhatIf
#
#   Resume after reboot using RunOnce:
#     powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Setup\win11\setup.ps1 -ScriptSet postreboot
#
# Example script groups:
#   - default
#   - prereboot
#   - postreboot
#   - apps
#   - finalize
#   - resume
#   - template
#
# Recommended pattern:
#   1. Keep each child script focused on one job
#   2. Let this launcher control ordering
#   3. If reboot is required, register this same setup.ps1 in RunOnce
#      with the next -ScriptSet value, then reboot
#
# Notes:
#   - Child scripts are executed in the exact order listed below
#   - Child scripts are expected to accept these parameters:
#       -RepoRoot
#       -WhatIf
#       -DisableInteractivity
#       -VerboseWinget
#   - If a child script runs a native EXE and returns a non-zero exit code,
#     this launcher will fail the run
# =========================================

[CmdletBinding()]
param(
    [switch]$WhatIf,
    [switch]$DisableInteractivity,
    [switch]$VerboseWinget,
    [string]$ScriptSet = "default"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# ==========================
# USER CONFIG
# ==========================
$ScriptsDirName = "scripts"
$LogRoot        = "C:\Setup\logs"

# Ordered script groups.
# Add or remove filenames as needed.
$ScriptSets = @{
    default = @(
        "100-template.ps1 ScriptSet=default"
    )

    prereboot = @(
        "100-template.ps1 ScriptSet=prereboot"
    )

    postreboot = @(
        "100-template.ps1 ScriptSet=postreboot"
    )

    apps = @(
        "100-template.ps1 ScriptSet=apps"
    )

    finalize = @(
        "100-template.ps1 ScriptSet=finalize"
    )

    resume = @(
        "100-template.ps1 ScriptSet=resume"
    )

    template = @(
        "100-template.ps1 ScriptSet=template"
    )
}
# ==========================

function New-FolderIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[{0}] {1}" -f $timestamp, $Message

    Write-Host $entry

    try {
        Add-Content -LiteralPath $script:LogFile -Value $entry
    }
    catch {
        Write-Host "[{0}] Failed to write to log file." -f $timestamp
    }
}

function Assert-Admin {
    if (-not (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
        try {
            Add-Content -LiteralPath $script:LogFile -Value ("[{0}] Script is not running elevated." -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
        }
        catch {}
        throw "Run in an elevated PowerShell (Run as Administrator)."
    }
}

function Write-Header {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$ScriptsDir,
        [Parameter(Mandatory = $true)][string]$LogFile
    )

    Write-Log ("RepoRoot: {0}" -f $RepoRoot)
    Write-Log ("ScriptsDir: {0}" -f $ScriptsDir)
    Write-Log ("LogFile: {0}" -f $LogFile)
    Write-Log ("PowerShell: {0} Edition: {1}" -f $PSVersionTable.PSVersion, $PSVersionTable.PSEdition)
    Write-Log ("Flags: WhatIf={0} DisableInteractivity={1} VerboseWinget={2} ScriptSet={3}" -f $WhatIf, $DisableInteractivity, $VerboseWinget, $ScriptSet)
}

function Invoke-StepScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$StepName,
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [switch]$WhatIf,
        [switch]$DisableInteractivity,
        [switch]$VerboseWinget
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing step: $Path"
    }

    Write-Log ("Starting step: {0}" -f $StepName)

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
        Write-Log ("Step threw an error: {0} ({1}s)" -f $StepName, [int]$sw.Elapsed.TotalSeconds)
        throw
    }
    finally {
        $sw.Stop()
    }

    if (Test-Path variable:LASTEXITCODE) {
        $currentExit = $global:LASTEXITCODE
        $changed =
            (-not $hadLastExitCode) -or
            ($prevLastExitCode -ne $currentExit)

        if ($changed -and $currentExit -ne 0) {
            throw "Step failed: $StepName (native exit $currentExit)"
        }
    }

    Write-Log ("Step complete: {0} ({1}s)" -f $StepName, [int]$sw.Elapsed.TotalSeconds)
}

# -------------------------
# MAIN
# -------------------------
$RepoRoot   = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$ScriptsDir = Join-Path $RepoRoot $ScriptsDirName

New-FolderIfMissing -Path $LogRoot
$runId = (Get-Date).ToString("yyyyMMdd-HHmmss")
$script:LogFile = Join-Path $LogRoot ("setup-{0}-{1}.log" -f $ScriptSet, $runId)

Start-Transcript -Path $script:LogFile -Append | Out-Null

try {
    Write-Header -RepoRoot $RepoRoot -ScriptsDir $ScriptsDir -LogFile $script:LogFile

    if (-not (Test-Path -LiteralPath $ScriptsDir)) {
        throw "Scripts folder not found: $ScriptsDir"
    }

    if (-not $ScriptSets.ContainsKey($ScriptSet)) {
        throw "Unknown ScriptSet '$ScriptSet'. Valid values: $($ScriptSets.Keys -join ', ')"
    }

    $Scripts = $ScriptSets[$ScriptSet]

    if (-not $Scripts -or $Scripts.Count -eq 0) {
        throw "No scripts defined for ScriptSet '$ScriptSet'."
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

    Write-Log "Setup complete."
}
catch {
    Write-Log "SETUP FAILED."
    Write-Log $_.Exception.ToString()
    throw
}
finally {
    try { Stop-Transcript | Out-Null } catch {}
    Write-Host "Log saved: $script:LogFile"
}