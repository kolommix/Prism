; Prism Windows installer (Inno Setup 6).
; Build:  powershell -File tool\build_release.ps1   (or ISCC installer\prism.iss after flutter build windows --release)
; Installs per-user (no admin needed) to %LOCALAPPDATA%\Programs\Prism.

#define AppName "Prism"
#define AppVersion GetEnv("PRISM_VERSION")
#if AppVersion == ""
  #define AppVersion "1.0.0"
#endif
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{6F1B0D2C-3E4A-4C55-9B7E-5A1F2D9C8E11}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=kolommix
DefaultDirName={localappdata}\Programs\Prism
DefaultGroupName=Prism
PrivilegesRequired=lowest
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=Prism-Setup-{#AppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\prism.exe
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"

[InstallDelete]
; Older versions shipped a Windows plugin that started the location service (docs/PRIVACY.md).
Type: files; Name: "{app}\permission_handler_windows_plugin.dll"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Prism"; Filename: "{app}\prism.exe"
Name: "{group}\Uninstall Prism"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Prism"; Filename: "{app}\prism.exe"; Tasks: desktopicon

[Registry]
; Shared playlists: liner:// links and .liner files open in Prism.
Root: HKCU; Subkey: "Software\Classes\liner"; ValueType: string; ValueName: ""; ValueData: "URL:Prism shared playlist"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\liner"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\liner\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\prism.exe"" ""%1"""
Root: HKCU; Subkey: "Software\Classes\.liner"; ValueType: string; ValueName: ""; ValueData: "Prism.SharedPlaylist"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\Prism.SharedPlaylist"; ValueType: string; ValueName: ""; ValueData: "Prism shared playlist"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\Prism.SharedPlaylist\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\prism.exe"" ""%1"""

[Run]
Filename: "{app}\prism.exe"; Description: "Start Prism"; Flags: nowait postinstall skipifsilent

; Your library, settings and edits (in %APPDATA%\com.kolommix\prism) are kept on uninstall.
