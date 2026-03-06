#!/usr/bin/env bash
set -euo pipefail

ISO_URL="https://github.com/mdelgert/win11/releases/latest/download/unattend.iso"
ISO_DIR="/var/lib/vz/template/iso"
ISO_PATH="${ISO_DIR}/unattend.iso"
TMP_PATH="${ISO_PATH}.download"

mkdir -p "$ISO_DIR"

if [[ -f "$ISO_PATH" ]]; then
  curl -fL -z "$ISO_PATH" --retry 3 --connect-timeout 15 -o "$TMP_PATH" "$ISO_URL" || {
    rm -f "$TMP_PATH"
    exit 1
  }

  if [[ -f "$TMP_PATH" && -s "$TMP_PATH" ]]; then
    mv -f "$TMP_PATH" "$ISO_PATH"
    chmod 644 "$ISO_PATH"
    echo "Updated unattend.iso"
  else
    rm -f "$TMP_PATH"
    echo "No update available"
  fi
else
  curl -fL --retry 3 --connect-timeout 15 -o "$TMP_PATH" "$ISO_URL"
  [[ -s "$TMP_PATH" ]]
  mv -f "$TMP_PATH" "$ISO_PATH"
  chmod 644 "$ISO_PATH"
  echo "Downloaded unattend.iso"
fi