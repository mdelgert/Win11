#Requires -Version 5.1
# clone.ps1
# Compatible with Windows PowerShell 5.1
# Requires -RunAsAdministrator

param(
    [string]$RepoUrl = "https://github.com/mdelgert/Win11.git",
    [string]$SourceRoot = "C:\test",
    [string]$RepoName = "Win11",
    [switch]$RunSetup
)

$ErrorActionPreference = "Stop"

function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        throw "Please run this script as Administrator."
    }
}

function Ensure-Folder($path) {
    if (!(Test-Path $path)) {
        Write-Host "Creating folder $path"
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

function Ensure-Git {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Git not found. Installing Git using WinGet..."

        winget install `
            --exact `
            --id Git.Git `
            --silent `
            --accept-package-agreements `
            --accept-source-agreements

        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            throw "Git installation failed."
        }
    }
}

Assert-Admin

Ensure-Folder $SourceRoot
Ensure-Git

$RepoPath = Join-Path $SourceRoot $RepoName

if (!(Test-Path $RepoPath)) {

    Write-Host ""
    Write-Host "Cloning repository..."
    Write-Host "$RepoUrl -> $RepoPath"

    git clone $RepoUrl $RepoPath
}
else {

    Write-Host ""
    Write-Host "Repository already exists. Updating..."

    Push-Location $RepoPath
    git pull
    Pop-Location
}

if ($RunSetup) {

    $SetupScript = Join-Path $RepoPath "setup\run.ps1"

    if (Test-Path $SetupScript) {

        Write-Host ""
        Write-Host "Running setup script..."

        powershell -ExecutionPolicy Bypass -File $SetupScript
    }
    else {
        Write-Warning "Setup script not found: $SetupScript"
    }
}

Write-Host ""
Write-Host "Bootstrap completed."