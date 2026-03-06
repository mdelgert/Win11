
```markdown
# Windows `$OEM$` Folder

The `$OEM$` folder is a special directory used during Windows installation that allows custom files and scripts to be copied into the installed system automatically.

This is commonly used for:

- unattended installations
- automated system configuration
- VM template creation
- homelab automation

It works alongside `autounattend.xml`.

---

# Folder Location in ISO

The `$OEM$` folder must be placed inside the `sources` directory of the Windows installation media.

```

ISO_ROOT
│
├ autounattend.xml
│
└ sources
  └ $OEM$

```

---

# Folder Mapping

Windows Setup automatically copies specific `$OEM$` folders to known locations.

| ISO Folder | Destination After Install |
|---|---|
| `sources\$OEM$\$1` | `C:\` |
| `sources\$OEM$\$$` | `C:\Windows` |
| `sources\$OEM$\$Docs` | `C:\Users` |

---

# Example Layout

```

sources
└ $OEM$
├ $$
│   └ Setup
│       └ Scripts
│           SetupComplete.cmd
│
└ $1
└ Setup
└ Scripts
Bootstrap.ps1

```

After Windows installs this becomes:

```

C:\Windows\Setup\Scripts\SetupComplete.cmd
C:\Setup\Scripts\Bootstrap.ps1

```

---

# SetupComplete.cmd

`SetupComplete.cmd` runs automatically after Windows Setup finishes but **before the first user login**.

Location required:

```

C:\Windows\Setup\Scripts\SetupComplete.cmd

```

This maps to:

```

sources$OEM$$$\Setup\Scripts\SetupComplete.cmd

````

Typical use cases:

- run bootstrap scripts
- install software
- download configuration
- configure system settings

Example:

```cmd
@echo off
powershell.exe -ExecutionPolicy Bypass -NoProfile -File C:\Setup\Scripts\Bootstrap.ps1
exit /b 0
````

---

# Bootstrap Script Pattern

A common pattern is:

```
Windows install
      ↓
$OEM$ files copied
      ↓
SetupComplete.cmd
      ↓
Bootstrap.ps1
      ↓
download repo
      ↓
run setup.ps1
```

Example bootstrap tasks:

* download GitHub repository
* install software
* configure system settings
* enable services

---

# Why Use `$OEM$`

Benefits:

* runs automatically during installation
* avoids manual post-install setup
* works with unattended installs
* reliable for VM template automation

Common uses:

* Proxmox VM templates
* Packer builds
* enterprise imaging
* homelab automation

---

# Logging

Setup scripts should write logs so installation issues can be diagnosed.

Common log locations:

```
C:\Windows\Panther\UnattendGC
C:\Windows\Temp
C:\Logs
```

---

# Summary

The `$OEM$` folder allows Windows installations to automatically include custom scripts and files, enabling reliable automated system provisioning during setup.

```
```
