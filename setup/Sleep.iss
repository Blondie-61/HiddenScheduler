; === SleepSetup_v1.2.1.iss ===

[Setup]
AppName=Sleep Tool
AppVersion=1.2.1 (Build 85)
AppPublisher=BlondieSoft
DefaultDirName=C:\Tools\Sleep
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\Sleep.exe
OutputDir=.\Output
OutputBaseFilename=SleepSetup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=admin
VersionInfoVersion=1.2.1
VersionInfoTextVersion=1.2.1
VersionInfoProductVersion=1.2.1

[Files]
Source: "Sleep.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "WakeHidden.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "sleep.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "icq-uh-oh.wav"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge0.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge1.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge2.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge3.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge4.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge5.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge6.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge7.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge8.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge9.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge9+.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge0_w.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge1_w.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge2_w.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge3_w.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge4_w.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge5_w.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge6_w.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge7_w.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge8_w.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge9_w.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithBlueBadge9+_w.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithRedBadge.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IconWithRedBadge_w.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Delphi-Projekte\Blondie\WVL\Main\changelog.txt"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
[Icons]
; Startmenü-Eintrag "Sleep", startet WakeHidden.exe
Name: "{autoprograms}\Sleep"; Filename: "{app}\WakeHidden.exe"

[Registry]
; --- Altbestand beim Installieren vollständig entfernen ---
Root: HKCR; Subkey: "*\shell\Sleep"; Flags: deletekey
Root: HKCR; Subkey: "*\shell\SleepIndividuell"; Flags: deletekey

; --- Kontextmenü "Sleep ..." neu anlegen ---
Root: HKCR; Subkey: "*\shell\Sleep"; ValueType: string; ValueName: "MUIVerb"; ValueData: "Schlafen ..."
Root: HKCR; Subkey: "*\shell\Sleep"; ValueType: string; ValueName: "SubCommands"; ValueData: ""
Root: HKCR; Subkey: "*\shell\Sleep"; ValueType: string; ValueName: "Icon"; ValueData: "shell32.dll,50"

; Untermenü-Container; beim Uninstall mit entfernen
Root: HKCR; Subkey: "*\shell\Sleep\shell"; Flags: uninsdeletekey

; --- Einträge ---
Root: HKCR; Subkey: "*\shell\Sleep\shell\1h";                ValueType: string; ValueName: ""; ValueData: "1 Stunde"
Root: HKCR; Subkey: "*\shell\Sleep\shell\1h\command";         ValueType: string; ValueName: ""; ValueData: """{app}\Sleep.exe"" ""%1"" 1h"

Root: HKCR; Subkey: "*\shell\Sleep\shell\2h";                ValueType: string; ValueName: ""; ValueData: "2 Stunden"
Root: HKCR; Subkey: "*\shell\Sleep\shell\2h\command";         ValueType: string; ValueName: ""; ValueData: """{app}\Sleep.exe"" ""%1"" 2h"

Root: HKCR; Subkey: "*\shell\Sleep\shell\4h";                ValueType: string; ValueName: ""; ValueData: "4 Stunden"
Root: HKCR; Subkey: "*\shell\Sleep\shell\4h\command";         ValueType: string; ValueName: ""; ValueData: """{app}\Sleep.exe"" ""%1"" 4h"

Root: HKCR; Subkey: "*\shell\Sleep\shell\morgen";            ValueType: string; ValueName: ""; ValueData: "Bis morgen früh"
Root: HKCR; Subkey: "*\shell\Sleep\shell\morgen\command";     ValueType: string; ValueName: ""; ValueData: """{app}\Sleep.exe"" ""%1"" morgen"

Root: HKCR; Subkey: "*\shell\Sleep\shell\wochenende";        ValueType: string; ValueName: ""; ValueData: "Am Wochenende"
Root: HKCR; Subkey: "*\shell\Sleep\shell\wochenende\command"; ValueType: string; ValueName: ""; ValueData: """{app}\Sleep.exe"" ""%1"" wochenende"

Root: HKCR; Subkey: "*\shell\Sleep\shell\z_individuell";     ValueType: string; ValueName: ""; ValueData: "Individuell ..."
Root: HKCR; Subkey: "*\shell\Sleep\shell\z_individuell\command"; ValueType: string; ValueName: ""; ValueData: """{app}\Sleep.exe"" ""%1"" z_individuell"

; --- Zweiter Eintrag mit Icon/Shield (optional) ---
Root: HKCR; Subkey: "*\shell\SleepIndividuell";                      ValueType: string; ValueData: "Schlafen …"
Root: HKCR; Subkey: "*\shell\SleepIndividuell"; ValueName: "HasLUAShield"; ValueType: string; ValueData: ""
Root: HKCR; Subkey: "*\shell\SleepIndividuell"; ValueName: "Icon";        ValueType: string; ValueData: """{app}\Sleep.ico"""
Root: HKCR; Subkey: "*\shell\SleepIndividuell"; ValueName: "Position";    ValueType: string; ValueData: "Top"
Root: HKCR; Subkey: "*\shell\SleepIndividuell\command";                    ValueType: string; ValueData: """{app}\Sleep.exe"" ""%1"" z_individuell"

[Tasks]
Name: "autostart"; Description: "Sleep automatisch beim Windows-Start starten"; GroupDescription: "Optionale Einstellungen:"; Flags: unchecked

[Run]
Filename: "{app}\WakeHidden.exe"; Description: "Sleep jetzt starten"; Flags: nowait postinstall skipifsilent
Filename: "{app}\changelog.txt"; Description: "Changelog anzeigen"; Flags: postinstall shellexec skipifsilent

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if WizardIsTaskSelected('autostart') then
    begin
      RegWriteStringValue(HKEY_CURRENT_USER,
        'Software\Microsoft\Windows\CurrentVersion\Run',
        'SleepTray',
        ExpandConstant('"{app}\WakeHidden.exe"'));
    end;
  end;
end;