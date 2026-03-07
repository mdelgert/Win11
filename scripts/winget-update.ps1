#Requires -Version 5.1

$ErrorActionPreference = "Stop"

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[$timestamp] [$Level] $Message"
}

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: winget-update.ps1"
Write-Host "Description: Upgrade winget."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "=============================================================="
Write-Host ""

function Get-IsoRoot {
    $drives = Get-PSDrive -PSProvider FileSystem

    foreach ($drive in $drives) {
        $versionMarker = Join-Path $drive.Root "media.version.txt"
        
        if (Test-Path -Path $versionMarker) {
            return $drive.Root
        }
    }

    return $null
}

function Get-WingetInstallerPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$IsoRoot
    )

    $searchRoots = @(
        (Join-Path -Path $IsoRoot -ChildPath 'media'),
        $IsoRoot
    )

    $patterns = @(
        'Microsoft.DesktopAppInstaller*.msixbundle',
        'Microsoft.DesktopAppInstaller*.appxbundle',
        'Microsoft.DesktopAppInstaller*.msix',
        'Microsoft.DesktopAppInstaller*.appx',
        'winget*.msi',
        'winget*.exe'
    )

    $candidates = @()
    foreach ($root in $searchRoots) {
        if (-not (Test-Path -Path $root)) {
            continue
        }

        foreach ($pattern in $patterns) {
            $candidates += Get-ChildItem -Path $root -Filter $pattern -File -ErrorAction SilentlyContinue
        }
    }

    if ($null -eq $candidates -or $candidates.Count -eq 0) {
        return $null
    }

    return ($candidates | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1).FullName
}

function Install-WingetSilently {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstallerPath
    )

    $extension = [System.IO.Path]::GetExtension($InstallerPath).ToLowerInvariant()
    Write-Log -Message "Using installer: $InstallerPath"

    switch ($extension) {
        '.msixbundle' {
            Add-AppxPackage -Path $InstallerPath -ForceApplicationShutdown -ForceUpdateFromAnyVersion -ErrorAction Stop
            return
        }
        '.appxbundle' {
            Add-AppxPackage -Path $InstallerPath -ForceApplicationShutdown -ForceUpdateFromAnyVersion -ErrorAction Stop
            return
        }
        '.msix' {
            Add-AppxPackage -Path $InstallerPath -ForceApplicationShutdown -ForceUpdateFromAnyVersion -ErrorAction Stop
            return
        }
        '.appx' {
            Add-AppxPackage -Path $InstallerPath -ForceApplicationShutdown -ForceUpdateFromAnyVersion -ErrorAction Stop
            return
        }
        '.msi' {
            $msiArgs = '/i "{0}" /qn /norestart' -f $InstallerPath
            $process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait -PassThru -WindowStyle Hidden
            if ($process.ExitCode -ne 0) {
                throw "MSI install failed with exit code $($process.ExitCode)."
            }

            return
        }
        '.exe' {
            $exeArgs = '/quiet /silent /norestart'
            $process = Start-Process -FilePath $InstallerPath -ArgumentList $exeArgs -Wait -PassThru -WindowStyle Hidden
            if ($process.ExitCode -ne 0) {
                throw "EXE install failed with exit code $($process.ExitCode)."
            }

            return
        }
        default {
            throw "Unsupported installer type: $extension"
        }
    }
}

try {
    Write-Log -Message 'Searching for ISO root directory...'
    $isoRoot = Get-IsoRoot

    if ([string]::IsNullOrWhiteSpace($isoRoot)) {
        throw 'ISO root directory was not found. Expected media.version.txt on a mounted drive.'
    }

    Write-Log -Message "ISO root directory: $isoRoot"

    $installerPath = Get-WingetInstallerPath -IsoRoot $isoRoot
    if ([string]::IsNullOrWhiteSpace($installerPath)) {
        throw "No Winget installer was found under '$isoRoot'."
    }

    Write-Log -Message 'Installing Winget silently (no prompts)...'
    Install-WingetSilently -InstallerPath $installerPath

    $wingetCommand = Get-Command -Name winget.exe -ErrorAction SilentlyContinue
    if ($wingetCommand) {
        Write-Log -Message "Winget install/update complete. Command path: $($wingetCommand.Source)"
    }
    else {
        Write-Log -Message 'Install completed, but winget is not yet visible in this session. A sign-out or reboot may be required.' -Level 'WARN'
    }
}
catch {
    Write-Log -Message "Winget update failed: $($_.Exception.Message)" -Level 'ERROR'
    exit 1
}