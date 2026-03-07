
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
    require_command wget || missing+=("wget")

    if [ "${#missing[@]}" -gt 0 ]; then
        echo "Installing missing packages: ${missing[*]}"
        sudo apt-get update
        sudo apt-get install -y "${missing[@]}"
    fi
}

install_dependencies_if_needed

rm -rf "$ISO_ROOT" media.iso media.iso.sha256 media.version.txt

mkdir -p "$ISO_ROOT"
mkdir -p "$ISO_ROOT/media"
echo "$VERSION" > media.version.txt
cp media.version.txt "$ISO_ROOT/media.version.txt"

# Dowload winget update
wget -O "$ISO_ROOT/media/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" \
  https://github.com/microsoft/winget-cli/releases/download/v1.28.190/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle

# Create the ISO image
genisoimage \
  -o media.iso \
  -J -R \
  "$ISO_ROOT"

sha256sum media.iso > media.iso.sha256

###################### Dev testing comment out everything below for release builds ######################
# Note: This is a quick test to ensure the script runs without errors. It does not validate the contents of the ISO.
# Test running the script without errors and that the expected files are created. In a real test, you would want to mount the ISO and verify its contents.
# chmod +x ./scripts/build-media-iso.sh
# ./scripts/build-media-iso.sh
#cp media.iso ../
#rm -rf "$ISO_ROOT" media.iso media.iso.sha256 media.version.txt
#########################################################################################################