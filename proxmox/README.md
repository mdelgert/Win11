
````markdown
# Proxmox Unattend ISO Auto-Update

This setup allows a Proxmox host to automatically keep a local copy of the latest Windows unattended install ISO from this repository.

It installs a small update script plus a `systemd` service and timer. The updater checks GitHub release assets, compares checksums, and only downloads a new ISO when it has changed.

## What it updates

The updater pulls these release assets from GitHub:

- `unattend.iso`
- `unattend.iso.sha256`
- `unattend.version.txt`

## What it does

On each run, the updater:

1. Downloads `unattend.version.txt`
2. Downloads `unattend.iso.sha256`
3. Compares the remote checksum to the local ISO checksum
4. Downloads `unattend.iso` only if the checksum changed
5. Verifies the checksum before replacing the local ISO
6. Saves the ISO to the Proxmox ISO storage folder
7. Writes a log file for auditing and troubleshooting

## Installed file locations

### Script
```bash
/root/scripts/update-unattend-iso.sh
````

### systemd service

```bash
/etc/systemd/system/update-unattend-iso.service
```

### systemd timer

```bash
/etc/systemd/system/update-unattend-iso.timer
```

### Downloaded ISO

```bash
/var/lib/vz/template/iso/unattend.iso
```

### Local version marker

```bash
/var/lib/vz/template/iso/unattend.version.txt
```

### Log file

```bash
/var/log/unattend-iso/update.log
```

## Repository files

This folder contains:

* `install-update-unattend-iso.sh`
* `update-unattend-iso.sh`
* `update-unattend-iso.service`
* `update-unattend-iso.timer`

## Quick install

Run this directly on the Proxmox host as `root`:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mdelgert/win11/main/proxmox/install-update-unattend-iso.sh)
```

## What the installer does

The installer:

1. Downloads the latest versions of the script and systemd unit files from this repo
2. Saves them to the correct locations on the Proxmox host
3. Makes the shell script executable
4. Reloads systemd
5. Enables and starts the timer
6. Starts the update service once immediately

## Manual install

If you want to install it manually instead of using the one-liner:

### 1. Create the script folder

```bash
mkdir -p /root/scripts
```

### 2. Download the files

```bash
curl -fsSL https://raw.githubusercontent.com/mdelgert/win11/main/proxmox/update-unattend-iso.sh -o /root/scripts/update-unattend-iso.sh
curl -fsSL https://raw.githubusercontent.com/mdelgert/win11/main/proxmox/update-unattend-iso.service -o /etc/systemd/system/update-unattend-iso.service
curl -fsSL https://raw.githubusercontent.com/mdelgert/win11/main/proxmox/update-unattend-iso.timer -o /etc/systemd/system/update-unattend-iso.timer
```

### 3. Make the script executable

```bash
chmod +x /root/scripts/update-unattend-iso.sh
```

### 4. Reload systemd

```bash
systemctl daemon-reload
```

### 5. Enable and start the timer

```bash
systemctl enable --now update-unattend-iso.timer
```

### 6. Run the service once now

```bash
systemctl start update-unattend-iso.service
```

## Verify setup

### Check the timer

```bash
systemctl list-timers update-unattend-iso.timer
systemctl status update-unattend-iso.timer
```

### Check the service

```bash
systemctl status update-unattend-iso.service
```

### Check systemd logs

```bash
journalctl -u update-unattend-iso.service -n 50 --no-pager
```

### Check the updater log

```bash
tail -n 50 /var/log/unattend-iso/update.log
```

### Check the current installed version

```bash
cat /var/lib/vz/template/iso/unattend.version.txt
```

## Default schedule

The timer is currently configured to run:

```ini
OnCalendar=hourly
```

It also uses:

```ini
Persistent=true
```

This means if the server is off when a scheduled run is missed, the job will run on the next boot.

## Change the schedule

Edit:

```bash
/etc/systemd/system/update-unattend-iso.timer
```

Examples:

### Every hour

```ini
OnCalendar=hourly
```

### Every day

```ini
OnCalendar=daily
```

### Every 15 minutes

```ini
OnCalendar=*:0/15
```

### Every 30 minutes

```ini
OnCalendar=*:0/30
```

After changing the timer:

```bash
systemctl daemon-reload
systemctl restart update-unattend-iso.timer
```

## Update or reinstall later

To refresh the installed files from GitHub, just run the installer again:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mdelgert/win11/main/proxmox/install-update-unattend-iso.sh)
```

## Troubleshooting

### Timer installed but nothing downloaded

Run the service manually:

```bash
systemctl start update-unattend-iso.service
```

Then inspect:

```bash
journalctl -u update-unattend-iso.service -n 100 --no-pager
tail -n 100 /var/log/unattend-iso/update.log
```

### ISO did not update

Check whether the checksum actually changed:

```bash
tail -n 50 /var/log/unattend-iso/update.log
```

If local and remote checksums match, no download will occur.

### Version file missing

Check that the GitHub release contains:

* `unattend.iso`
* `unattend.iso.sha256`
* `unattend.version.txt`

### Permissions issue

Make sure the installer and updater are run as `root`.

## Best practices used here

* Uses `systemd` instead of cron
* Uses checksum verification before replacing the ISO
* Uses a temp download path before moving files into place
* Writes a persistent local log file
* Saves a local version marker for quick verification
* Safe to re-run
* Only downloads the ISO when it changed

## Suggested release assets

Your GitHub Action should publish:

* `unattend.iso`
* `unattend.iso.sha256`
* `unattend.version.txt`

And inside the ISO, include:

* `version.txt`

That gives you both:

* external version visibility from Proxmox
* internal version visibility if you mount or inspect the ISO

```