# Phase 3 — Conservative offline debloat (Windows 10 Pro 22H2 x64)

**Status:** scripts and checklist committed; changes not executed against a Windows image yet.

## Inputs
- Phase 2's verified single-edition `C:\DoomOS\Output\Stage-Pro\sources\install.wim`.
- Windows PowerShell 5.1 elevated on a Windows build host with the DISM PowerShell module.
- Adequate working disk space for WIM backup and mounted image.

## Why not extreme removal?
An ESD-compressed installer does **not** reduce idle memory by itself. Aggressive component deletion can break the Microsoft Store, servicing, gaming middleware, network onboarding, driver installs and security updates. The conservative profile targets only seven consumer provisioned-app identities *if present*.

## Preview first
From the repository root:
```powershell
.\Scripts\Customize-DoomOSApps.ps1 -Root C:\DoomOS
```
This mounts the staged WIM read-only, logs candidate apps, and discards the mount. Examine `Logs\Phase3-Apps-*.log`.

## Apply after review
```powershell
.\Scripts\Customize-DoomOSApps.ps1 -Root C:\DoomOS -Apply
```
The script validates that image index 1 is a single x64 Windows 10 Pro image, copies it to `Backups\PreDebloat-*.wim`, compares SHA-256 hashes, mounts the staged WIM, removes only exact allowlisted provisioned packages, checks none remain, and commits the result. On errors, it attempts to discard the mount. **It does not touch the running Windows installation**.

## Optional apps in this profile
| Package name | Action | Compatibility note |
| --- | --- | --- |
| Microsoft.BingNews | Remove if present | News app only; web news unaffected |
| Microsoft.BingWeather | Remove if present | Weather app disappears |
| Microsoft.GetHelp | Remove if present | Built-in Get Help client absent |
| Microsoft.Getstarted | Remove if present | Tips/Get Started absent |
| Microsoft.MicrosoftSolitaireCollection | Remove if present | Solitaire must be reinstalled separately |
| Microsoft.WindowsFeedbackHub | Remove if present | Built-in feedback app absent |
| Microsoft.WindowsMaps | Remove if present | Offline Maps UI unavailable |

Default **keep**: Microsoft Store and StorePurchaseApp, App Installer, all VCLibs/.NET/UI.Xaml frameworks, Photos, DesktopAppInstaller, Xbox identity and gaming services, Defender, Firewall, WinRE, Windows Update, Windows Installer, Windows Search, SysMain, networking, audio, printing and servicing stack.

OneDrive is a separate Win32 client, **not** a provisioned-app removal in this script. Cortana, Mixed Reality and optional feature removal need individualized testing, not an unchecked bulk removal list.

## NTLite safe profile, applied only to staged copy
1. Add `Stage-Pro\sources\install.wim`, choose **Windows 10 Pro** index 1 and load.
2. Components: remove only the seven optional consumer apps above if available; avoid removing system/framework packages, Store, WinRE, update and servicing components.
3. Features: **leave optional Windows features unchanged** in the first build.
4. Drivers: do not integrate unverified ASUS/Intel drivers for the hardware-neutral target.
5. Settings: do not globally disable security, automatic updates, Windows Search or SysMain. Configure optional visual/startup settings after installation.
6. Apply: **Save image** and validate with DISM. Do not combine NTLite and the PowerShell app-removal script on the same mounted WIM; choose one workflow or apply serially to dismounted image.

## Rollback / troubleshooting
- To undo, ensure the image is **not mounted** and manually copy a validated `Backups\PreDebloat-*.wim` over `Output\Stage-Pro\sources\install.wim`. Keep backups outside the ISO staging directory.
- If DISM reports pending mount changes, inspect `Get-WindowsImage -Mounted` or `dism /Get-MountedWimInfo` before manual recovery. Never delete a mount directory while mounted.
- If a package isn't found, the script skips it; do not invent package identities.
- If mounting fails, close Explorer windows and antivirus scans of mount directory, check free space and permissions.
- Verify `dism /Get-WimInfo /WimFile:C:\DoomOS\Output\Stage-Pro\sources\install.wim` after saving.

## Security/lifecycle
Windows 10 standard support ended October 14, 2025. Keep security components, and evaluate ESU eligibility. Continue with Phase 4 only after a successful run and servicing validation.
