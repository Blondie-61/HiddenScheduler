﻿unit WakeHiddenU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, WinAPI.ShellAPI,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, System.ImageList, Vcl.ImgList, System.Actions, Vcl.ActnList, Vcl.Menus,
  System.IOUtils, System.JSON, System.DateUtils, System.IniFiles, MMSystem, Winapi.CommCtrl, StrUtils, Registry,
  System.Types, VirtualTrees.Types;
type
  TTrayIconState = (tisDefault, tisBlue, tisRed);

type
  TFormWake = class(TForm)
    Timer1: TTimer;
    PopupMenu1: TPopupMenu;
    Jetztprfen1: TMenuItem;
    Jetztprfen2: TMenuItem;
    Beenden1: TMenuItem;
    ActionList1: TActionList;
    actCheckNow: TAction;
    actWakeAll: TAction;
    actExit: TAction;
    ImageListWithBadge: TImageList;
    TrayIcon1: TTrayIcon;
    actShwFileShw: TAction;
    ZeigeDateien1: TMenuItem;
    N1: TMenuItem;
    Scannenaus1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    mnuSelectSound: TMenuItem;
    mnuPlaySound: TMenuItem;
    mnuSnoozeEnabled: TMenuItem;
    N4: TMenuItem;
    mnuSnooze5: TMenuItem;
    mnuSnooze15: TMenuItem;
    mnuSnooze60: TMenuItem;
    SchlummernDialog1: TMenuItem;
    Taskleistensymbol1: TMenuItem;
    chkAutostart: TMenuItem;

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    procedure actCheckNowExecute(Sender: TObject);
    procedure actWakeAllExecute(Sender: TObject);
    procedure actExitExecute(Sender: TObject);
    procedure actShwFileShwExecute(Sender: TObject);
    procedure chkAutostartClick(Sender: TObject);

    procedure mnuSelectSoundClick(Sender: TObject);
    procedure mnuSnooze15Click(Sender: TObject);
    procedure mnuSnooze5Click(Sender: TObject);
    procedure mnuSnooze60Click(Sender: TObject);
    procedure nachneuerVersionsuchen1Click(Sender: TObject);
    procedure Scannenaus1Click(Sender: TObject);
    procedure Taskleistensymbol1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure TrayIcon1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    procedure SetAppIconFromFile(const icoPath: string);
    { Private-Deklarationen }
  public
    procedure ShowBlueBadgeIcon(durationSecs: Integer = 60);
    procedure ShowRedBadgeIcon(durationSecs: Integer = 60);
    procedure LoadDefaultIcon;
    { Public-Deklarationen }
  protected
  end;

var
  FormWake: TFormWake;
  WakeupSoundFile: string = '';
  SnoozeActive: Boolean = False;
  SnoozeEndTime: TDateTime;
  LastWokenFile: string = '';
  BadgeSessionID: Integer = 0;
  CurrentTrayState: TTrayIconState = tisDefault;
  iNumberOfFiles: Integer = 0;
  ENABLE_LOGGING: Boolean = False;

function TaskbarIconEnabled: Boolean;
function GetAppDataPath: string;
function GetJsonFilePath: string;
procedure Log(const msg: string);
procedure UpdateSnoozeMenuItems(visible: Boolean);
function UpdateTrayIconStatus: Integer;
function GetInfoText(Count: Integer = 0): string;
procedure DoSnooze(minutes: Integer);
procedure LoadSettings;
procedure SaveSettings;

implementation

{$R *.dfm}
{$R WakeHidden.res}

uses ShwFilesU, FormToastU, UpdateChecker;

function TaskbarIconEnabled: Boolean;
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(TPath.Combine(GetAppDataPath, 'settings.ini'));
  try
    Result := ini.ReadBool('Options', 'ShowInTaskbar', True); // Default: aktiv
  finally
    ini.Free;
  end;
end;

function CreateTrayIconWithBadgeNumber(const icoPath: string; number: Integer): HICON;
var
  icon: TIcon;
  bmp: TBitmap;
  hbmColor, hbmMask: HBITMAP;
  iconInfo: TIconInfo;
  canvasRect: TRect;
  s: string;
