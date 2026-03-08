#Requires -Version 5.1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: winget-update.ps1"
Write-Host "Description: Upgrade Winget from local ISO media."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "=============================================================="
Write-Host ""

function Get-IsoRoot {
    $drives = Get-PSDrive -PSProvider FileSystem

    foreach ($drive in $drives) {
        $autounattendFile = Join-Path -Path $drive.Root -ChildPath "autounattend.xml"
        $versionMarker = Join-Path -Path $drive.Root -ChildPath "unattend.version.txt"

        if ((Test-Path -Path $autounattendFile) -and (Test-Path -Path $versionMarker)) {
            return $drive.Root
        }
    }

    return $null
}

try {
    $isoRoot = Get-IsoRoot
    if ([string]::IsNullOrWhiteSpace($isoRoot)) {
        throw "Could not locate ISO media root. Expected to find both 'autounattend.xml' and 'unattend.version.txt' on a mounted drive."
    }

    $mediaRoot = Join-Path -Path $isoRoot -ChildPath "media"
    $x64Root   = Join-Path -Path $mediaRoot -ChildPath "x64"

    $installerPath = Join-Path -Path $mediaRoot -ChildPath "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    $winAppRuntime = Join-Path -Path $x64Root   -ChildPath "Microsoft.WindowsAppRuntime.1.8_8000.616.304.0_x64.appx"
    $vclibsUwp     = Join-Path -Path $x64Root   -ChildPath "Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x64.appx"
    $vclibsDesktop = Join-Path -Path $x64Root   -ChildPath "Microsoft.VCLibs.140.00_14.0.33519.0_x64.appx"

    Write-Host "Located ISO media root at: $isoRoot"
    Write-Host "Installer path: $installerPath"
    Write-Host "Dependency path 1: $winAppRuntime"
    Write-Host "Dependency path 2: $vclibsUwp"
    Write-Host "Dependency path 3: $vclibsDesktop"

    if (-not (Test-Path -Path $installerPath)) {
        throw "Installer not found: $installerPath"
    }

    $dependencyPaths = @()

    if (Test-Path -Path $winAppRuntime) {
        $dependencyPaths += $winAppRuntime
    }

    if (Test-Path -Path $vclibsUwp) {
        $dependencyPaths += $vclibsUwp
    }

    if (Test-Path -Path $vclibsDesktop) {
        $dependencyPaths += $vclibsDesktop
    }

    if ($dependencyPaths.Count -eq 0) {
        throw "No dependency packages were found under: $x64Root"
    }

    Write-Host "Installing Winget silently from: $installerPath"
    Write-Host "Using dependencies:"
    $dependencyPaths | ForEach-Object { Write-Host "  $_" }

    Add-AppxPackage `
        -Path $installerPath `
        -DependencyPath $dependencyPaths `
        -ForceApplicationShutdown `
        -ForceUpdateFromAnyVersion `
        -ErrorAction Stop

    $wingetCommand = Get-Command -Name winget.exe -ErrorAction SilentlyContinue
    if ($wingetCommand) {
        Write-Host "Winget install/update complete. Command path: $($wingetCommand.Source)"
    }
    else {
        Write-Host "Install completed, but winget is not yet visible in this session. A sign-out or reboot may be required."
    }
}
catch {
    Write-Host "Winget update failed: $($_.Exception.Message)"
    exit 1
}