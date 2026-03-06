#!/usr/bin/env bash
#
# File: proxmox/install-update-unattend-iso.sh
#
# Purpose:
#   Bootstrap the unattended Windows ISO auto-update system on a Proxmox host.
#
# What this installer does:
#   1. Downloads the latest versions of these files from this GitHub repo:
#        - update-unattend-iso.sh
#        - update-unattend-iso.service
#        - update-unattend-iso.timer
#   2. Saves them to the correct locations on the Proxmox host
#   3. Makes the shell script executable
#   4. Reloads systemd
#   5. Enables and starts the timer
#   6. Optionally starts the update service immediately
#
# Files installed:
#   Script:
#     /root/scripts/update-unattend-iso.sh
#
#   Service:
#     /etc/systemd/system/update-unattend-iso.service
#
#   Timer:
#     /etc/systemd/system/update-unattend-iso.timer
#
# What the installed updater does:
#   - Checks GitHub Releases for:
#       unattend.iso
#       unattend.iso.sha256
#       unattend.version.txt
#   - Downloads unattend.iso only if the checksum changed
#   - Verifies checksum before replacing the local ISO
#   - Saves the ISO to:
#       /var/lib/vz/template/iso/unattend.iso
#   - Saves the current version marker to:
#       /var/lib/vz/template/iso/unattend.version.txt
#   - Writes logs to:
#       /var/log/unattend-iso/update.log
#
# Usage:
#   Run directly on the Proxmox host as root:
#
#     bash <(curl -fsSL https://raw.githubusercontent.com/mdelgert/win11/main/proxmox/install-update-unattend-iso.sh)
#
# Manual usage:
#   chmod +x install-update-unattend-iso.sh
#   ./install-update-unattend-iso.sh
#
# Verify setup:
#   systemctl list-timers update-unattend-iso.timer
#   systemctl status update-unattend-iso.timer
#   journalctl -u update-unattend-iso.service -n 50 --no-pager
#   tail -n 50 /var/log/unattend-iso/update.log
#
# Notes:
#   - Intended for Proxmox VE hosts
#   - Should be run as root
#   - Safe to run again to refresh the installed files
#   - Uses GitHub raw file URLs as the source of truth
#

set -euo pipefail

BASE_URL="https://raw.githubusercontent.com/mdelgert/win11/main/proxmox"

mkdir -p /root/scripts

curl -fsSL "${BASE_URL}/update-unattend-iso.sh" -o /root/scripts/update-unattend-iso.sh
curl -fsSL "${BASE_URL}/update-unattend-iso.service" -o /etc/systemd/system/update-unattend-iso.service
curl -fsSL "${BASE_URL}/update-unattend-iso.timer" -o /etc/systemd/system/update-unattend-iso.timer

chmod +x /root/scripts/update-unattend-iso.sh

systemctl daemon-reload
systemctl enable --now update-unattend-iso.timer
systemctl start update-unattend-iso.service

echo "Setup complete."
systemctl status update-unattend-iso.timer --no-pager