#!/usr/bin/env bash
#
# File: proxmox/uninstall-update-unattend-iso.sh
#
# Purpose:
#   Remove the unattended Windows ISO auto-update system from a Proxmox host.
#
# What this script does:
#   1. Stops and disables the systemd timer
#   2. Stops the systemd service if it is running
#   3. Removes the installed service and timer unit files
#   4. Removes the updater shell script
#   5. Reloads systemd
#
# Default behavior:
#   - Keeps the downloaded ISO
#   - Keeps the local version marker
#   - Keeps the log files
#
# Optional flags:
#   --remove-iso
#       Remove:
#         /var/lib/vz/template/iso/unattend.iso
#
#   --remove-version
#       Remove:
#         /var/lib/vz/template/iso/unattend.version.txt
#
#   --remove-logs
#       Remove:
#         /var/log/unattend-iso
#
# Installed files removed by this script:
#   Script:
#     /root/scripts/update-unattend-iso.sh
#
#   Service:
#     /etc/systemd/system/update-unattend-iso.service
#
#   Timer:
#     /etc/systemd/system/update-unattend-iso.timer
#
# Usage:
#   Run directly on the Proxmox host as root:
#
#     bash uninstall-update-unattend-iso.sh
#
#   Remove updater and logs:
#
#     bash uninstall-update-unattend-iso.sh --remove-logs
#
#   Remove everything including ISO, version marker, and logs:
#
#     bash uninstall-update-unattend-iso.sh --remove-iso --remove-version --remove-logs
#
# GitHub raw one-liner:
#
#   Remove updater only:
#     bash <(curl -fsSL https://raw.githubusercontent.com/mdelgert/win11/main/proxmox/uninstall-update-unattend-iso.sh)
#
#   Remove everything:
#     bash <(curl -fsSL https://raw.githubusercontent.com/mdelgert/win11/main/proxmox/uninstall-update-unattend-iso.sh) --remove-iso --remove-version --remove-logs
#
# Verify removal:
#   systemctl status update-unattend-iso.timer
#   systemctl status update-unattend-iso.service
#   ls -l /etc/systemd/system/update-unattend-iso.*
#   ls -l /root/scripts/update-unattend-iso.sh
#
# Notes:
#   - Intended for Proxmox VE hosts
#   - Should be run as root
#   - Safe to run again if files were already removed
#   - By default, leaves ISO and logs in place for safety and audit purposes
#

set -euo pipefail

SERVICE_FILE="/etc/systemd/system/update-unattend-iso.service"
TIMER_FILE="/etc/systemd/system/update-unattend-iso.timer"
SCRIPT_FILE="/root/scripts/update-unattend-iso.sh"

ISO_FILE="/var/lib/vz/template/iso/unattend.iso"
VERSION_FILE="/var/lib/vz/template/iso/unattend.version.txt"
LOG_DIR="/var/log/unattend-iso"

REMOVE_ISO=false
REMOVE_VERSION=false
REMOVE_LOGS=false

for arg in "$@"; do
    case "$arg" in
        --remove-iso)
            REMOVE_ISO=true
            ;;
        --remove-version)
            REMOVE_VERSION=true
            ;;
        --remove-logs)
            REMOVE_LOGS=true
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Valid options: --remove-iso --remove-version --remove-logs"
            exit 1
            ;;
    esac
done

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "Stopping and disabling timer"
systemctl disable --now update-unattend-iso.timer 2>/dev/null || true

log "Stopping service"
systemctl stop update-unattend-iso.service 2>/dev/null || true

if [[ -f "$TIMER_FILE" ]]; then
    log "Removing $TIMER_FILE"
    rm -f "$TIMER_FILE"
fi

if [[ -f "$SERVICE_FILE" ]]; then
    log "Removing $SERVICE_FILE"
    rm -f "$SERVICE_FILE"
fi

if [[ -f "$SCRIPT_FILE" ]]; then
    log "Removing $SCRIPT_FILE"
    rm -f "$SCRIPT_FILE"
fi

log "Reloading systemd"
systemctl daemon-reload
systemctl reset-failed || true

if [[ "$REMOVE_ISO" == true && -f "$ISO_FILE" ]]; then
    log "Removing $ISO_FILE"
    rm -f "$ISO_FILE"
fi

if [[ "$REMOVE_VERSION" == true && -f "$VERSION_FILE" ]]; then
    log "Removing $VERSION_FILE"
    rm -f "$VERSION_FILE"
fi

if [[ "$REMOVE_LOGS" == true && -d "$LOG_DIR" ]]; then
    log "Removing $LOG_DIR"
    rm -rf "$LOG_DIR"
fi

log "Uninstall complete"