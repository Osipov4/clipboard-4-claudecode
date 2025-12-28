$WshShell = New-Object -ComObject WScript.Shell
$Startup = $WshShell.SpecialFolders("Startup")
$ShortcutPath = Join-Path $Startup "ClipboardImageDaemon.lnk"

$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "F:\workspace\AutoHotkey\ClipboardImageDaemon.ahk"
$Shortcut.WorkingDirectory = "F:\workspace\AutoHotkey"
$Shortcut.Description = "Clipboard Image Daemon"
$Shortcut.Save()

Write-Host "Shortcut created: $ShortcutPath"
