#Requires -RunAsAdministrator
# Compatible with Windows PowerShell 5.1

$ErrorActionPreference = "Stop"

function Wait-Until {
    param(
        [Parameter(Mandatory)] [scriptblock] $Condition,
        [int] $TimeoutSeconds = 300,
        [int] $SleepSeconds = 2,
        [string] $WaitingMessage = "Waiting..."
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    while ($true) {
        if (& $Condition) { return $true }

        if (Get-Date -gt $deadline) { return $false }

        Write-Host $WaitingMessage
        Start-Sleep -Seconds $SleepSeconds
    }
}

$winget = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"

$gitExeCandidates = @(
    "C:\Program Files\Git\cmd\git.exe",
    "C:\Program Files\Git\bin\git.exe"
)

$repoUrl = "https://github.com/mdelgert/win11.git"
$repoDir = "C:\source\win11"
$setupScript = Join-Path $repoDir "setup.ps1"

# 1) Wait for winget
if (-not (Wait-Until -TimeoutSeconds 300 -WaitingMessage "Waiting for winget..." -Condition { Test-Path $winget })) {
    Write-Warning "winget not found at: $winget"
    return
}

# 2) Install Git (idempotent-ish: winget may return nonzero if already installed; we tolerate it)
Write-Host "Installing Git via winget..."
try {
    & $winget install `
        --exact --id Git.Git `
        --silent `
        --accept-package-agreements --accept-source-agreements `
        --source winget `
        --scope machine | Out-Host
}
catch {
    Write-Warning "winget install Git.Git threw an exception (may already be installed): $($_.Exception.Message)"
}

# 3) Resolve git.exe path (don’t rely on PATH refresh)
$gitExe = $null

# First, check common install paths
foreach ($p in $gitExeCandidates) {
    if (Test-Path $p) { $gitExe = $p; break }
}

# If not found yet, poll until it appears
if (-not $gitExe) {
    if (-not (Wait-Until -TimeoutSeconds 300 -WaitingMessage "Waiting for git.exe to appear..." -Condition {
        foreach ($p in $gitExeCandidates) { if (Test-Path $p) { return $true } }
        return $false
    })) {
        Write-Warning "Git did not appear in expected locations."
        return
    }

    foreach ($p in $gitExeCandidates) {
        if (Test-Path $p) { $gitExe = $p; break }
    }
}

Write-Host "Using Git at: $gitExe"

# 4) Ensure repo folder exists
if (-not (Test-Path $repoDir)) {
    New-Item -ItemType Directory -Path $repoDir -Force | Out-Null
}

# 5) Clone (safe re-run)
# If folder is non-empty OR already a git repo, skip clone
$gitDir = Join-Path $repoDir ".git"
$hasFiles = @(Get-ChildItem -LiteralPath $repoDir -Force -ErrorAction SilentlyContinue).Count -gt 0

if (Test-Path $gitDir) {
    Write-Host "Repo already cloned (found .git). Pulling latest..."
    & $gitExe -C $repoDir pull | Out-Host
}
elseif ($hasFiles) {
    Write-Warning "Repo directory exists and is not empty, but no .git found. Skipping clone: $repoDir"
}
else {
    Write-Host "Cloning repo..."
    & $gitExe clone $repoUrl $repoDir | Out-Host
}

# 6) Wait for setup.ps1 then run
if (-not (Wait-Until -TimeoutSeconds 300 -WaitingMessage "Waiting for setup.ps1..." -Condition { Test-Path $setupScript })) {
    Write-Warning "Setup script not found: $setupScript"
    return
}

Write-Host "Running setup: $setupScript"
& $setupScript