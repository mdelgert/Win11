# Win11

Windows 11 automation scripts for unattended installation and configuration.

## Quick Start

### Download the latest release

**Linux/macOS (curl):**

```bash
curl -L -o unattend.iso https://github.com/mdelgert/win11/releases/latest/download/unattend.iso
```

**Windows (PowerShell):**

```powershell
Invoke-WebRequest -Uri 'https://github.com/mdelgert/win11/releases/latest/download/unattend.iso' -OutFile 'unattend.iso'
```

## Links
- [Proxmox README](proxmox/README.md)
- [unattend.iso](https://github.com/mdelgert/win11/releases/latest/download/unattend.iso) - Latest release
- [Repository](https://github.com/mdelgert/Win11)
- [Unattend Generator](https://schneegans.de/windows/unattend-generator/)
- [Unattend Generator Source](https://github.com/cschneegans/unattend-generator)
- [Unattend Generator Samples](https://schneegans.de/windows/unattend-generator/samples/)
- [UnattendedWinstall](https://github.com/memstechtips/UnattendedWinstall)
- [WinGet Configurations](https://learn.microsoft.com/en-us/windows/package-manager/configuration/)
- [WinGet DSC Configure Guide](https://woshub.com/winget-dsc-configure/)
- [Any Burn](https://anyburn.com/download.php)

## Wallpaper

Photo by Benjamin Voros on [Unsplash](https://unsplash.com/photos/snow-mountain-under-stars-phIFdC6lA4E).

```powershell
$url = 'https://4kwallpapers.com/images/wallpapers/windows-11-dark-mode-abstract-background-black-background-3840x2160-8710.png'
& {
    $ProgressPreference = 'SilentlyContinue'
    (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30).Content
}
```

## VM Config

| Setting | Value |
|---------|-------|
| Name    | `vm-unattend` |
| Memory  | 32768 / 16384 / 4096 |

## Default Users

| Username   | Password          |
|------------|-------------------|
| mdelgert   | `p@ssw0rd2026!0`  |
| elgertmd   | `p@ssw0rd2026!1`  |
