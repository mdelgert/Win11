#!/usr/bin/env bash
#
# File: /root/scripts/update-unattend-iso.sh
#
# Purpose:
#   Download the latest unattend Windows ISO assets from:
#     https://github.com/mdelgert/win11/releases/latest/download/
#   and update the local Proxmox ISO only when the checksum changed.
#
# What this script does:
#   1. Downloads:
#        - unattend.version.txt
#        - unattend.iso.sha256
#   2. Compares the remote SHA256 with the local ISO SHA256
#   3. Downloads unattend.iso only if the checksum changed
#   4. Verifies the downloaded ISO checksum
#   5. Replaces the local ISO only after verification succeeds
#   6. Writes a log file for auditing and troubleshooting
#
# Local files used:
#   ISO file:
#     /var/lib/vz/template/iso/unattend.iso
#
#   Version marker:
#     /var/lib/vz/template/iso/unattend.version.txt
#
#   Log file:
#     /var/log/unattend-iso/update.log
#
# Install:
#   mkdir -p /root/scripts
#   nano /root/scripts/update-unattend-iso.sh
#   chmod +x /root/scripts/update-unattend-iso.sh
#
# Test manually:
#   /root/scripts/update-unattend-iso.sh
#
# Check logs:
#   tail -n 50 /var/log/unattend-iso/update.log
#
# Notes:
#   - Safe for repeated runs
#   - Uses temp files and only replaces the active ISO after checksum verification
#   - Intended to be run by systemd via update-unattend-iso.service / .timer
#

set -euo pipefail

#ISO_DIR="/var/lib/vz/template/iso"
ISO_DIR="/mnt/pve/downloads/template/iso"
ISO_NAME="unattend.iso"
ISO_PATH="${ISO_DIR}/${ISO_NAME}"

BASE_URL="https://github.com/mdelgert/win11/releases/latest/download"
ISO_URL="${BASE_URL}/unattend.iso"
SHA_URL="${BASE_URL}/unattend.iso.sha256"
VERSION_URL="${BASE_URL}/unattend.version.txt"

LOG_DIR="/var/log/unattend-iso"
LOG_FILE="${LOG_DIR}/update.log"
TMP_DIR="$(mktemp -d /tmp/unattend-iso.XXXXXX)"
TMP_ISO="${TMP_DIR}/unattend.iso"
TMP_SHA="${TMP_DIR}/unattend.iso.sha256"
TMP_VERSION="${TMP_DIR}/unattend.version.txt"

umask 022

mkdir -p "$ISO_DIR"
mkdir -p "$LOG_DIR"

log() {
    local message="$1"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[${ts}] ${message}" | tee -a "$LOG_FILE"
}

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

log "Starting unattend ISO update check"

download_file() {
    local url="$1"
    local output="$2"

    curl -fsSL \
        --retry 3 \
        --retry-delay 3 \
        --connect-timeout 15 \
        -o "$output" \
        "$url"
}

get_local_sha() {
    if [[ -f "$ISO_PATH" ]]; then
        sha256sum "$ISO_PATH" | awk '{print $1}'
    else
        echo ""
    fi
}

get_remote_sha() {
    awk 'NF >= 1 { print $1; exit }' "$TMP_SHA"
}

get_remote_version() {
    tr -d '\r\n' < "$TMP_VERSION"
}

log "Downloading remote version file"
download_file "$VERSION_URL" "$TMP_VERSION"
REMOTE_VERSION="$(get_remote_version)"

if [[ -n "$REMOTE_VERSION" ]]; then
    log "Remote version: ${REMOTE_VERSION}"
else
    log "Remote version file was empty"
fi

log "Downloading remote checksum file"
download_file "$SHA_URL" "$TMP_SHA"
REMOTE_SHA="$(get_remote_sha)"

if [[ -z "$REMOTE_SHA" ]]; then
    log "ERROR: Remote checksum file did not contain a valid hash"
    exit 1
fi

log "Remote SHA256: ${REMOTE_SHA}"

LOCAL_SHA="$(get_local_sha)"

if [[ -n "$LOCAL_SHA" ]]; then
    log "Local SHA256: ${LOCAL_SHA}"
else
    log "No local ISO found at ${ISO_PATH}"
fi

if [[ -n "$LOCAL_SHA" && "$LOCAL_SHA" == "$REMOTE_SHA" ]]; then
    log "Local ISO is already current. No download needed."
    log "Completed successfully"
    exit 0
fi

log "Checksum changed or local ISO missing. Downloading new ISO."
download_file "$ISO_URL" "$TMP_ISO"

if [[ ! -s "$TMP_ISO" ]]; then
    log "ERROR: Downloaded ISO is empty"
    exit 1
fi

DOWNLOADED_SHA="$(sha256sum "$TMP_ISO" | awk '{print $1}')"
log "Downloaded ISO SHA256: ${DOWNLOADED_SHA}"

if [[ "$DOWNLOADED_SHA" != "$REMOTE_SHA" ]]; then
    log "ERROR: Checksum mismatch. ISO will not be installed."
    exit 1
fi

install -m 0644 "$TMP_ISO" "$ISO_PATH"
log "Installed updated ISO to ${ISO_PATH}"

if [[ -n "$REMOTE_VERSION" ]]; then
    echo "$REMOTE_VERSION" > "${ISO_DIR}/unattend.version.txt"
    chmod 0644 "${ISO_DIR}/unattend.version.txt"
    log "Saved version marker to ${ISO_DIR}/unattend.version.txt"
fi

log "Completed successfully"
exit 0