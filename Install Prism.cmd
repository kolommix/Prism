@echo off
rem Double-click to install/update Prism (Start menu + Desktop shortcut).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tool\install_windows.ps1" %*
pause
