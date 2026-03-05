# setup\entry.ps1
# Run as Administrator for any resources that require elevation.

param(
  [switch]$Force
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$LogRoot = "C:\ProgramData\Win11Setup\Logs"
$StatePath = "C:\ProgramData\Win11Setup\state.json"

function Ensure-Folder([string]$p) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null } }

function Start-Log {
  Ensure-Folder $LogRoot
  $runId = (Get-Date).ToString("yyyyMMdd-HHmmss")
  $logFile = Join-Path $LogRoot "setup-$runId.log"
  Start-Transcript -Path $logFile -Append | Out-Null
  return @{ RunId = $runId; LogFile = $logFile }
}

function Stop-Log { try { Stop-Transcript | Out-Null } catch {} }

function Read-State {
  Ensure-Folder (Split-Path $StatePath -Parent)
  if (-not (Test-Path $StatePath)) {
    return [ordered]@{ schema=1; machine=$env:COMPUTERNAME; steps=@{} }
  }
  return (Get-Content $StatePath -Raw | ConvertFrom-Json -AsHashtable)
}

function Write-State([hashtable]$state) {
  $state | ConvertTo-Json -Depth 10 | Set-Content -Path $StatePath -Encoding utf8
}

function Step-NeedsRun([hashtable]$state, [string]$name) {
  if ($Force) { return $true }
  return -not ($state.steps.ContainsKey($name) -and $state.steps[$name].status -eq "ok")
}

function Mark-Step([hashtable]$state, [string]$name, [string]$status, [string]$runId, [string]$err = $null) {
  if (-not $state.steps.ContainsKey($name)) { $state.steps[$name] = @{} }
  $state.steps[$name].status = $status
  $state.steps[$name].lastRunId = $runId
  $state.steps[$name].timestamp = (Get-Date).ToString("s")
  if ($err) { $state.steps[$name].error = $err } else { $state.steps[$name].Remove("error") }
}

function Assert-Admin {
  $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if (-not $isAdmin) { throw "Run this in an elevated PowerShell (Run as Administrator)." }
}

function Ensure-Winget {
  $exe = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
  if (-not (Test-Path $exe)) { throw "winget not found. Install/repair App Installer, then rerun." }
  return $exe
}

# ---- main ----
Assert-Admin
$log = Start-Log
$state = Read-State

try {
  $winget = Ensure-Winget

  # 1) Apply baseline packages via WinGet Configuration
  $cfgName = "baseline"
  $cfgPath = Join-Path (Resolve-Path "$PSScriptRoot\..") ".config\baseline.dsc.winget"

  if (Step-NeedsRun $state $cfgName) {
    try {
      if (-not (Test-Path $cfgPath)) { throw "Missing config: $cfgPath" }

      # Ensure WinGet DSC module is available (required for WinGetPackage resources)
      if (-not (Get-Module -ListAvailable -Name Microsoft.WinGet.DSC)) {
          Write-Host "Installing PowerShell module: Microsoft.WinGet.DSC ..."
          Install-Module Microsoft.WinGet.DSC -Force -Scope AllUsers
      }
      
      # winget configure usage
      & $winget configure -f $cfgPath
      if ($LASTEXITCODE -ne 0) { throw "winget configure failed (exit $LASTEXITCODE)" }

      Mark-Step $state $cfgName "ok" $log.RunId
      Write-State $state
    } catch {
      Mark-Step $state $cfgName "failed" $log.RunId $_.Exception.Message
      Write-State $state
      throw
    }
  }

  # 2) Run your custom steps after apps are installed
  $customSteps = @(
      "$PSScriptRoot\steps\10-step1.ps1",
      "$PSScriptRoot\steps\20-step2.ps1",
      "$PSScriptRoot\steps\30-step3.ps1"
  )

  foreach ($s in $customSteps) {
    $name = Split-Path $s -Leaf
    if (-not (Test-Path $s)) { continue }

    if (Step-NeedsRun $state $name) {
      try {
        & $s
        Mark-Step $state $name "ok" $log.RunId
        Write-State $state
      } catch {
        Mark-Step $state $name "failed" $log.RunId $_.Exception.Message
        Write-State $state
        throw
      }
    }
  }

  Write-Host "Done. Log: $($log.LogFile)"
  Write-Host "State: $StatePath"
}
finally {
  Stop-Log
}