# Puts libmpv-2.dll and ffmpeg.exe into windows\third_party. Each is over 100 MB,
# which GitHub refuses in git, so they live on this repo's "windows-deps" release
# (made once, see docs/RELEASING.md). Needs the GitHub CLI.
#
#   powershell -ExecutionPolicy Bypass -File tool\fetch_windows_deps.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$mpv = 'windows\third_party\libmpv'
$ff = 'windows\third_party\ffmpeg'
New-Item -ItemType Directory -Force $mpv, $ff | Out-Null

if (-not (Test-Path "$mpv\libmpv-2.dll")) {
    gh release download windows-deps --pattern 'libmpv-2.dll' --dir $mpv
    if ($LASTEXITCODE -ne 0) { throw 'Could not download libmpv-2.dll: is there a windows-deps release? See docs/RELEASING.md' }
}
if (-not (Test-Path "$ff\ffmpeg.exe")) {
    gh release download windows-deps --pattern 'ffmpeg.exe' --dir $ff
    if ($LASTEXITCODE -ne 0) { throw 'Could not download ffmpeg.exe: is there a windows-deps release? See docs/RELEASING.md' }
}
Get-Item "$mpv\libmpv-2.dll", "$ff\ffmpeg.exe" | Select-Object Name, @{ n = 'MB'; e = { [math]::Round($_.Length / 1MB) } } | Format-Table -AutoSize