begin
  Result := 0;
  if not FileExists(icoPath) then Exit;

  icon := TIcon.Create;
  bmp := TBitmap.Create;
  try
    icon.LoadFromFile(icoPath);

    bmp.Width := icon.Width;
    bmp.Height := icon.Height;
    bmp.PixelFormat := pf32bit;

    // Icon in Bitmap zeichnen
    bmp.Canvas.Draw(0, 0, icon);

    // Badge-Zahl hinzufügen
    with bmp.Canvas do
    begin
      Font.Name := 'Segoe UI';
      Font.Size := 9;
      Font.Style := [fsBold];
      Font.Color := clWhite;
      Brush.Style := bsSolid;
      Brush.Color := RGB(10, 100, 240);

      canvasRect := Rect(bmp.Width - 18, bmp.Height - 18, bmp.Width - 2, bmp.Height - 2);
      Ellipse(canvasRect);

      Brush.Style := bsClear;
      TextOut(canvasRect.Left + 3, canvasRect.Top + 2, number.ToString);
    end;

    // In echtes HICON umwandeln
    hbmColor := bmp.Handle;
    hbmMask := CreateBitmap(bmp.Width, bmp.Height, 1, 1, nil); // einfache leere Maske

    ZeroMemory(@iconInfo, SizeOf(iconInfo));
    iconInfo.fIcon := True;
    iconInfo.hbmColor := hbmColor;
    iconInfo.hbmMask := hbmMask;

    Result := CreateIconIndirect(iconInfo);

    DeleteObject(hbmMask); // aufräumen!

  finally
    icon.Free;
    bmp.Free;
  end;
end;

function GetAppDataPath: string;
begin
  Result := TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'HiddenScheduler');
  ForceDirectories(Result);
end;

function GetJsonFilePath: string;
begin
  Result := TPath.Combine(GetAppDataPath, 'hidden_files.json');
end;

procedure Log(const msg: string);
var
  logFile: string;
  retryCount: Integer;
