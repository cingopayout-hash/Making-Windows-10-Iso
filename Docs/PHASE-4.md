# Phase 4 — Low-end PC responsiveness (source published, not executed)

Target: generic Windows 10 Pro 22H2 x64 with 4 GB RAM, slow HDD and low-end integrated graphics. Settings are **optional after installation** and are not built into the ISO yet.

## Why this is balanced

Windows security, services, Windows Update, memory protections, system-managed page file, Windows Search, SysMain and power plan are left unchanged. No fake FPS-boost registry tweaks are used.

The four reversible **current-user** adjustments are:
- Disable taskbar animations.
- Disable window minimize/maximize animations.
- Disable transparency.
- Disable background activity for Store apps via the user preference.

These reduce distractions and possibly overhead; FPS and RAM savings are not guaranteed, and Store app notifications/background jobs may be affected.

## Commands
Run PowerShell **as administrator in the user account to be tuned**:

```powershell
Set-ExecutionPolicy -Scope Process RemoteSigned
.\Scripts\Set-DoomOSBalanced.ps1 -Root C:\DoomOS
.\Scripts\Set-DoomOSBalanced.ps1 -Root C:\DoomOS -Apply
```

Before changes, inspect the preview log. Apply creates a timestamped JSON backup in `C:\DoomOS\Backups`. To roll back:
```powershell
.\Scripts\Set-DoomOSBalanced.ps1 -Root C:\DoomOS -Rollback -BackupFile 'C:\DoomOS\Backups\DoomOS-Settings-YYYYMMDD-HHMMSS-fff.json'
```
Use the actual backup file path. Sign out/in for visual changes.

## Hardware-dependent decisions for 4 GB laptops

- Keep virtual memory **system managed**. Disabling pagefile can crash apps and games.
- Keep Windows Search and SysMain initially; benchmark HDD queue, active time and boot time before any manual decision.
- Use Windows' disk Optimize Drives for HDD defrag; do not defragment an SSD as though it were an HDD.
- Keep the laptop plugged in for games; measure temperatures and avoid unsupported CPU/GPU overclocking.
- For Intel HD Graphics 500, install an OEM-compatible or Intel-supported graphics driver only after matching actual hardware IDs.
- Disable individual app overlays where possible; Game Mode and fullscreen optimizations can be A/B tested per game.
- Target 720p/low settings for older games and cap FPS to a stable sustainable value rather than chasing high averages.

## Benchmark procedure
Record stock Windows baseline and DoomOS with the same hardware, drivers and game versions: boot-to-desktop (three trials), 10-minute idle working set/commit, CPU%, disk active time and queue, in-game median frame rate, 1% low FPS and frametime spikes, temperatures and unexpected driver/Windows Update failures. Optimize only where measured improvements outweigh breakage.

## Troubleshooting
If settings appear unchanged, sign out/in. If background Store notifications stop, roll back. If a registry write fails, use the backup JSON to restore existing settings; script logs success/failure per setting. It never erases personal data.
