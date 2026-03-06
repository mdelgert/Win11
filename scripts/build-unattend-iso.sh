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
mkdir -p "$ISO_ROOT/tools/autologon"

cp autounattend.xml "$ISO_ROOT/autounattend.xml"
echo "$VERSION" > "$ISO_ROOT/version.txt"

rsync -av ./ "$ISO_ROOT/repo/" \
  --exclude '.git' \
  --exclude '.github' \
  --exclude 'iso-root' \
  --exclude '*.iso' \
  --exclude '*.zip'

curl -fsSL \
  https://download.sysinternals.com/files/AutoLogon.zip \
  -o "$ISO_ROOT/tools/AutoLogon.zip"

unzip -o "$ISO_ROOT/tools/AutoLogon.zip" -d "$ISO_ROOT/tools/autologon"

genisoimage \
  -o unattend.iso \
  -J -R \
  "$ISO_ROOT"

echo "$VERSION" > unattend.version.txt
sha256sum unattend.iso > unattend.iso.sha256