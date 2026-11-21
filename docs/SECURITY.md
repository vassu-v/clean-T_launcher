# Security audit of TLauncher 2.9381 / 2.9382 and what this project changes

The launcher and installer were analysed statically (unpacked, `javap`, string and config review) and in an isolated test VM.
Nothing here is guesswork: each item names the code it comes from.

## Official installer (TLauncher-Installer-1.9.8.3.exe)

- Setup Factory installer with an Opera GX offer that is **pre-ticked**.
- A hidden second installer (`TL-INSTALLER`) chooses an offer by country and runs Opera with `--silent` or 360 with `/s`.
- `_IgnoreInvalidCertificate = true` is set before it downloads executables.
- It sends your user SID and system information to `installerstat`, `removedstat` and `errorstat` endpoints.
  On failure it also sends a list of Temp `.exe` files and the names of folders in `C:\Users`.

**This project:** the installer is not used at all.

## Starter (TLauncher.exe, GraalVM native image)

- Server-driven offer and ad engine with re-offer timers.

**This project:** the starter is not used. The launcher jar runs directly on a private Java.

## Launcher jar: issues and fixes

| # | Issue | Where | Fix |
|---|---|---|---|
| 1 | One TLS error installs a trust-all `TrustManager` and an always-true `HostnameVerifier`, saves `ssl.deactivate.date` (+1 month) and renews it on every start | `Http.performGet` → `TlauncherUtil.deactivateSSL`; `TLauncher.<init>` | Calls redirected to the harmless `createTimeStart()`; the start script strips `ssl.deactivate.date` from existing configs |
| 2 | Hardware profile (OS, CPU, GPU, RAM, resolution, client UUID) sent to a stats server | `StatisticsUtil.sendMachineInfo` | `statistics.url` → `https://localhost.invalid/` |
| 3 | TLauncher account tokens POSTed to an advertising endpoint | `AdvertisingStatusObservable` | `skin.server.advertising` → `https://localhost.invalid/` |
| 4 | Launcher log, including Windows `systeminfo` output, uploaded to a log server | `TlauncherUtil.logRequest` | `log.system` → `https://localhost.invalid/` |
| 5 | "Fix network" downloads `TLauncherUpdater.exe` over plain HTTP and runs it | `MinecraftUIListener.executeFixed` | URL neutralised |
| 6 | Plain-HTTP mirrors and an expired-certificate mirror | `inner.tlauncher.properties` | Removed |
| 7 | Home page with ads, server promotion and social links | `TlauncherUtil.getStartPageAddress` | Start page loaded from this repository (`update/downloads/configs_v1/pages/`) |

## Remaining, by design (cannot be patched safely)

- **Local helper HTTPS server on ports 37842/42951**, bound to all network interfaces. It is used for the Microsoft
  login callback and the "play on server" website links. Recommendation: deny Java in the Windows Firewall prompt.
  Loopback still works.
- **Game libraries (authlib) come from TLauncher's servers.** That is how TLauncher accounts and skins work. They are
  protected by HTTPS, which can no longer be switched off.
- **Connectivity checks** fetch `check.bin` from several hosts. These are plain GETs with no data attached.

## Not found

- No keylogger, screen capture, clipboard theft, credential stealer or crypto miner.
- `mockserver-netty` and the AWS SDK are bundled but never referenced.
