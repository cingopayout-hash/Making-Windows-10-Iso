# Phase 6/7: repeatable build + static checks

**Status: source committed to GitHub. Not executed against official Windows installation media. No bootable DoomOS ISO has yet been produced or verified.**

## Inputs
- Local official Microsoft Windows 10 22H2 x64 ISO containing **Windows 10 Pro**.
- Windows x64 build computer with Windows PowerShell 5.1, DISM commands and Windows ADK Deployment Tools (\`oscdimg\`).
- At least 30–40 GB working space, and adequate disk space to keep WIM backups.
- A license for Windows 10 Pro on the installation target.
- Original Windows ISO must NOT be committed to the public repository.

## Orchestrated build (PowerShell as Administrator)
From the cloned repository root:

\`\`\`powershell
Set-ExecutionPolicy -Scope Process RemoteSigned
.\Scripts\Invoke-DoomOSBuild.ps1 -Root C:\DoomOS -IsoPath 'D:\Downloads\Win10_22H2_x64.iso'
.\Scripts\Invoke-DoomOSBuild.ps1 -Root C:\DoomOS -IsoPath 'D:\Downloads\Win10_22H2_x64.iso' -Apply -Debloat
\`\`\`

The first invocation previews and does not change files. The second (only after review) creates a local project, copies source media, exports the Windows 10 Pro image, optionally debloats seven allowlisted consumer apps, exports ESD with DISM recovery compression, compiles BIOS/UEFI ISO using ADK oscdimg, and performs read-only ISO integrity checks. The build **refuses overwrites**; do not re-run Apply on an existing workspace unless you manually inspect and relocate prior output.

Output expected *only after successful execution*: \`C:\DoomOS\Output\DoomOS-Balanced-Gaming-Edition-x64.iso\`; logs in \`C:\DoomOS\Logs\`. The ISO is still unapproved until its VM testing succeeds.

## Theme-only answer file
\`Unattend/ThemeOnly.xml\` provides a minimal oobeSystem theme template (no product key, users, disk or partition configuration). It must be validated using Windows System Image Manager with the correct edition and install image *before* enabling it. It is deliberately **not injected** by the automated build; an unvalidated unattend can break Windows Setup. If used later, ensure \`DoomOS-Wallpaper.jpg\` exists in \`%WINDIR%\Web\Wallpaper\DoomOS\`.

## VM test checklist — manual gate
1. Preserve ISO SHA256 in the build log and compare with \`Get-FileHash\` at test time.
2. Boot a disposable VM using UEFI; test Legacy BIOS if available.
3. Ensure Setup sees Windows 10 Pro, no automated disk wipe, prompt for disk/partition, and successful installation.
4. At desktop: verify Windows edition and activation pathway, Wi-Fi/network, Microsoft Store, Defender, Firewall, Windows Update, Windows Recovery Environment, settings, audio, keyboard and app installation.
5. Run \`sfc /scannow\` and \`DISM /Online /Cleanup-Image /ScanHealth\` in the VM.
6. Record installation success, VM firmware, VM RAM and resource usage, and any error codes; do not extrapolate VM frame rates to the original Celeron laptop.
7. Only after VM tests should the ISO be written to USB and manually installed on the original laptop following a full backup.

## Diagnosing failures
- \`ISO not found\`: correct -IsoPath.
- \`Stage already exists\`: preserve or manually move previous run's stage; do not overwrite silently.
- No Pro edition: verify Microsoft ISO, never guess edition index.
- Missing ADK: install Deployment Tools and rerun preview.
- ESD conversion error: check DISM logs, free space; inspect partial files.
- Failing ISO static checks: do not flash or install. Inspect \`Logs\ISO-Validation-*.json\`.
- VM boot failure: ISO compilation is not proof of bootability, adjust boot media only after diagnosis.

## Known unfinished areas
The default wallpaper isn't activated automatically yet; theme answer file still requires Windows SIM/VM validation. There is no automated partitioning or key injection by design. No true idle RAM/performance results exist until real-hardware benchmarks.

Microsoft technical reference: https://learn.microsoft.com/windows-hardware/manufacture/desktop/oscdimg-command-line-options
