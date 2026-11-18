# Phase 5 — wallpaper branding staging

Source code only, **not executed against installation media**.

The provided wallpaper contains the words *Competitive Edition*. It will not be silently relabeled to Balanced Gaming Edition. The other uploaded image is an icon reference sheet, not a set of standalone Windows `.ico` files.

After Phase 2 has prepared the single-edition Pro stage and you have extracted/copied your owned original wallpaper to the build PC:

```powershell
.\Scripts\Stage-DoomOSBranding.ps1 -Root C:\DoomOS -WallpaperPath 'C:\DoomOS\Branding\DoomOS-Wallpaper.jpg'
```

The script copies the image into `Output\Stage-Pro\sources\$OEM$\$$\Web\Wallpaper\DoomOS`. During standard Windows Setup, the `$OEM$\$$` path is mapped to the Windows installation directory. The script checks hashes, refuses overwrites, and leaves the source untouched.

**Limitations:** Copying an image does not set it as the default wallpaper or lock screen. A validated theme/unattend configuration will be needed later. Do not patch signed Windows DLLs, explorer.exe or system icons. Convert icons from the owned reference art to valid multi-resolution .ico files for custom shortcuts, subject to testing. OEM branding should not misstate device vendor identity.

Rollback: delete the specifically staged wallpaper file from the stage. No changes to the currently running OS.
