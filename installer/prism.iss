; Prism Windows installer (Inno Setup 6.7+).
; Build:  powershell -File tool\build_release.ps1   (or ISCC installer\prism.iss after flutter build windows --release)
; Installs per-user (no admin needed) to %LOCALAPPDATA%\Programs\Prism.
; Pictures: installer\art (tool\make_installer_art.ps1). Texts: info_en.txt / info_ru.txt.

#define AppName "Prism"
#define AppVersion GetEnv("PRISM_VERSION")
#if AppVersion == ""
  #define AppVersion "1.0.0"
#endif
#define BuildDir "..\build\windows\x64\runner\Release"
#define RepoUrl "https://github.com/kolommix/Prism"

[Setup]
AppId={{6F1B0D2C-3E4A-4C55-9B7E-5A1F2D9C8E11}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=kolommix
AppPublisherURL={#RepoUrl}
AppSupportURL={#RepoUrl}/issues
AppUpdatesURL={#RepoUrl}/releases
AppComments=Music player for your own music files
VersionInfoVersion={#AppVersion}
VersionInfoDescription={#AppName} setup
VersionInfoProductName={#AppName}
DefaultDirName={localappdata}\Programs\Prism
DefaultGroupName=Prism
PrivilegesRequired=lowest
DisableProgramGroupPage=yes
DisableWelcomePage=no
DisableDirPage=auto
OutputDir=..\dist
OutputBaseFilename=Prism-Setup-{#AppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\prism.exe
UninstallDisplayName={#AppName}
Compression=lzma2/ultra64
SolidCompression=yes
; Dark, like the app, with Prism's own near-black and pictures.
WizardStyle=modern dark hidebevels
WizardBackColor=#131318
WizardImageFile=art\wizard.png
WizardSmallImageFile=art\wizard_small.png
WizardImageBackColor=#131318
WizardSizePercent=110
LicenseFile=..\LICENSE
ShowLanguageDialog=auto
UsePreviousLanguage=no
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"; InfoBeforeFile: "info_en.txt"
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"; InfoBeforeFile: "info_ru.txt"

[CustomMessages]
en.ShortcutsGroup=Shortcuts:
ru.ShortcutsGroup=Ярлыки:
en.DesktopIcon=Create a desktop shortcut
ru.DesktopIcon=Создать ярлык на рабочем столе
en.LinksGroup=Shared playlists:
ru.LinksGroup=Общие плейлисты:
en.LinksTask=Open liner:// links and .liner files from friends with Prism
ru.LinksTask=Открывать ссылки liner:// и файлы .liner от друзей в Prism
en.StartPrism=Start Prism now
ru.StartPrism=Запустить Prism
en.UpgradeWelcome=Prism is already on this computer. This updates it to version %1 in place.%n%nYour library, playlists, statistics and settings stay as they are: there is no need to uninstall first.%n%nPrism closes for a moment if it is open.
ru.UpgradeWelcome=Prism уже установлен на этом компьютере. Сейчас он обновится до версии %1 прямо на месте.%n%nМедиатека, плейлисты, статистика и настройки останутся как есть: удалять старую версию не нужно.%n%nЕсли Prism открыт, он ненадолго закроется.
en.RemoveData=Also delete your Prism library, playlists, statistics and settings?%n%n(%1)%n%nYour music files are never deleted. Choose No to keep everything for a later install.
ru.RemoveData=Удалить также медиатеку Prism, плейлисты, статистику и настройки?%n%n(%1)%n%nМузыкальные файлы не удаляются никогда. Выберите «Нет», чтобы сохранить всё для следующей установки.

[Messages]
en.WelcomeLabel2=This will install [name/ver] on your computer, for your account only.%n%nPrism plays the music you already have: point it at your music folders and it finds everything by itself. It also imports playlists from streaming services, edits songs, shows lyrics and lets you listen together with friends.%n%nClose other programs before you go on.
ru.WelcomeLabel2=Будет установлен [name/ver], только для вашей учётной записи.%n%nPrism играет музыку, которая у вас уже есть: укажите папки с музыкой, и он сам всё найдёт. Ещё он импортирует плейлисты из стриминговых сервисов, редактирует песни, показывает тексты и позволяет слушать вместе с друзьями.%n%nПеред продолжением закройте другие программы.
en.FinishedLabel=Prism is installed.%n%nWhen it starts for the first time, a short tour shows the basics: adding your music folders, the player, playlists and imports. You can see it again any time in Settings.%n%nTip: Prism stays in the tray when you close the window; quit it from the tray icon.
ru.FinishedLabel=Prism установлен.%n%nПри первом запуске короткий тур покажет главное: как добавить папки с музыкой, плеер, плейлисты и импорт. Его можно открыть снова в Настройках.%n%nСовет: при закрытии окна Prism остаётся в трее; выйти можно через значок в трее.

[Tasks]
Name: "desktopicon"; Description: "{cm:DesktopIcon}"; GroupDescription: "{cm:ShortcutsGroup}"
Name: "links"; Description: "{cm:LinksTask}"; GroupDescription: "{cm:LinksGroup}"

[InstallDelete]
; Older versions shipped a Windows plugin that started the location service (docs/PRIVACY.md).
Type: files; Name: "{app}\permission_handler_windows_plugin.dll"
; Older versions shipped the one-file yt-dlp.exe next to prism.exe (now in its own yt-dlp folder).
Type: files; Name: "{app}\yt-dlp.exe"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Prism"; Filename: "{app}\prism.exe"; Comment: "Music player"
Name: "{group}\Uninstall Prism"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Prism"; Filename: "{app}\prism.exe"; Comment: "Music player"; Tasks: desktopicon

[Registry]
; Shared playlists: liner:// links and .liner files open in Prism.
Root: HKCU; Subkey: "Software\Classes\liner"; ValueType: string; ValueName: ""; ValueData: "URL:Prism shared playlist"; Flags: uninsdeletekey; Tasks: links
Root: HKCU; Subkey: "Software\Classes\liner"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Tasks: links
Root: HKCU; Subkey: "Software\Classes\liner\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\prism.exe"",0"; Tasks: links
Root: HKCU; Subkey: "Software\Classes\liner\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\prism.exe"" ""%1"""; Tasks: links
Root: HKCU; Subkey: "Software\Classes\.liner"; ValueType: string; ValueName: ""; ValueData: "Prism.SharedPlaylist"; Flags: uninsdeletevalue; Tasks: links
Root: HKCU; Subkey: "Software\Classes\Prism.SharedPlaylist"; ValueType: string; ValueName: ""; ValueData: "Prism shared playlist"; Flags: uninsdeletekey; Tasks: links
Root: HKCU; Subkey: "Software\Classes\Prism.SharedPlaylist\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\prism.exe"",0"; Tasks: links
Root: HKCU; Subkey: "Software\Classes\Prism.SharedPlaylist\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\prism.exe"" ""%1"""; Tasks: links

[Run]
Filename: "{app}\prism.exe"; Description: "{cm:StartPrism}"; Flags: nowait postinstall skipifsilent
; Update from inside Prism (quiet install): Prism opens again by itself.
Filename: "{app}\prism.exe"; Flags: nowait skipifnotsilent

[Code]
// Installing over an existing Prism is an update: no license, folder or task
// questions again (the earlier answers are kept), and the welcome page says
// that nothing needs to be uninstalled.
function IsUpgrade: Boolean;
begin
  Result := RegKeyExists(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{6F1B0D2C-3E4A-4C55-9B7E-5A1F2D9C8E11}_is1');
end;

procedure InitializeWizard;
begin
  if IsUpgrade then
    WizardForm.WelcomeLabel2.Caption := FmtMessage(CustomMessage('UpgradeWelcome'), ['{#AppVersion}']);
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := IsUpgrade and ((PageID = wpLicense) or (PageID = wpInfoBefore) or (PageID = wpSelectDir) or (PageID = wpSelectTasks) or (PageID = wpReady));
end;

// Uninstall: the library data stays unless the user says to delete it.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Data: String;
begin
  if CurUninstallStep <> usPostUninstall then exit;
  Data := ExpandConstant('{userappdata}\com.kolommix\prism');
  if not DirExists(Data) then exit;
  if UninstallSilent then exit;
  if SuppressibleMsgBox(FmtMessage(CustomMessage('RemoveData'), [Data]), mbConfirmation, MB_YESNO or MB_DEFBUTTON2, IDNO) = IDYES then
    DelTree(Data, True, True, True);
end;
