#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ScriptSet = "default"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ScriptsDirName = "scripts"
$LogRoot = "C:\Setup\logs"

$ScriptSets = @{
    default = @(
        @{ File = "100-template.ps1"; Args = @("-ScriptSet", "default", "-TestParam", "1") }
        @{ File = "100-template.ps1"; Args = @("-ScriptSet", "default", "-TestParam", "2") }
    )

    prereboot = @(
        @{ File = "100-template.ps1"; Args = @("-ScriptSet", "prereboot", "-TestParam", "A") }
    )

    postreboot = @(
        @{ File = "100-template.ps1"; Args = @("-ScriptSet", "postreboot", "-TestParam", "B") }
    )
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

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host ("[{0}] {1}" -f $timestamp, $Message)
}

function Invoke-ChildScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [string[]]$Args = @()
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing script: $Path"
    }

    Write-Log ("Running: {0}" -f $Path)

    if ($Args.Count -gt 0) {
        Write-Log ("Args: {0}" -f ($Args -join " "))
    }

    & $Path @Args
}

$RepoRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$ScriptsDir = Join-Path $RepoRoot $ScriptsDirName

New-FolderIfMissing -Path $LogRoot
$runId = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $LogRoot "setup-$ScriptSet-$runId.log"

Start-Transcript -Path $logFile -Append | Out-Null

try {
    Write-Log ("RepoRoot: {0}" -f $RepoRoot)
    Write-Log ("ScriptsDir: {0}" -f $ScriptsDir)
    Write-Log ("ScriptSet: {0}" -f $ScriptSet)

    if (-not $ScriptSets.ContainsKey($ScriptSet)) {
        throw "Unknown ScriptSet: $ScriptSet"
    }

    foreach ($step in $ScriptSets[$ScriptSet]) {
        $path = Join-Path $ScriptsDir $step.File
        $args = @()

        if ($step.ContainsKey("Args")) {
            $args = [string[]]$step.Args
        }

        Invoke-ChildScript -Path $path -Args $args
    }

    Write-Log "Setup complete."
}
catch {
    Write-Log "SETUP FAILED."
    Write-Log $_.Exception.Message
    throw
}
finally {
    try { Stop-Transcript | Out-Null } catch {}
    Write-Host "Log saved: $logFile"
}