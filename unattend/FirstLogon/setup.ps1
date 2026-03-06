#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$repoUrl     = 'https://github.com/mdelgert/win11.git'
$repoRoot    = 'C:\source'
$repoDir     = 'C:\source\win11'
$setupScript = 'C:\source\win11\setup.ps1'

function Wait-ForPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [int]$TimeoutSeconds = 300
    )

    $end = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $end) {
        if (Test-Path $Path) {
            return $true
        }
        Start-Sleep -Seconds 2
    }

    return $false
}

function Wait-ForCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [int]$TimeoutSeconds = 300
    )

    $end = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $end) {
        $cmd = Get-Command $Name -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) {
            return $cmd.Source
        }
        Start-Sleep -Seconds 2
    }

    return $null
}

function Invoke-NativeWithRetry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [int]$RetryCount = 3,

        [int]$DelaySeconds = 5
    )

    for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
        Write-Host "Running: $FilePath $($Arguments -join ' ')"
        & $FilePath @Arguments
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            return
        }

        if ($attempt -lt $RetryCount) {
            Write-Warning "Command failed with exit code ${exitCode}. Retrying in $DelaySeconds seconds..."
            Start-Sleep -Seconds $DelaySeconds
        }
        else {
            throw "Command failed with exit code ${exitCode}: $FilePath $($Arguments -join ' ')"
        }
    }
}

Write-Host 'Waiting for winget...'

$winget = Wait-ForCommand -Name 'winget.exe' -TimeoutSeconds 300

if (-not $winget) {
    $windowsAppsWinget = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'

    if (Wait-ForPath -Path $windowsAppsWinget -TimeoutSeconds 60) {
        $winget = $windowsAppsWinget
    }
}

if (-not $winget) {
    throw 'winget.exe was not found.'
}

Write-Host "winget found at: $winget"

Write-Host 'Installing Git...'
Invoke-NativeWithRetry -FilePath $winget -Arguments @(
    'install',
    '--exact',
    '--id', 'Git.Git',
    '--silent',
    '--accept-package-agreements',
    '--accept-source-agreements',
    '--source', 'winget',
    '--scope', 'machine'
) -RetryCount 3 -DelaySeconds 10

Write-Host 'Waiting for git...'

$git = Wait-ForCommand -Name 'git.exe' -TimeoutSeconds 300

if (-not $git) {
    $gitCmd = 'C:\Program Files\Git\cmd\git.exe'
    $gitBin = 'C:\Program Files\Git\bin\git.exe'

    if (Test-Path $gitCmd) {
        $git = $gitCmd
    }
    elseif (Test-Path $gitBin) {
        $git = $gitBin
    }
}

if (-not $git) {
    throw 'git.exe was not found after installation.'
}

Write-Host "git found at: $git"

if (-not (Test-Path $repoRoot)) {
    New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null
}

if (Test-Path $repoDir) {
    Write-Host "Repository already exists at $repoDir"
}
else {
    Write-Host "Cloning $repoUrl to $repoDir ..."
    Invoke-NativeWithRetry -FilePath $git -Arguments @(
        'clone',
        $repoUrl,
        $repoDir
    ) -RetryCount 3 -DelaySeconds 10
}

if (-not (Test-Path $setupScript)) {
    throw "setup.ps1 not found at $setupScript"
}

Write-Host "Running $setupScript ..."
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setupScript

$setupExitCode = $LASTEXITCODE
if ($setupExitCode -ne 0) {
    throw "setup.ps1 failed with exit code $setupExitCode"
}

Write-Host 'Bootstrap completed successfully.'
exit 0