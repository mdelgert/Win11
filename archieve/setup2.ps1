#Requires -RunAsAdministrator
# bootstrap.ps1
# - Provisions App Installer (winget) from local media (no Store dependency)
# - Locates winget deterministically
# - Then you can run winget install / your setup

$ErrorActionPreference = "Stop"

$logDir = "C:\Setup\Logs"

New-Item -ItemType Directory -Path $logDir -Force | Out-Null
Start-Transcript -Path (Join-Path $logDir "bootstrap.log") -Append | Out-Null

function Test-AppInstallerPresent {
    try {
        $pkg = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -AllUsers -ErrorAction Stop
        return [bool]$pkg
    } catch {
        return $false
    }
}

function Provision-WingetFromLocal {
    param(
        [Parameter(Mandatory=$true)]
        [string]$WingetFolder
    )

    if (-not (Test-Path $WingetFolder)) {
        throw "Winget folder not found: $WingetFolder"
    }

    $msix = Get-ChildItem -Path $WingetFolder -Filter "*.msixbundle" -File | Select-Object -First 1
    if (-not $msix) { throw "No .msixbundle found in $WingetFolder" }

    $deps = Get-ChildItem -Path $WingetFolder -Include "*.appx","*.msix" -File

    Write-Host "Provisioning App Installer (winget) from local packages..."
    Write-Host "  Bundle: $($msix.FullName)"
    if ($deps) {
        Write-Host "  Dependencies:"
        $deps | ForEach-Object { Write-Host "   - $($_.FullName)" }
    } else {
        Write-Host "  (No dependency .appx/.msix files found; provisioning may fail if deps are required.)"
    }

    # Provision for all users (future profiles) + install for current context
    # DISM provision is the most deterministic for unattended images.
    $depArgs = @()
    foreach ($d in $deps) {
        $depArgs += "/DependencyPackagePath:`"$($d.FullName)`""
    }

    $dismArgs = @(
        "/Online",
        "/Add-ProvisionedAppxPackage",
        "/PackagePath:`"$($msix.FullName)`"",
        "/SkipLicense"
    ) + $depArgs

    $p = Start-Process -FilePath dism.exe -ArgumentList $dismArgs -Wait -PassThru
    if ($p.ExitCode -ne 0) {
        throw "DISM provisioning failed with exit code $($p.ExitCode)"
    }

    # Give appx subsystem a moment
    Start-Sleep -Seconds 3
}

function Get-WingetPath {
    # Most reliable: read InstallLocation from the App Installer package and point at winget.exe
    $pkg = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -AllUsers |
           Sort-Object Version -Descending |
           Select-Object -First 1

    if (-not $pkg) { return $null }

    $candidate = Join-Path $pkg.InstallLocation "winget.exe"
    if (Test-Path $candidate) { return $candidate }

    # Fallback: try PATH resolution
    $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    return $null
}

$wingetFolder = "C:\Setup\Winget"

if (-not (Test-AppInstallerPresent)) {
    Provision-WingetFromLocal -WingetFolder $wingetFolder
}

$winget = $null
$timeout = [datetime]::Now.AddMinutes(5)

while (-not $winget) {
    $winget = Get-WingetPath
    if ($winget) { break }

    if ([datetime]::Now -gt $timeout) {
        throw "winget still not available after provisioning + waiting."
    }

    Write-Host "Waiting for winget registration..."
    Start-Sleep -Seconds 2
}

Write-Host "winget found at: $winget"

# (Optional) update sources / upgrade existing packages
& $winget source update | Out-Host
& $winget upgrade --all --silent --accept-package-agreements --accept-source-agreements | Out-Host

# Example installs (edit to your needs)
$packages = @(
  "Git.Git --source winget",
  "Microsoft.VisualStudioCode --source winget"
)

foreach ($id in $packages) {
    Write-Host "Installing $id ..."
    & $winget install --exact --id $id --silent --accept-package-agreements --accept-source-agreements --source winget --scope machine | Out-Host
}

$repoUrl = "https://github.com/mdelgert/win11.git"
$repoDir = "C:\source\win11"
$setupScript = "$repoDir\setup.ps1"

if (!(Test-Path $repoDir)) {
    Write-Host "Cloning repository..."
    New-Item -ItemType Directory -Path "C:\source" -Force | Out-Null
    & git clone $repoUrl $repoDir
}
else {
    Write-Host "Repository already exists, pulling latest..."
    git pull
}

# Now run your repo setup deterministically
if (Test-Path $setupScript) {
    Write-Host "Running setup.ps1"
    powershell -ExecutionPolicy Bypass -File $setupScript
}
else {
    Write-Warning "Setup script not found at $setupScript"
}

Stop-Transcript | Out-Null