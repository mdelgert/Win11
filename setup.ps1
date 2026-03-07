#Requires -Version 5.1

# .\setup.ps1
# .\setup.ps1 -ScriptSet firstReboot
# .\setup.ps1 -ScriptSet secondReboot

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
        @{ File = "100-template.ps1"; Params = @{ ScriptSet = "default"; TestParam = "1" } }
        @{ File = "100-template.ps1"; Params = @{ ScriptSet = "default"; TestParam = "2" } }
        @{ File = "99-resume.ps1"; Params = @{ NextScriptSet = "firstReboot"; -PreviewOnly } }
    )

    firstReboot = @(
        @{ File = "100-template.ps1"; Params = @{ ScriptSet = "firstReboot"; TestParam = "A" } }
        @{ File = "100-template.ps1"; Params = @{ ScriptSet = "firstReboot"; TestParam = "B" } }
        @{ File = "99-resume.ps1"; Params = @{ NextScriptSet = "secondReboot"; -PreviewOnly } }
    )

    secondReboot = @(
        @{ File = "100-template.ps1"; Params = @{ ScriptSet = "secondReboot"; TestParam = "1" } }
        @{ File = "100-template.ps1"; Params = @{ ScriptSet = "secondReboot"; TestParam = "2" } }
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

        [hashtable]$ScriptParams = @{}
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing script: $Path"
    }

    Write-Log ("Running: {0}" -f $Path)

    if ($ScriptParams.Count -gt 0) {
        $paramsText = ($ScriptParams.GetEnumerator() | ForEach-Object { "-{0} {1}" -f $_.Key, $_.Value }) -join " "
        Write-Log ("Params: {0}" -f $paramsText)
    }

    & $Path @ScriptParams
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
        $scriptParams = @{}

        if ($step.ContainsKey("Params")) {
            $scriptParams = [hashtable]$step.Params
        }

        $invokeParams = @{
            Path = $path
            ScriptParams = $scriptParams
        }

        Invoke-ChildScript @invokeParams
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