# Phase 8 — Transfer to target laptop and test

Source code prepared, not run. **Do not install until the ISO passes VM tests.**

## On your other Windows build laptop
- Download/build from a licensed, official Windows 10 Pro 22H2 source as described in Docs/PHASE-6-7.md.
- Verify boot, account creation, display, updates, networking, Microsoft Store, Defender, Firewall, WinRE, sound and Windows Installer in a VM.
- Save the ISO SHA-256 and keep a second copy of the working WIM and essential user data.
- Install Rufus from its official website, choose the validated DoomOS ISO and an **empty USB drive**. Rufus erases the USB; back up anything on it first. Choose appropriate UEFI/GPT or BIOS/MBR based on the actual target's firmware.
- Do not upload Windows installation ISOs to public GitHub. The GitHub repo contains scripts/configuration only.

## On the original 4 GB laptop
1. Back up personal files externally, record license/BitLocker/recovery details if applicable, and verify you can restore the original Windows installation.
2. Identify BIOS/UEFI mode and exact Wi-Fi, graphics, audio and storage-controller driver requirements; retain backup drivers and a working recovery USB.
3. Boot the USB only when ready; select the destination manually. There is **no automatic disk wipe**. Avoid modifying partitions until data is backed up and the target disk is confirmed.
4. After installation, run the read-only audit:

\`\`\`powershell
.\Scripts\Test-DoomOSInstallation.ps1 -Root C:\DoomOS
\`\`\`

5. Check security, installed Windows Pro edition, storage drivers, Windows Update, Microsoft Store, audio, Wi-Fi, Bluetooth, USB, touchpad and recovery environment. Run \`sfc /scannow\` and \`DISM /Online /Cleanup-Image /ScanHealth\` separately.
6. Repeat boot, CPU/RAM at 10 minutes idle, disk active time, and FPS/1%-low FPS of the same games with matching drivers/settings used on baseline Windows 10. Repeat 3 times, report medians and any failures.

## Stop criteria
- Unexpected driver/device failures, repeated blue screens, updates not working, Defender/Firewall disabled, broken Store or WinRE, unstable disk operation, or significant game regression.
- If installation is unusable, restore the backed-up original system using recovery media. This repo does **not** provide an automatic destructive rollback.
- Windows 10 regular support ended 2025-10-14. Extended Security Updates eligibility should be checked; preserve security components and legitimate activation.
