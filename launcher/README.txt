HARDENED TLAUNCHER (portable) - read me
=======================================
Everything lives in THIS folder. Nothing is installed on Windows, and your normal
%APPDATA%\.minecraft and your original TLauncher are never changed.

START
  Start TLauncher.vbs          double-click to play (no black window)
  Create Desktop Shortcut.vbs  run once to get a nice icon on Desktop + Start menu
                               (run it again if you move this folder)
  run-tlauncher.bat            same as Start, but shows a console - use it if something fails

KEEP IT UP TO DATE
  update-tlauncher.bat         updates the launcher inside this folder only, checks every
                               fingerprint, re-applies the security patches, keeps the old
                               version in backup\. Run it when TLauncher says an update exists.
  New Minecraft versions       just pick them in the launcher's version list and press Install.
                               They download into data\.minecraft (this folder).

MODS
  mods-list.txt + install-mods.bat   downloads the listed mods from Modrinth (fingerprint-checked)
                                     for the Minecraft version you choose (Fabric).
  mods-preset\                       drop any .jar here; it is copied into the game on every start
                                     (never overwrites).

REMOVE
  uninstall.bat                offers to back up your worlds to the Desktop, removes the shortcuts,
                               then deletes this folder. Nothing else.

PORTABLE (USB STICK)
  Copy this whole folder anywhere (pendrive, other drive, other PC) and start it there. Minecraft, worlds,
  mods, settings and logins all come along. Saved paths are fixed automatically on every start.
  Close TLauncher before copying. Logins travel with the folder - keep the stick safe.

WHERE THINGS ARE
  data\.minecraft   game versions, worlds (saves), mods, options, logs
  data\.tlauncher   launcher settings and your TLauncher account login
  java\jre          private Java 21, used only by this launcher
  version.txt       launcher version (used by the start script and the updater)

FIRST START
  1. Double-click "Start TLauncher.vbs". It asks once whether to COPY your worlds in (originals stay).
  2. If Windows Firewall asks about "Java" - click CANCEL / don't allow. Nothing breaks
     (TLauncher opens a local helper port; this keeps other devices on your Wi-Fi out of it).
  3. Log in with your TLauncher account, pick a version, Install, Play.

LOW-END LAPTOP (built-in graphics, 8 GB RAM)
  Settings > Memory allocation: about 3000 MB (4 GB laptop: about 1800 MB). Click Save.
  Settings > "on launch": Exit (or Hide) - frees the launcher's RAM while you play.
  The "select Java" window is optional - leave Java on the default. If Save says "Invalid path",
  clear the Java path box. Use a Fabric version + install-mods.bat (Sodium etc.) for more FPS.

DISCONNECTS ("disconnected from server", "network disconnected")
  - Wi-Fi power saving: Device Manager > Network adapters > your Wi-Fi > Power Management >
    untick "Allow the computer to turn off this device"; Power plan > Wireless adapter > Max performance.
  - Too much RAM given to the game on an 8 GB laptop causes freezes -> timeouts. Use about 3000 MB.
  - A TLauncher account can't join servers that require a Microsoft-bought account (online-mode).
  - The game log is in data\.minecraft\logs\latest.log.

MODS NOTE
  Don't put the same mod in both mods-preset\ and mods-list.txt (two copies crash Fabric).

Security changes vs. the official TLauncher: no installer or bundled offers, no ad/offer engine,
no hardware statistics, no advertising check, no automatic log upload,
HTTPS certificate checks can no longer be switched off by the launcher, HTTPS-only download mirrors (expired-cert mirror
removed), and the unsafe plain-HTTP "fix network" updater download is disabled.
hosts-block.txt is optional: lines you can add to your Windows hosts file to block ad/telemetry hosts.
