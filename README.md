# clean-T_launcher: Hardened, portable TLauncher for Windows

A one-click installer that builds a **clean, portable TLauncher**: no ads, no bundled offers, no tracking, no installer junk.
Everything lives in one folder you can move, back up or delete. Nothing is installed system-wide, and your normal
`.minecraft` and any existing TLauncher are never touched.

> This project ships **no TLauncher or Minecraft files**. The installer downloads TLauncher from TLauncher's own
> server, checks every file's fingerprint, and patches it **on your PC**.

## Install (Windows 10/11, 64-bit)

1. Download **[`install.bat`](https://raw.githubusercontent.com/vassu-v/clean-t_launcher/main/install.bat)**: right-click the link, then *Save link as...*.
2. Put it in a folder such as `C:\Games` and double-click it.
3. Wait a few minutes. About 300 MB is downloaded: Java about 200 MB, the launcher and its libraries about 70 MB.
4. Say **Y** to create a Desktop shortcut, then play.

If Windows shows *"Windows protected your PC"*, click **More info**, then **Run anyway**. The script is plain text, so you can open it in Notepad and read it first.

Running `install.bat` again on an existing folder repairs and updates it. Your worlds, settings and mod list are kept.

## What's in the folder

| File | What it does |
|---|---|
| `Start TLauncher.vbs` | Starts the launcher with no console window |
| `Create Desktop Shortcut.vbs` | Adds a Desktop and Start menu shortcut with an icon |
| `run-tlauncher.bat` | Same as Start, but shows a console if something goes wrong |
| `update-tlauncher.bat` | Updates TLauncher **inside this folder only**: checks fingerprints, re-applies the patches and keeps a backup |
| `install-mods.bat` + `mods-list.txt` | Installs or updates the mods in the list from Modrinth for your Fabric version (SHA-512 checked) |
| `mods-preset\` | Drop mod `.jar` files here; they are copied into the game on every start |
| `uninstall.bat` | Backs up your worlds to the Desktop, removes the shortcuts, then deletes the folder |
| `data\` | Your game files, worlds, settings and logins |

## What is changed compared with the official TLauncher

| Official TLauncher | Hardened |
|---|---|
| Installer with pre-ticked offers (Opera and others) | No installer and no offers |
| Server-driven ad and offer engine in the starter | Starter is not used at all |
| Home screen: ads, "recommended servers", Facebook, Discord, Premium | Clean local home page with tips |
| Hardware statistics (CPU, GPU, RAM, OS) sent to a stats server | Disabled |
| Launcher log, including Windows `systeminfo`, uploaded to a log server | Disabled |
| A single HTTPS error **switches off certificate checks for a month, renewed on every start** | Never switched off |
| "Fix network" button downloads and runs an `.exe` over plain HTTP | Disabled |
| Mirrors over plain HTTP and one with an expired certificate | HTTPS-only mirrors |
| Shared Java and `%APPDATA%` folders | Private Java 21, and everything in one folder |

See [`docs/SECURITY.md`](docs/SECURITY.md) for the full audit and [`tools/harden.py`](tools/harden.py) for the exact patches.
The same patches are in [`launcher/update-tlauncher.ps1`](launcher/update-tlauncher.ps1).

## New Minecraft versions

Choose any version in the launcher's list and press **Install**. TLauncher downloads the Java each version needs
from Mojang, for example Java 25 for 26.x, into the `data` folder. Your private Java 21 only runs the launcher itself.

## Accounts

- **TLauncher account:** log in under *Accounts*; your skins work as usual.
- **Microsoft account:** supported; the login opens in your browser.

## Tips for low-end PCs (built-in graphics, 8 GB RAM)

- In Settings, set *Memory allocation* to about **3000 MB** (about 1800 MB on 4 GB of RAM).
- In Settings, set *on launch* to **Exit** to free the launcher's RAM while you play.
- Install a Fabric version, then run `install-mods.bat` for Sodium, Lithium, FerriteCore, ModernFix and Entity Culling.
- If Windows Firewall asks about **Java**, click **Cancel**. Nothing breaks, and devices on your Wi-Fi can't reach the launcher's local port.

## Troubleshooting

| Problem | Fix |
|---|---|
| Nothing happens on start | Run `run-tlauncher.bat` and read the error |
| "Disconnected from server" | Turn off Wi-Fi power saving (Device Manager, Wi-Fi adapter, Power Management); don't give the game more than about 3000 MB on 8 GB; check `data\.minecraft\logs\latest.log` |
| Update says "needs a different Java" | Run `install.bat` again; it rebuilds Java |
| Want to start fresh | Run `uninstall.bat`, then `install.bat` |

## Legal

Unofficial project, not affiliated with TLauncher or Mojang/Microsoft. "Minecraft" is a trademark of Mojang/Microsoft.
Buying Minecraft supports its developers.
