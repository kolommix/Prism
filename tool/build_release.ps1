# Builds every release artifact into dist\ :
#   Prism-Setup-<version>.exe         Windows installer (Inno Setup, per-user, no admin)
#   Prism-<version>.apk               Android, all CPUs (signed)
#   Prism-<version>-arm64-v8a.apk     Android, most phones (smaller)
#   Prism-<version>-armeabi-v7a.apk   Android, old 32-bit phones
#
#   powershell -ExecutionPolicy Bypass -File tool\build_release.ps1
#
# Signing key: %USERPROFILE%\.prism-signing\key.properties (kept outside the
# project). Without it the APKs are signed with the debug key (still installable).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$env:Path += ';C:\dev\flutter\bin'
if (-not $env:JAVA_HOME) { $env:JAVA_HOME = 'C:\Program Files\Microsoft\jdk-17.0.21.21-hotspot' }

$version = (Select-String -Path pubspec.yaml -Pattern '^version:\s*([0-9.]+)').Matches[0].Groups[1].Value
$env:PRISM_VERSION = $version
$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null

Write-Host "== Prism ${version} - Windows"
Get-Process prism -ErrorAction SilentlyContinue | Stop-Process -Force
flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw 'Windows build failed' }
$iscc = @("$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe", "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup not found (winget install JRSoftware.InnoSetup)' }
& $iscc /Q installer\prism.iss
if ($LASTEXITCODE -ne 0) { throw 'Installer build failed' }

Write-Host "== Prism ${version} - Android"
flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw 'APK build failed' }
Copy-Item build\app\outputs\flutter-apk\app-release.apk (Join-Path $dist "Prism-$version.apk") -Force
flutter build apk --release --split-per-abi
if ($LASTEXITCODE -ne 0) { throw 'Split APK build failed' }
foreach ($abi in 'arm64-v8a', 'armeabi-v7a') {
    Copy-Item "build\app\outputs\flutter-apk\app-$abi-release.apk" (Join-Path $dist "Prism-$version-$abi.apk") -Force
}

# Show who signed the APK (release key vs debug key).
$apksigner = Get-ChildItem "$env:LOCALAPPDATA\Android\Sdk\build-tools" -Recurse -Filter apksigner.bat | Select-Object -Last 1
if ($apksigner) {
    & $apksigner.FullName verify --print-certs (Join-Path $dist "Prism-$version.apk") | Select-String 'Signer #1 certificate DN'
}

Write-Host "== Done"
Get-ChildItem $dist -File | Where-Object Name -like "Prism*$version*" |
    Select-Object Name, @{ n = 'MB'; e = { [math]::Round($_.Length / 1MB, 1) } } | Format-Table -AutoSize