begin
  if ENABLE_LOGGING then
  begin
    logFile := TPath.Combine(GetEnvironmentVariable('TEMP'), 'HideFile.log');
    retryCount := 0;

    while retryCount < 10 do
    begin
      try
        TFile.AppendAllText(logFile,
          Format('[%s] %s%s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), msg, sLineBreak]),
          TEncoding.UTF8);
        Exit; // nur bei Erfolg
      except
        on E: Exception do
        begin
          Inc(retryCount);
          Sleep(100);
        end;
      end;
    end;
  end;
end;

procedure SetJsonValue(obj: TJSONObject; const key, value: string);
begin
  if obj.GetValue(key) <> nil then
    obj.RemovePair(key);
  obj.AddPair(key, value);
end;

function IsHidden(const path: string): Boolean;
begin
  Result := (GetFileAttributes(PChar(path)) and FILE_ATTRIBUTE_HIDDEN) <> 0;
end;

procedure PlayWakeupSound;
begin
  if FormWake.mnuPlaySound.Checked and FileExists(WakeupSoundFile) then
    PlaySound(PChar(WakeupSoundFile), 0, SND_FILENAME or SND_ASYNC);
end;

procedure SetTrayIconFromImageList(index: Integer);
var
  ico: TIcon;
begin
  ico := TIcon.Create;
  try
    case index of
      1: CurrentTrayState := (tisBlue);
      2: CurrentTrayState := (tisRed);
      else CurrentTrayState := (tisDefault);
    end;

    FormWake.ImageListWithBadge.GetIcon(index, ico);
    FormWake.TrayIcon1.Icon := ico;
//    FormWake.TrayIcon1.Visible := False;
//    FormWake.TrayIcon1.Visible := True;
  finally
    ico.Free;
  end;
end;

procedure UpdateSnoozeMenuItems(visible: Boolean);
begin
  Log('🛠 Menüeinträge Snooze sichtbar: ' + BoolToStr(visible, True));
  FormWake.mnuSnooze5.Visible := visible;
  FormWake.mnuSnooze15.Visible := visible;
  FormWake.mnuSnooze60.Visible := visible;
end;

procedure UpdateJsonEntry(const filePath: string; const newHide, newWake: TDateTime; const newStatus: string);
var
  jsonFile, jsonStr: string;
  jsonArr: TJSONArray;
  jsonObj: TJSONObject;
  i: Integer;
begin
  jsonFile := GetJsonFilePath;
  if not TFile.Exists(jsonFile) then Exit;

  jsonStr := TFile.ReadAllText(jsonFile);
  jsonArr := TJSONObject.ParseJSONValue(jsonStr) as TJSONArray;
  if not Assigned(jsonArr) then Exit;

  for i := 0 to jsonArr.Count - 1 do
  begin
    jsonObj := jsonArr.Items[i] as TJSONObject;
    if jsonObj.GetValue<string>('path') = filePath then
    begin
      jsonObj.RemovePair('hideTime');
      jsonObj.RemovePair('wakeTime');
      jsonObj.RemovePair('status');

      jsonObj.AddPair('hideTime', DateToISO8601(newHide, True));
      jsonObj.AddPair('wakeTime', DateToISO8601(newWake, True));
      jsonObj.AddPair('status', newStatus);
      Break;
    end;
  end;

  TFile.WriteAllText(jsonFile, jsonArr.ToJSON);
  jsonArr.Free;
end;

function UpdateTrayIconStatus: Integer;
var
  jsonFile, jsonStr: string;
  jsonArr: TJSONArray;
  jsonObj: TJSONObject;
  i: Integer;
  filePath: string;
  fileAttr: DWORD;
  hasHidden: Boolean;
begin
  // ❗ Rot hat Priorität – wenn aktiv, NICHT ändern
  Result := 0;
  if CurrentTrayState = tisRed then Exit;

  hasHidden := False;
  jsonFile := GetJsonFilePath;
  if not FileExists(jsonFile) then Exit;

  jsonStr := TFile.ReadAllText(jsonFile);
  jsonArr := TJSONObject.ParseJSONValue(jsonStr) as TJSONArray;
  if not Assigned(jsonArr) or ((jsonArr.Count) = 0) then
  begin
   FormWake.LoadDefaultIcon;
   Exit;
  end;

  Result := jsonArr.Count;
  try
    for i := 0 to jsonArr.Count - 1 do
    begin
      jsonObj := jsonArr.Items[i] as TJSONObject;
      filePath := jsonObj.GetValue<string>('path');
      if not FileExists(filePath) then Continue;

      fileAttr := GetFileAttributes(PChar(filePath));
      if (fileAttr and FILE_ATTRIBUTE_HIDDEN) <> 0 then
      begin
        hasHidden := True;
        Break;
      end;
    end;
  finally
    jsonArr.Free;
  end;

  //if hasHidden and (CurrentTrayState <> tisBlue) then
  if hasHidden then
  begin
    iNumberOfFiles := Result;
    FormWake.ShowBlueBadgeIcon;
  end
  else
  if not hasHidden and (CurrentTrayState <> tisDefault) then
    FormWake.LoadDefaultIcon
end;

function GetInfoText(Count: Integer = 0): string;
begin
  if (Count = 0) then
    Result := 'Alle Dateien sind wach.'
  else
  if (Count = 1) then
    Result := Count.ToString + ' Datei schläft.'
  else
  if (Count > 1) then
    Result := Count.ToString + ' Dateien schlafen.';
end;

procedure DoSnooze(minutes: Integer);
var
  filePath, jsonFile: string;
  jsonArr: TJSONArray;
  jsonObj: TJSONObject;
  wakeTime: TDateTime;
begin
  if SnoozeActive then
  begin
    Log('⚠ Snooze bereits aktiv – erneuter Start abgebrochen');
    Exit;
  end;

  Inc(BadgeSessionID); // damit alte Threads enden
  SnoozeActive := False;

  Inc(iNumberOfFiles);
  FormWake.ShowBlueBadgeIcon;
  UpdateTrayIconStatus;
  UpdateSnoozeMenuItems(False);

  if LastWokenFile = '' then
  begin
    Log('⚠️ Snooze abgebrochen – keine geweckte Datei vorhanden');
    Exit;
  end;

  filePath := LastWokenFile;
  //wakeTime := Now + EncodeTime(0, minutes, 0, 0);
  wakeTime := IncMinute(Now, minutes);
  // Datei erneut verstecken
  if FileExists(filePath) then
  begin
    var attrs := GetFileAttributes(PChar(filePath));
    if (attrs and FILE_ATTRIBUTE_HIDDEN) = 0 then
    begin
      SetFileAttributes(PChar(filePath), attrs or FILE_ATTRIBUTE_HIDDEN);
      Log('😴 Datei erneut versteckt (Snooze): ' + filePath);
    end;
  end;

  // Eintrag in JSON neu anlegen
  jsonFile := GetJsonFilePath;
  if TFile.Exists(jsonFile) then
    jsonArr := TJSONObject.ParseJSONValue(TFile.ReadAllText(jsonFile)) as TJSONArray
  else
    jsonArr := TJSONArray.Create;

  if not Assigned(jsonArr) then
  begin
    jsonArr := TJSONArray.Create;
    Log('⚠️ Fehler beim Parsen der JSON – neue Liste angelegt (Snooze)');
  end;

  jsonObj := TJSONObject.Create;
  jsonObj.AddPair('path', filePath);
  jsonObj.AddPair('hideTime', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now));
  jsonObj.AddPair('wakeTime', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', wakeTime));
  jsonArr.AddElement(jsonObj);

  TFile.WriteAllText(jsonFile, jsonArr.ToJSON);
  Log(Format('🔁 Schlummern: %s für %d Minuten', [filePath, minutes]));

  jsonArr.Free;
  if (ShwFiles.Visible) then
    ShwFiles.actReFreshExecute(nil);

  if (FormToastF.Visible) then
  begin
    FormToastF.StartFadeOut;
    FormToastF.Close;
  end;

  // 🆕 Neue Snooze-Badge starten
//  FormWake.ShowBadgeIcon;
end;

function CheckAndWakeFiles: Integer;
var
  jsonFile, jsonStr, filePath, wakeTimeStr, hideTimeStr: string;
  jsonArr, newList: TJSONArray;
  jsonObj: TJSONObject;
  wakeTime, hideTime: TDateTime;
  i: Integer;
  processedPaths: TStringList;
  fileAttr: DWORD;
begin
  Result := 0;
  jsonFile := GetJsonFilePath;
  if not TFile.Exists(jsonFile) then Exit;

  try
    jsonStr := TFile.ReadAllText(jsonFile);
    jsonArr := TJSONObject.ParseJSONValue(jsonStr) as TJSONArray;
    if not Assigned(jsonArr) then Exit;

    newList := TJSONArray.Create;
    processedPaths := TStringList.Create;
    processedPaths.CaseSensitive := False;
    processedPaths.Sorted := True;

    Result := jsonArr.Count;
    iNumberOfFiles := Result;

    for i := 0 to jsonArr.Count - 1 do
    begin
      jsonObj := jsonArr.Items[i] as TJSONObject;
      filePath := jsonObj.GetValue('path').Value;
      fileAttr := GetFileAttributes(PChar(filePath));

      if processedPaths.IndexOf(filePath) >= 0 then
      begin
        Log('⚠️ Doppelter Eintrag ignoriert: ' + filePath);
        Continue;
      end;
      processedPaths.Add(filePath);

      // === WakeTime prüfen ===
      if jsonObj.TryGetValue('wakeTime', wakeTimeStr) then
      begin
        try
          wakeTime := ISO8601ToDate(wakeTimeStr, True);
        except
          Log('⚠️ Fehler beim Parsen von wakeTime: ' + wakeTimeStr);
          Continue;
        end;

        // HideTime (optional, rein informativ)
        if jsonObj.TryGetValue('hideTime', hideTimeStr) then
        begin
          try
            hideTime := ISO8601ToDate(hideTimeStr, True);
          except
            hideTime := 0;
          end;
        end;

        if Now >= wakeTime then
        begin
          if FileExists(filePath) then
          begin
            if (fileAttr and FILE_ATTRIBUTE_HIDDEN) <> 0 then
            begin
              SetFileAttributes(PChar(filePath), fileAttr and not FILE_ATTRIBUTE_HIDDEN);
              Log('🌞 Datei geweckt: ' + filePath);
              LastWokenFile := filePath;

              if FormWake.mnuPlaySound.Checked then
                PlayWakeupSound;

              if (FormWake.mnuSnoozeEnabled.Checked) then
              begin
                var aFn := ExtractFileName(filePath);
                if (Length(aFn) > 30) then
                  aFn := LeftStr(aFn, 30) + ' ...';

                if FormWake.SchlummernDialog1.Checked then
                  FormToastF.ShowToast('Die Datei '+ aFn + ' ist aufgewacht.', 'Snooze verfügbar für 60 Sekunden');

                Dec(iNumberOfFiles);
                UpdateSnoozeMenuItems(True);
                FormWake.ShowRedBadgeIcon(60);
              end;
            end
            else
              Log('🔍 WakeTime erreicht, aber Datei war nicht versteckt: ' + filePath);
          end
          else
            Log('❌ Datei bei WakeTime nicht gefunden: ' + filePath);

          Log('🧹 Datei aus Liste entfernt (WakeTime erreicht): ' + filePath);
          Continue;
        end;
      end;

      // === Standardübernahme ===
      newList.AddElement(jsonObj.Clone as TJSONValue);
    end;

    TFile.WriteAllText(jsonFile, newList.ToJSON);

    processedPaths.Free;
    jsonArr.Free;
    newList.Free;
  except
    on E: Exception do
      Log('💥 Fehler beim Verarbeiten von hidden_files.json: ' + E.Message);
  end;
end;

procedure WakeAllFiles;
var
  jsonFile, jsonStr, filePath: string;
  jsonArr, newList: TJSONArray;
  jsonObj: TJSONObject;
  fileAttr: DWORD;
  i: Integer;
begin
  jsonFile := GetJsonFilePath;
  if not TFile.Exists(jsonFile) then Exit;

  try
    jsonStr := TFile.ReadAllText(jsonFile);
    jsonArr := TJSONObject.ParseJSONValue(jsonStr) as TJSONArray;
    if not Assigned(jsonArr) then Exit;

    newList := TJSONArray.Create;

    for i := 0 to jsonArr.Count - 1 do
    begin
      jsonObj := jsonArr.Items[i] as TJSONObject;
      filePath := jsonObj.GetValue('path').Value;
      fileAttr := GetFileAttributes(PChar(filePath));

      if TFile.Exists(filePath) then
      begin
        if (fileAttr and FILE_ATTRIBUTE_HIDDEN) <> 0 then
        begin
          PlayWakeupSound;
          SetFileAttributes(PChar(filePath), fileAttr and not FILE_ATTRIBUTE_HIDDEN);
          Log('🌞 Manuell aufgeweckt: ' + filePath);
        end
        else
        begin
          Log('📂 Datei war schon sichtbar: ' + filePath);
        end;

        // Status setzen (optional)
        //jsonObj.RemovePair('status');
        //jsonObj.AddPair('status', 'awake');

        // Entscheidung: wieder beobachten oder nicht?
        // Falls du sie vollständig löschen willst, Kommentar unten entfernen:
        Continue;

        newList.AddElement(jsonObj.Clone as TJSONValue);
      end
      else
      begin
        Log('❌ Datei nicht gefunden: ' + filePath);
        // nicht übernehmen
      end;
    end;

    TFile.WriteAllText(jsonFile, newList.ToJSON);

    jsonArr.Free;
    newList.Free;
  except
    on E: Exception do
      Log('💥 Fehler bei WakeAllFiles: ' + E.Message);
  end;
  FormWake.LoadDefaultIcon;
  ShwFiles.actReFreshExecute(nil);
end;

procedure UpdateAutoStart(enable: Boolean);
const
  RegPath = 'Software\Microsoft\Windows\CurrentVersion\Run';
var
  reg: TRegistry;
begin
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if reg.OpenKey(RegPath, True) then
    begin
      if enable then
        reg.WriteString('HiddenScheduler', Application.ExeName)
      else
        reg.DeleteValue('HiddenScheduler');
    end;
  finally
    reg.Free;
  end;
end;

procedure LoadSettings;
var
  ini: TIniFile;
  autoStartRegSet: Boolean;
begin
  ini := TIniFile.Create(TPath.Combine(GetAppDataPath, 'settings.ini'));
  try
    ENABLE_LOGGING := ini.ReadBool('Options', 'Logging', False);
    FormWake.Timer1.Interval := ini.ReadInteger('Timer', 'Intervall', 15000);
    WakeupSoundFile := ini.ReadString('Sound', 'WakeupSoundFile', '');
    FormWake.mnuPlaySound.Checked := ini.ReadBool('Sound', 'PlayOnWake', False);
    FormWake.Scannenaus1.Checked := ini.ReadBool('Options', 'ScanOff', False);
    FormWake.mnuSnoozeEnabled.Checked := ini.ReadBool('Options', 'EnableSnooze', False);
    FormWake.SchlummernDialog1.Checked := ini.ReadBool('Options', 'SnoozeDialog', True);
    FormWake.Taskleistensymbol1.Checked := ini.ReadBool('Options', 'ShowInTaskbar', True);

    // Autostart aus Registry lesen
    var reg := TRegistry.Create(KEY_READ);
    try
      reg.RootKey := HKEY_CURRENT_USER;
      autoStartRegSet := reg.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Run') and reg.ValueExists('SleepTray');
    finally
      reg.Free;
    end;

    // INI ggf. aktualisieren
    ini.WriteBool('Options', 'AutoStart', autoStartRegSet);
    FormWake.chkAutostart.Checked := autoStartRegSet;

    ShwFiles.Left   := ini.ReadInteger('Window', 'ShwFiles.Left'  , ShwFiles.Left);
    ShwFiles.Top    := ini.ReadInteger('Window', 'ShwFiles.Top'   , ShwFiles.Top);
    ShwFiles.Width  := ini.ReadInteger('Window', 'ShwFiles.Width' , ShwFiles.Width);
    ShwFiles.Height := ini.ReadInteger('Window', 'ShwFiles.Height', ShwFiles.Height);

    for var i := 0 to ShwFiles.VST.Header.Columns.Count - 1 do
      ShwFiles.VST.Header.Columns[i].Width := ini.ReadInteger('Columns', Format('Col%d.Width', [i]), ShwFiles.VST.Header.Columns[i].Width);

    ShwFiles.VST.Header.SortColumn := ini.ReadInteger('Columns', 'SortColumn', 1);
    ShwFiles.VST.Header.SortDirection := TSortDirection(ini.ReadInteger('Columns', 'SortDirection', Ord(sdAscending)));

    ShwFiles.VST.SortTree(
      ShwFiles.VST.Header.SortColumn,
      ShwFiles.VST.Header.SortDirection,
      True
    );

  finally
    ini.Free;
  end;

  FormWake.Timer1.Enabled := not (FormWake.Scannenaus1.Checked);

  if (FileExists(WakeupSoundFile)) then
    FormWake.mnuPlaySound.Caption := 'Sound beim Aufwecken: ' + ExtractFileName(WakeupSoundFile)
  else
    FormWake.mnuPlaySound.Caption := 'Sound beim Aufwecken';
end;

procedure SaveSettings;
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(TPath.Combine(GetAppDataPath, 'settings.ini'));
  try
    ini.WriteBool('Options', 'Logging', ENABLE_LOGGING);
    ini.WriteInteger('Timer', 'Intervall', FormWake.Timer1.Interval);
    ini.WriteBool('Sound', 'PlayOnWake', FormWake.mnuPlaySound.Checked);
    ini.WriteString('Sound', 'WakeupSoundFile', WakeupSoundFile);
    ini.WriteBool('Options', 'ScanOff', FormWake.Scannenaus1.Checked);
    ini.WriteBool('Options', 'EnableSnooze', FormWake.mnuSnoozeEnabled.Checked);
    ini.WriteBool('Options', 'SnoozeDialog', FormWake.SchlummernDialog1.Checked);
    ini.WriteBool('Options', 'AutoStart', FormWake.chkAutostart.Checked);

    ini.WriteInteger('Window', 'ShwFiles.Left'  , ShwFiles.Left);
    ini.WriteInteger('Window', 'ShwFiles.Top'   , ShwFiles.Top);
    ini.WriteInteger('Window', 'ShwFiles.Width' , ShwFiles.Width);
    ini.WriteInteger('Window', 'ShwFiles.Height', ShwFiles.Height);

    for var i := 0 to ShwFiles.VST.Header.Columns.Count - 1 do
     ini.WriteInteger('Columns', Format('Col%d.Width', [i]), ShwFiles.VST.Header.Columns[i].Width);

    ini.WriteInteger('Columns', 'SortColumn', ShwFiles.VST.Header.SortColumn);
    ini.WriteInteger('Columns', 'SortDirection', Ord(ShwFiles.VST.Header.SortDirection));

  finally
    ini.Free;
  end;
end;

procedure TFormWake.FormCreate(Sender: TObject);
begin
  UpdateTrayIconStatus;

  TrayIcon1.Icon.Assign(Application.Icon);
  TrayIcon1.PopupMenu := PopupMenu1;
  TrayIcon1.Visible := True;
  LoadSettings;
  Timer1.Enabled := True;

  Visible := False;
  Log('🏷 ExStyle: ' + IntToHex(GetWindowLong(Handle, GWL_EXSTYLE), 8));
end;

procedure TFormWake.FormShow(Sender: TObject);
begin
  LoadSettings;
end;

procedure TFormWake.FormDestroy(Sender: TObject);
begin
  TrayIcon1.Visible := False;
end;

procedure TFormWake.Timer1Timer(Sender: TObject);
begin
  UpdateTrayIconStatus;
  UpdateSnoozeMenuItems(False);

  CheckAndWakeFiles;

  if (ShwFiles.Visible) then
    ShwFiles.actReFresh.Execute;
end;

procedure TFormWake.mnuSelectSoundClick(Sender: TObject);
var
  dlg: TOpenDialog;
begin
  dlg := TOpenDialog.Create(Self);
  try
    dlg.Filter := 'WAV-Dateien (*.wav)|*.wav';
    if dlg.Execute then
    begin
      WakeupSoundFile := dlg.FileName;
      Log('🔔 Sounddatei ausgewählt: ' + WakeupSoundFile);
      SaveSettings; // gleich mit speichern
      LoadSettings;
    end;
  finally
    dlg.Free;
  end;
end;

procedure TFormWake.actCheckNowExecute(Sender: TObject);
begin
  Timer1.Enabled := False;
  CheckAndWakeFiles;
    if (ShwFiles.Visible) then
      ShwFiles.actReFresh.Execute;
  Timer1.Enabled := True;
end;

procedure TFormWake.actWakeAllExecute(Sender: TObject);
begin
  WakeAllFiles;
  iNumberOfFiles := 0;
end;

procedure TFormWake.actExitExecute(Sender: TObject);
begin
  SaveSettings;
  Application.Terminate;
end;

procedure TFormWake.actShwFileShwExecute(Sender: TObject);
begin
  ShwFiles.WindowState := wsNormal;
  ShwFiles.Show;
end;

procedure TFormWake.chkAutostartClick(Sender: TObject);
begin
  UpdateAutoStart(chkAutostart.Checked);
end;

procedure TFormWake.LoadDefaultIcon;
begin
  SetTrayIconFromImageList(0);

  // Dynamisches App-Icon festlegen (aus C:\Tools\Sleep\app_badge_X.ico)
  var iconName := 'IconWithBlueBadge0.ico';
  var appIconPath := 'C:\Tools\Sleep\' + iconName;
  SetAppIconFromFile(appIconPath);

//  TrayIcon1.Visible := False; // Refresh
//  TrayIcon1.Visible := True;
  TrayIcon1.Hint := 'Alles wach!';
  UpdateSnoozeMenuItems(False);
end;

procedure TFormWake.SetAppIconFromFile(const icoPath: string);
var
  icon: TIcon;
begin
  if not FileExists(icoPath) then Exit;

  icon := TIcon.Create;
  try
    icon.LoadFromFile(icoPath);
    Application.Icon := icon; // Taskleisten-Icon wird aktualisiert
  finally
    icon.Free;
  end;
end;

procedure TFormWake.ShowBlueBadgeIcon(durationSecs: Integer = 60);
var
  iconName, appIconPath: string;
begin
  SetTrayIconFromImageList(1);

  TrayIcon1.Hint := GetInfoText(iNumberOfFiles);

  // Dynamisches App-Icon festlegen (aus C:\Tools\Sleep\app_badge_X.ico)
  if iNumberOfFiles > 9 then
    iconName := 'IconWithBlueBadge9+.ico'
  else
    iconName := Format('IconWithBlueBadge%d.ico', [iNumberOfFiles]);

  appIconPath := 'C:\Tools\Sleep\' + iconName;
  SetAppIconFromFile(appIconPath);
end;

procedure TFormWake.ShowRedBadgeIcon(durationSecs: Integer = 60);
var
  thisSession: Integer;
begin
  Inc(BadgeSessionID); // Neue Session-ID, alte Threads werden ignoriert
  thisSession := BadgeSessionID;
  Log('🆕 Neue Badge-Session: ' + thisSession.ToString);

//  SnoozeActive := True;
  SetTrayIconFromImageList(2); // Badge laden
  TrayIcon1.Hint := 'Snooze-Option aktiv';

  // Dynamisches App-Icon festlegen (aus C:\Tools\Sleep\app_badge_X.ico)
  var iconName := 'IconWithRedBadge.ico';
  var appIconPath := 'C:\Tools\Sleep\' + iconName;
  SetAppIconFromFile(appIconPath);

//  TrayIcon1.Visible := False;
//  TrayIcon1.Visible := True;

  UpdateSnoozeMenuItems(True);

  FormWake.Timer1.Enabled := False;

  TThread.CreateAnonymousThread(procedure
  begin
    Sleep(durationSecs * 1000);
    TThread.Synchronize(nil, procedure
    begin
      if thisSession = BadgeSessionID then
      begin
        Log('⏱ Snooze-Badge läuft ab – Standardicon wiederherstellen');
        FormWake.ShowBlueBadgeIcon;
        UpdateTrayIconStatus;
        UpdateSnoozeMenuItems(False);
        FormWake.Timer1.Enabled := True;
      end
      else
        Log('⏩ Snooze-Badge vorzeitig ersetzt – Icon bleibt bestehen');
        UpdateSnoozeMenuItems(False);
        FormWake.Timer1.Enabled := True;
    end);
  end).Start;
end;

procedure TFormWake.mnuSnooze5Click(Sender: TObject);
begin
  Log('🔁 Schlummern: ' + LastWokenFile + ' für 5 Minuten');
  DoSnooze(5); // Neue WakeTime setzen etc.
  ShowBlueBadgeIcon(60);
end;

procedure TFormWake.mnuSnooze15Click(Sender: TObject);
begin
  Log('🔁 Schlummern: ' + LastWokenFile + ' für 5 Minuten');
  DoSnooze(15); // Neue WakeTime setzen etc.
  ShowBlueBadgeIcon(60);          // Neuer Badge → alte Session wird automatisch ersetzt
end;

procedure TFormWake.mnuSnooze60Click(Sender: TObject);
begin
  Log('🔁 Schlummern: ' + LastWokenFile + ' für 5 Minuten');
  DoSnooze(60); // Neue WakeTime setzen etc.
  ShowBlueBadgeIcon(60);          // Neuer Badge → alte Session wird automatisch ersetzt
end;

procedure TFormWake.nachneuerVersionsuchen1Click(Sender: TObject);
var
  currentVersion: string;
  updateInfo: TUpdateInfo;
begin
  currentVersion := GetAppVersion; // z. B. '1.1.0'

  if CheckForUpdate(currentVersion, updateInfo) then
  begin
    if MessageDlg(
      Format('Eine neue Version (%s) ist verfügbar!' + sLineBreak + sLineBreak +
             'Möchten Sie das Update jetzt herunterladen und installieren?' + sLineBreak + sLineBreak +
             'Änderungen:' + sLineBreak + '%s',
             [updateInfo.TagName, SimplifyMarkdownForGitHub(updateInfo.ReleaseNotes)]),
      mtInformation, [mbYes, mbNo], 0) = mrYes then
    begin
      OpenURL(updateInfo.DownloadURL);
    end;
  end
  else
  begin
    MessageDlg('Du verwendest bereits die aktuellste Version (' + currentVersion + ').',
               mtInformation, [mbOK], 0);
  end;
end;

procedure TFormWake.Scannenaus1Click(Sender: TObject);
begin
  SaveSettings;
  LoadSettings;
end;

procedure TFormWake.Taskleistensymbol1Click(Sender: TObject);
var
  ini: TIniFile;
  oldState, newState: Boolean;
  question: string;
  handler: TNotifyEvent;
begin
  // Aktuellen Zustand merken
  oldState := not Taskleistensymbol1.Checked;
  newState := not oldState;

  // Frage formulieren
  if newState then
    question := 'Soll das Taskleistensymbol ab dem nächsten Start angezeigt werden?'
  else
    question := 'Soll das Taskleistensymbol ab dem nächsten Start entfernt werden?';

  // Dialog anzeigen
  if MessageDlg(question, mtConfirmation, [mbYes, mbCancel], 0) = mrYes then
  begin
    // OnClick-Handler temporär entfernen, um Endlosschleife zu vermeiden
    handler := Taskleistensymbol1.OnClick;
    Taskleistensymbol1.OnClick := nil;
    Taskleistensymbol1.Checked := newState;
    Taskleistensymbol1.OnClick := handler;

    // INI schreiben
    ini := TIniFile.Create(TPath.Combine(GetAppDataPath, 'settings.ini'));
    try
      ini.WriteBool('Options', 'ShowInTaskbar', newState);
    finally
      ini.Free;
    end;
    if MessageDlg('Programm jetzt beenden?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      Application.Terminate;
    end;

  end
  else
  begin
    // Änderung abbrechen → zurücksetzen auf alten Zustand
    handler := Taskleistensymbol1.OnClick;
    Taskleistensymbol1.OnClick := nil;
    Taskleistensymbol1.Checked := oldState;
    Taskleistensymbol1.OnClick := handler;
  end;
end;

procedure TFormWake.TrayIcon1DblClick(Sender: TObject);
begin
  // Fenster anzeigen, falls minimiert oder versteckt
  ShwFiles.Show;
  ShwFiles.WindowState := wsNormal;
//  ShwFiles.BringToFront;
end;

procedure TFormWake.TrayIcon1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    // Fokus holen, falls notwendig
    SetForegroundWindow(Handle);

    // Menü anzeigen
    if Button in [mbLeft, mbRight] then
      TrayIcon1.PopupMenu.Popup(X, Y);
  end;
end;

end.
