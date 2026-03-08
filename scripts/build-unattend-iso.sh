#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-dev}"
ISO_ROOT="iso-root"

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

install_dependencies_if_needed() {
    local missing=()

    require_command genisoimage || missing+=("genisoimage")
    require_command rsync || missing+=("rsync")
    require_command unzip || missing+=("unzip")
    require_command curl || missing+=("curl")
    require_command wget || missing+=("wget")

    if [ "${#missing[@]}" -gt 0 ]; then
        echo "Installing missing packages: ${missing[*]}"
        sudo apt-get update
        sudo apt-get install -y "${missing[@]}"
    fi
}

install_dependencies_if_needed

rm -rf "$ISO_ROOT" unattend.iso unattend.iso.sha256 unattend.version.txt

mkdir -p "$ISO_ROOT"
mkdir -p "$ISO_ROOT/repo"
mkdir -p "$ISO_ROOT/media"
echo "$VERSION" > unattend.version.txt
cp autounattend.xml "$ISO_ROOT/autounattend.xml"
cp unattend.version.txt "$ISO_ROOT/unattend.version.txt"

rsync -av ./ "$ISO_ROOT/repo/" \
  --exclude 'archieve' \
  --exclude 'proxmox' \
  --exclude 'unattend' \
  --exclude '.git' \
  --exclude '.github' \
  --exclude 'iso-root' \
  --exclude '*.iso' \
  --exclude '*.zip'

# Dowload winget update
wget -O "$ISO_ROOT/media/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" \
  https://github.com/microsoft/winget-cli/releases/download/v1.28.190/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle

wget -O "$ISO_ROOT/media/DesktopAppInstaller_Dependencies.zip" \
  https://github.com/microsoft/winget-cli/releases/download/v1.28.190/DesktopAppInstaller_Dependencies.zip

unzip -o "$ISO_ROOT/media/DesktopAppInstaller_Dependencies.zip" -d "$ISO_ROOT/media"

rm -f "$ISO_ROOT/media/DesktopAppInstaller_Dependencies.zip"

# Create the ISO image
genisoimage \
  -o unattend.iso \
  -J -R \
  "$ISO_ROOT"

sha256sum unattend.iso > unattend.iso.sha256

###################### Dev testing comment out everything below for release builds ######################
# Note: This is a quick test to ensure the script runs without errors. It does not validate the contents of the ISO.
# Test running the script without errors and that the expected files are created. In a real test, you would want to mount the ISO and verify its contents.
# chmod +x ./scripts/build-unattend-iso.sh
# ./scripts/build-unattend-iso.sh
# cp unattend.iso ../
# rm -rf "$ISO_ROOT" unattend.iso unattend.iso.sha256 unattend.version.txt
#########################################################################################################