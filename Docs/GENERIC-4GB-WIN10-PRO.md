# DoomOS Balanced Gaming Edition — Generic 4 GB Windows 10 Pro target

This build is **not** bound to an ASUS X441 hardware SKU. It targets Windows 10 Pro 22H2 x64 on low-specification devices with 4 GB of RAM; check CPU virtualization, storage controllers, UEFI/Legacy boot, Wi-Fi, audio and touchpad on the actual installation device.

## Baseline choices

- Official Microsoft Windows 10 22H2 x64 source, with a legitimately licensed **Pro** edition. Run DISM /Get-WimInfo to identify the correct Pro image index; indexes differ across media.
- Preserve Windows Update, component servicing, Defender, Firewall, Microsoft Store, WinRE, DirectX, .NET and installer functions.
- System-managed page file, even on mechanical HDD. Avoid disabling memory compression and page file.
- Reduce startup applications, unnecessary OEM trialware, animations and optional consumer app provisioning. Leave SysMain and Windows Search enabled by default pending measured tests.
- Avoid universal Intel graphics/chipset/network driver preintegration. Drivers must be matched to PnP IDs; unsupported generic drivers can disable devices.
- Do not assume idle RAM, frames-per-second or game compatibility targets without measurement.
- Do not auto-format or erase drives; unattended deployment disk configuration must be explicitly user-approved.
- Windows 10 regular security servicing has ended. Check Microsoft Extended Security Updates eligibility and safer supported operating-system alternatives.

## Next gates before ISO assembly

1. Record SHA-256 of official source ISO; verify Pro image index.
2. Obtain Windows ADK Deployment Tools, adequate disk space and a safe test VM.
3. Make a recoverable backup before any real-hardware installation.
4. Validate setup, network, WinRE, updates, Windows security, graphics, audio, and disk utilization in a VM and on target hardware.
5. Publish scripts/configuration and rights-cleared branding only; don't distribute Microsoft's proprietary install files in the public repo.

See `Scripts/Prepare-OfficialISO.ps1` for local source verification and extraction. That script enumerates indexes and does not write a customized image yet.
