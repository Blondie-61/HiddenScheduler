; === SleepSetup_v1.1.0.iss ===

[Setup]
AppName=Sleep Tool
AppVersion=1.1.1 (Build 71)
AppPublisher=BlondieSoft
DefaultDirName=C:\Tools\Sleep
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\Sleep.exe
OutputDir=.\Output
OutputBaseFilename=SleepSetup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=admin
VersionInfoVersion=1.1.1
VersionInfoTextVersion=1.1.1
VersionInfoProductVersion=1.1.1

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

[Icons]
Name: "{autoprograms}\Sleep Tool"; Filename: "{app}\Sleep.exe"

[Registry]
; Kontextmenü "Schlafen ..."
Root: HKCR; Subkey: "*\shell\Schlafen"; ValueType: string; ValueName: "MUIVerb"; ValueData: "Schlafen ..."
Root: HKCR; Subkey: "*\shell\Schlafen"; ValueType: string; ValueName: "SubCommands"; ValueData: ""
Root: HKCR; Subkey: "*\shell\Schlafen"; ValueType: string; ValueName: "Icon"; ValueData: "shell32.dll,50"
Root: HKCR; Subkey: "*\shell\Schlafen\shell"; Flags: uninsdeletekey

Root: HKCR; Subkey: "*\shell\Schlafen\shell\1h"; ValueType: string; ValueName: ""; ValueData: "1 Stunde"
Root: HKCR; Subkey: "*\shell\Schlafen\shell\1h\command"; ValueType: string; ValueName: ""; ValueData: """{app}\Sleep.exe"" ""%1"" 1h"

Root: HKCR; Subkey: "*\shell\Schlafen\shell\2h"; ValueType: string; ValueName: ""; ValueData: "2 Stunden"
Root: HKCR; Subkey: "*\shell\Schlafen\shell\2h\command"; ValueType: string; ValueName: ""; ValueData: """{app}\Sleep.exe"" ""%1"" 2h"

Root: HKCR; Subkey: "*\shell\Schlafen\shell\4h"; ValueType: string; ValueName: ""; ValueData: "4 Stunden"
Root: HKCR; Subkey: "*\shell\Schlafen\shell\4h\command"; ValueType: string; ValueName: ""; ValueData: """{app}\Sleep.exe"" ""%1"" 4h"

Root: HKCR; Subkey: "*\shell\Schlafen\shell\morgen"; ValueType: string; ValueName: ""; ValueData: "Bis morgen früh"
Root: HKCR; Subkey: "*\shell\Schlafen\shell\morgen\command"; ValueType: string; ValueName: ""; ValueData: """{app}\Sleep.exe"" ""%1"" morgen"

Root: HKCR; Subkey: "*\shell\Schlafen\shell\wochenende"; ValueType: string; ValueName: ""; ValueData: "Am Wochenende"
Root: HKCR; Subkey: "*\shell\Schlafen\shell\wochenende\command"; ValueType: string; ValueName: ""; ValueData: """{app}\Sleep.exe"" ""%1"" wochenende"

Root: HKCR; Subkey: "*\shell\Schlafen\shell\z_individuell"; ValueType: string; ValueName: ""; ValueData: "Individuell ..."
Root: HKCR; Subkey: "*\shell\Schlafen\shell\z_individuell\command"; ValueType: string; ValueName: ""; ValueData: """{app}\Sleep.exe"" ""%1"" z_individuell"

; Zweiter Eintrag mit Icon und Shield
Root: HKCR; Subkey: "*\shell\SleepIndividuell"; ValueType: string; ValueData: "Schlafen …"
Root: HKCR; Subkey: "*\shell\SleepIndividuell"; ValueName: "HasLUAShield"; ValueType: string; ValueData: ""
Root: HKCR; Subkey: "*\shell\SleepIndividuell"; ValueName: "Icon"; ValueType: string; ValueData: """{app}\Sleep.ico"""
Root: HKCR; Subkey: "*\shell\SleepIndividuell"; ValueName: "Position"; ValueType: string; ValueData: "Top"
Root: HKCR; Subkey: "*\shell\SleepIndividuell\command"; ValueType: string; ValueData: """{app}\Sleep.exe"" ""%1"" z_individuell"

[Tasks]
Name: "autostart"; Description: "Sleep automatisch beim Windows-Start starten"; GroupDescription: "Optionale Einstellungen:"; Flags: unchecked

[Run]
Filename: "{app}\WakeHidden.exe"; Description: "Sleep jetzt starten"; Flags: nowait postinstall skipifsilent

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