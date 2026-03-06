# Win11
Windows 11 Scripts

# Links
[repo](https://github.com/mdelgert/Win11)
[unattend-generator](https://schneegans.de/windows/unattend-generator/)
[source](https://github.com/cschneegans/unattend-generator)
[](https://schneegans.de/windows/unattend-generator/samples/)
[UnattendedWinstall](https://github.com/memstechtips/UnattendedWinstall)
[WinGet Configurations](https://learn.microsoft.com/en-us/windows/package-manager/configuration/)
[Automate Software and Settings Deployment with WinGet Configure (DSC)](https://woshub.com/winget-dsc-configure/)
[Any Burn](https://anyburn.com/download.php)

# Photo by Benjamin Voros on Unsplash. See https://unsplash.com/photos/snow-mountain-under-stars-phIFdC6lA4E for more info.
$url = 'https://4kwallpapers.com/images/wallpapers/windows-11-dark-mode-abstract-background-black-background-3840x2160-8710.png';
& {
	$ProgressPreference = 'SilentlyContinue';
	( Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30 ).Content;
};

# VM Config
name: vm-unattend
mem: 32768/16384/4096

# Default users and passwords
mdelgert:p@ssw0rd2026!0
elgertmd:p@ssw0rd2026!1
