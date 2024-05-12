# Win11
Windows 11 Scripts

# Install and update winget
https://apps.microsoft.com/detail/9nblggh4nns1?rtc=1&hl=en-us&gl=US
https://learn.microsoft.com/en-us/windows/msix/app-installer/install-update-app-installer
https://superuser.com/questions/1701930/it-is-possible-to-install-microsoft-app-installer-using-the-command-line

```ps
(Get-AppxPackage Microsoft.DesktopAppInstaller).Version
Add-AppxPackage https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
winget upgrade Microsoft.AppInstaller
```

# Links
https://github.com/Raphire/Win11Debloat
https://github.com/Microsoft/vscode/issues/42889
https://stackoverflow.com/questions/75273110/add-open-with-visual-studio-code-shortcut-to-right-click-menu
https://apps.microsoft.com/detail/9nblggh4nns1?rtc=1&hl=en-us&gl=US#activetab=pivot:overviewtab
https://github.com/hellzerg/optimizer
https://github.com/Kugane/winget/blob/main/winget-basic.ps1
https://www.makeuseof.com/windows-11-enable-hyper-v/

# HyperV
```ps
DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V
```

# How to Add or Remove Optional Features in Windows 11
https://www.partitionwizard.com/partitionmanager/add-or-remove-optional-features-win-11.html
```ps
Get-WindowsOptionalFeature -Online
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All 
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root 
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2
Disable-WindowsOptionalFeature -Online -FeatureName MediaPlayback
Disable-WindowsOptionalFeature -Online -FeatureName WindowsMediaPlayer
```

# Winget
``ps
winget list | sort
``