#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$repoUrl     = 'https://github.com/mdelgert/win11.git'
$repoRoot    = 'C:\source'
$repoDir     = 'C:\source\win11'
$setupScript = 'C:\source\win11\setup.ps1'

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

function Get-GitPath {
    $candidates = @(
        'C:\Program Files\Git\cmd\git.exe',
        'C:\Program Files\Git\bin\git.exe',
        'C:\Program Files (x86)\Git\cmd\git.exe',
        'C:\Program Files (x86)\Git\bin\git.exe'
    )

    foreach ($path in $candidates) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}

function Wait-ForGit {
    param(
        [int]$TimeoutSeconds = 300
    )

    $end = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $end) {
        $git = Get-GitPath
        if ($git) {
            return $git
        }
        Start-Sleep -Seconds 2
    }

    return $null
}

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    Write-Host "Running: $FilePath $($Arguments -join ' ')"
    & $FilePath @Arguments
    return $LASTEXITCODE
}

Write-Host 'Waiting for winget...'
$winget = Wait-ForCommand -Name 'winget.exe' -TimeoutSeconds 300

if (-not $winget) {
    throw 'winget.exe was not found.'
}

Write-Host "winget found at: $winget"

$git = Get-GitPath

if ($git) {
    Write-Host "Git already installed at: $git"
}
else {
    Write-Host 'Git not found. Installing Git...'

    $exitCode = Invoke-Native -FilePath $winget -Arguments @(
        'install',
        '--exact',
        '--id', 'Git.Git',
        '--silent',
        '--accept-package-agreements',
        '--accept-source-agreements',
        '--source', 'winget',
        '--scope', 'machine'
    )

    if (($exitCode -ne 0) -and ($exitCode -ne -1978335189)) {
        throw "winget install Git.Git failed with exit code ${exitCode}"
    }

    Write-Host 'Waiting for git.exe file...'
    $git = Wait-ForGit -TimeoutSeconds 300

    if (-not $git) {
        throw 'git.exe was not found after installation.'
    }

    Write-Host "git found at: $git"
}

if (-not (Test-Path $repoRoot)) {
    New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null
}

if (-not (Test-Path $repoDir)) {
    Write-Host "Cloning $repoUrl to $repoDir ..."
    $cloneExitCode = Invoke-Native -FilePath $git -Arguments @(
        'clone',
        $repoUrl,
        $repoDir
    )

    if ($cloneExitCode -ne 0) {
        throw "git clone failed with exit code ${cloneExitCode}"
    }
}
else {
    Write-Host "Repository already exists at $repoDir"
}

if (-not (Test-Path $setupScript)) {
    throw "setup.ps1 not found at $setupScript"
}

Write-Host "Running $setupScript ..."
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setupScript

$setupExitCode = $LASTEXITCODE
if ($setupExitCode -ne 0) {
    throw "setup.ps1 failed with exit code ${setupExitCode}"
}

Write-Host 'Bootstrap completed successfully.'
exit 0