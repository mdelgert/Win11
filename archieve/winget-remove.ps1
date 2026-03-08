#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

function Write-Log {
	param(
		[Parameter(Mandatory = $true)]
		[string]$message,

		[ValidateSet('INFO', 'WARN', 'ERROR')]
		[string]$level = 'INFO'
	)

	$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
	Write-Host "[$timestamp] [$level] $message"
}

function Test-IsAdministrator {
	$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$principal = New-Object -TypeName System.Security.Principal.WindowsPrincipal -ArgumentList $identity
	return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: winget-remove.ps1"
Write-Host "Description: Removes Winget (Desktop App Installer) from system."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([System.Environment]::OSVersion.Version)"
Write-Host "=============================================================="
Write-Host ""

if (-not (Test-IsAdministrator)) {
	Write-Log -message 'Administrator privileges are required to remove provisioned packages.' -level 'ERROR'
	exit 1
}

$wingetPackageName = 'Microsoft.DesktopAppInstaller'
$removedCount = 0

try {
	Write-Log -message "Searching installed AppX packages matching '$wingetPackageName'."
	$installedPackages = Get-AppxPackage -AllUsers | Where-Object -FilterScript { $_.Name -eq $wingetPackageName }

	if ($null -eq $installedPackages -or $installedPackages.Count -eq 0) {
		Write-Log -message 'No installed Winget AppX packages found.' -level 'WARN'
	}
	else {
		foreach ($package in $installedPackages) {
			try {
				Write-Log -message "Removing installed package: $($package.PackageFullName)"
				Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop
				$removedCount++
			}
			catch {
				Write-Log -message "Failed to remove installed package '$($package.PackageFullName)': $($_.Exception.Message)" -level 'WARN'
			}
		}
	}

	Write-Log -message "Searching provisioned packages matching '$wingetPackageName'."
	$provisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object -FilterScript { $_.DisplayName -eq $wingetPackageName }

	if ($null -eq $provisionedPackages -or $provisionedPackages.Count -eq 0) {
		Write-Log -message 'No provisioned Winget packages found.' -level 'WARN'
	}
	else {
		foreach ($provisionedPackage in $provisionedPackages) {
			try {
				Write-Log -message "Removing provisioned package: $($provisionedPackage.PackageName)"
				Remove-AppxProvisionedPackage -Online -PackageName $provisionedPackage.PackageName -ErrorAction Stop | Out-Null
				$removedCount++
			}
			catch {
				Write-Log -message "Failed to remove provisioned package '$($provisionedPackage.PackageName)': $($_.Exception.Message)" -level 'WARN'
			}
		}
	}

	if (Get-Command -Name winget -ErrorAction SilentlyContinue) {
		Write-Log -message 'winget command is still resolvable in this session. A restart/sign-out may be required.' -level 'WARN'
	}
	else {
		Write-Log -message 'winget command is no longer resolvable.'
	}

	Write-Log -message "Winget removal process completed. Removed package entries: $removedCount"
}
catch {
	Write-Log -message "Fatal error while removing Winget: $($_.Exception.Message)" -level 'ERROR'
	exit 1
}