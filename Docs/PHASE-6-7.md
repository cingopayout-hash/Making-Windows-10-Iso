# DoomOS Phases 6–7: build, test, and rollback

**Code committed, but NOT executed. No genuine DoomOS ISO has been created or tested.**

## On a Windows build machine
1. Download official Windows 10 22H2 x64 ISO from Microsoft, and install Windows ADK **Deployment Tools**.
2. Use Phase 1 Prepare-OfficialISO.ps1 and Phase 2 Stage-Windows10Pro.ps1 to prepare a verified single-image Windows 10 Pro x64 WIM in C:\DoomOS\Output\Stage-Pro\sources\install.wim.
3. Optionally preview/apply the Phase 3 provisioned-app debloat and Stage-DoomOSBranding.ps1, ensuring the WIM is dismounted before compilation.
4. From project folder in elevated PowerShell:

\`\`\`powershell
Set-ExecutionPolicy -Scope Process RemoteSigned
.\Scripts\Build-DoomOSISO.ps1 -Root C:\DoomOS
.\Scripts\Build-DoomOSISO.ps1 -Root C:\DoomOS -Apply
\`\`\`

The first command checks prerequisites without modifying the image. Apply exports a smaller install.esd with DISM recovery compression, verifies Pro edition, preserves the WIM in Backups, and uses ADK oscdimg with BIOS and UEFI boot sectors to produce C:\DoomOS\Output\DoomOS-Balanced-Gaming-Edition-x64.iso. It logs SHA-256. No OS installation or partitioning occurs.

Microsoft references:
- https://learn.microsoft.com/windows-hardware/manufacture/desktop/dism-image-management-command-line-options-s14
- https://learn.microsoft.com/windows-hardware/manufacture/desktop/oscdimg-command-line-options
- https://learn.microsoft.com/windows-hardware/get-started/adk-install

## Setup / unattended installation
**No unattended disk configuration is provided.** The future installer must ask the operator to select the disk and partition, preserving the ability to cancel. No keys, autoactivation, or destructive partition commands are included. Windows setup runs normally.

## Verification gate
1. Check resulting ISO SHA-256 and size in Logs\Build-ISO-*.log.
2. Boot in an isolated VM on your build laptop; test UEFI and BIOS boot where supported, install, create user, and reach the desktop.
3. Check installed Windows edition, Windows Update, Microsoft Store, Windows Defender, Firewall, WinRE (\`reagentc /info\`), network, audio, and Windows Installer.
4. Run \`sfc /scannow\` and \`DISM /Online /Cleanup-Image /ScanHealth\` in the VM. Document errors.
5. Only after VM approval make a Rufus USB, back up the target laptop, manually select installation partition, and measure idle RAM/CPU/disk and game frametimes on the actual hardware.

## Expected outcomes and errors
- Missing original ISO, absent staged WIM or ADK: STOP; scripts cannot build from GitHub alone.
- Existing ISO/ESD or reserved backup: STOP rather than overwrite.
- DISM image mismatch: STOP; correct Pro index selection in Phase 2.
- Failed ISO creation: check log, source boot files, free space; rollback restores WIM where possible.
- Recovery: inspect current mount state, delete only known newly generated ISO/ESD, and restore backup if the destination WIM is absent.
- **Do not upload or distribute Microsoft Windows installation binaries in a public repo.**

Smaller ESD does not directly make installed Windows faster. Maintain a system-managed page file, Windows Defender, Windows Update, Firewall, Store and servicing stack. Windows 10 standard support ended in October 2025: check ESU entitlement.
