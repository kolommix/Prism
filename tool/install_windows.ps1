# Installs (or updates / removes) Prism for the current Windows user.
#
#   powershell -ExecutionPolicy Bypass -File tool\install_windows.ps1            # install / update
#   powershell -ExecutionPolicy Bypass -File tool\install_windows.ps1 -Uninstall # remove
#   powershell -ExecutionPolicy Bypass -File tool\install_windows.ps1 -Zip       # also make dist\Prism-windows.zip
#
# Copies build\windows\x64\runner\Release to %LOCALAPPDATA%\Programs\Prism (no admin
# rights needed) and creates Start menu + Desktop shortcuts. Your library, settings
# and edits live in %APPDATA%\com.kolommix\prism and are never touched.
param(
    [switch]$Uninstall,
    [switch]$Zip,
    [switch]$NoDesktopShortcut
)
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$release = Join-Path $root 'build\windows\x64\runner\Release'
$target = Join-Path $env:LOCALAPPDATA 'Programs\Prism'
$startMenu = Join-Path ([Environment]::GetFolderPath('Programs')) 'Prism.lnk'
$desktop = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Prism.lnk'

# Close a running Prism so its files can be replaced.
Get-Process prism -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$target*" } | Stop-Process -Force

if ($Uninstall) {
    Remove-Item $startMenu, $desktop -ErrorAction SilentlyContinue
    foreach ($key in 'liner', '.liner', 'Prism.SharedPlaylist') {
        Remove-Item -Recurse -Force "HKCU:\Software\Classes\$key" -ErrorAction SilentlyContinue
    }
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }
    Write-Host 'Prism removed (your library data is kept).'
    return
}

if (-not (Test-Path (Join-Path $release 'prism.exe'))) {
    throw "No build found. Run: flutter build windows --release"
}

New-Item -ItemType Directory -Force $target | Out-Null
# Mirror the build (robocopy exit codes < 8 mean success).
# Keep the Inno Setup uninstaller if Prism was installed with Prism-Setup.exe.
robocopy $release $target /MIR /XF unins*.exe unins*.dat /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw "Copy failed (robocopy $LASTEXITCODE)" }

$exe = Join-Path $target 'prism.exe'
$shell = New-Object -ComObject WScript.Shell
$links = @($startMenu)
if (-not $NoDesktopShortcut) { $links += $desktop }
foreach ($path in $links) {
    $s = $shell.CreateShortcut($path)
    $s.TargetPath = $exe
    $s.WorkingDirectory = $target
    $s.IconLocation = "$exe,0"
    $s.Description = 'Prism music player'
    $s.Save()
}
# Same as the installer: liner:// links and .liner files open in Prism.
$classes = 'HKCU:\Software\Classes'
$command = '"' + $exe + '" "%1"'
New-Item -Force "$classes\liner\shell\open\command" | Out-Null
Set-ItemProperty "$classes\liner" -Name '(default)' -Value 'URL:Prism shared playlist'
Set-ItemProperty "$classes\liner" -Name 'URL Protocol' -Value ''
Set-ItemProperty "$classes\liner\shell\open\command" -Name '(default)' -Value $command
New-Item -Force "$classes\.liner" | Out-Null
Set-ItemProperty "$classes\.liner" -Name '(default)' -Value 'Prism.SharedPlaylist'
New-Item -Force "$classes\Prism.SharedPlaylist\shell\open\command" | Out-Null
Set-ItemProperty "$classes\Prism.SharedPlaylist" -Name '(default)' -Value 'Prism shared playlist'
Set-ItemProperty "$classes\Prism.SharedPlaylist\shell\open\command" -Name '(default)' -Value $command

Write-Host "Prism installed to $target"
Write-Host 'Start it from the Start menu or the Desktop shortcut.'

if ($Zip) {
    $dist = Join-Path $root 'dist'
    New-Item -ItemType Directory -Force $dist | Out-Null
    $zipPath = Join-Path $dist 'Prism-windows.zip'
    if (Test-Path $zipPath) { Remove-Item $zipPath }
    Compress-Archive -Path (Join-Path $release '*') -DestinationPath $zipPath -CompressionLevel Optimal
    Write-Host "Portable zip: $zipPath (unzip anywhere, run prism.exe)"
}
