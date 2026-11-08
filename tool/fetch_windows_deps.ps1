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
# yt-dlp.exe (saves imported songs) from yt-dlp's own release, pinned and checked
# by SHA-256. Bump both lines together; Prism also updates it by itself later.
$yt = 'windows\third_party\yt-dlp'
$ytVersion = '2026.10.26'
$ytSha256 = 'F5389D3698ECDE4EF06F4E6B1CE0294FE9AC1396228C8990B8D3416D6D177A7D'
New-Item -ItemType Directory -Force $yt | Out-Null
if (-not (Test-Path "$yt\yt-dlp.exe") -or (Get-FileHash "$yt\yt-dlp.exe" -Algorithm SHA256).Hash -ne $ytSha256) {
    Invoke-WebRequest "https://github.com/yt-dlp/yt-dlp/releases/download/$ytVersion/yt-dlp.exe" -OutFile "$yt\yt-dlp.exe"
    if ((Get-FileHash "$yt\yt-dlp.exe" -Algorithm SHA256).Hash -ne $ytSha256) {
        Remove-Item "$yt\yt-dlp.exe"
        throw 'yt-dlp.exe does not match its pinned SHA-256'
    }
}
Get-Item "$mpv\libmpv-2.dll", "$ff\ffmpeg.exe", "$yt\yt-dlp.exe" | Select-Object Name, @{ n = 'MB'; e = { [math]::Round($_.Length / 1MB) } } | Format-Table -AutoSize
