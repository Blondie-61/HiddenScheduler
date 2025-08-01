﻿program Sleep_con;

{$APPTYPE GUI}
//{$APPTYPE CONSOLE}
{$R *.res}
uses
  System.SysUtils,
  System.IOUtils,
  System.DateUtils,
  System.JSON,
  Winapi.Windows,
  WakeTimeDialog in 'WakeTimeDialog.pas' {frmWakeTimeDialog};

const
  ENABLE_LOGGING = True;

function GetAppDataPath: string;
begin
  Result := TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'HiddenScheduler');
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
        Break; // ← WICHTIG: Bei Erfolg raus
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

function GetWakeUpTime(option: string): TDateTime;
var
  today: Word;
begin
  option := LowerCase(option);

  if option = '1h' then
    Result := Now + 1/24
  else if option = '2h' then
    Result := Now + 2/24
  else if option = '4h' then
    Result := Now + 4/24
  else if option = 'morgen' then
    Result := IncDay(StartOfTheDay(Now), 1) + EncodeTime(6, 0, 0, 0)
  else if option = 'wochenende' then
  begin
    today := DayOfTheWeek(Now); // 1 = Sonntag
    var daysToSaturday := (7 - today + 6) mod 7;
    if daysToSaturday = 0 then daysToSaturday := 7;
    Result := StartOfTheDay(IncDay(Now, daysToSaturday)) + EncodeTime(9, 0, 0, 0);
  end
  else if option = 'z_individuell' then
  begin
    if not TfrmWakeTimeDialog.Execute(Result) then
      raise Exception.Create('Auswahl abgebrochen. Keine WakeTime festgelegt.');
  end
  else
    raise Exception.Create('Ungültige Zeitoption: ' + option);
end;

procedure SaveToHiddenList(const filePath: string; const wakeTime: TDateTime);
var
  jsonArr: TJSONArray;
  jsonObj: TJSONObject;
  jsonStr, jsonFile: string;
  i, retryCount: Integer;
  alreadyExists: Boolean;
  mergedArr: TJSONArray;
begin
  ForceDirectories(GetAppDataPath);
  jsonFile := GetJsonFilePath;

  Log('→ Speichere Schlaf-Eintrag für: ' + filePath);
  Log('JSON-Datei: ' + jsonFile);

  retryCount := 0;
  while retryCount < 5 do
  begin
    try
      if TFile.Exists(jsonFile) then
        jsonStr := TFile.ReadAllText(jsonFile)
      else
        jsonStr := '[]';

      jsonArr := TJSONObject.ParseJSONValue(jsonStr) as TJSONArray;
      if not Assigned(jsonArr) then
      begin
        Log('⚠️ Fehler beim Parsen der JSON – Neue Liste wird angelegt');
        jsonArr := TJSONArray.Create;
      end;

      alreadyExists := False;
      for i := 0 to jsonArr.Count - 1 do
      begin
        if SameText(jsonArr.Items[i].GetValue<string>('path'), filePath) then
        begin
          alreadyExists := True;
          Break;
        end;
      end;

      if alreadyExists then
      begin
        Log('❌ Eintrag bereits vorhanden – wird nicht gespeichert: ' + filePath);
        jsonArr.Free;
        Exit;
      end;

      jsonObj := TJSONObject.Create;
      jsonObj.AddPair('path', filePath);
      jsonObj.AddPair('hideTime', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now));
      jsonObj.AddPair('wakeTime', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', wakeTime));
      jsonArr.AddElement(jsonObj);

      // Versuch schreiben
      TFile.WriteAllText(jsonFile, jsonArr.ToJSON);
      Log('✅ JSON-Eintrag erfolgreich geschrieben.');
      jsonArr.Free;
      Exit;
    except
      on E: Exception do
      begin
        Log('⚠️ Schreibkonflikt – Wiederhole Versuch ' + IntToStr(retryCount + 1));
        Inc(retryCount);
        Sleep(100);
      end;
    end;
  end;

  Log('💥 Fehler beim Schreiben der JSON-Datei – alle Versuche fehlgeschlagen');
end;

function CreateMutexForFile(const filePath: string): THandle;
var
  mutexName: string;
begin
  mutexName := 'HiddenScheduler_' + StringReplace(filePath, '\', '_', [rfReplaceAll]);
  Result := CreateMutex(nil, True, PChar(mutexName));
end;

procedure HideFile(const filePath: string);
var
  attrs: DWORD;
begin
  attrs := GetFileAttributes(PChar(filePath));
  if attrs = INVALID_FILE_ATTRIBUTES then
    raise Exception.Create('Datei nicht gefunden: ' + filePath);

  if (attrs and FILE_ATTRIBUTE_HIDDEN) = 0 then
  begin
    SetFileAttributes(PChar(filePath), attrs or FILE_ATTRIBUTE_HIDDEN);
    Log('Hidden-Attribut gesetzt für: ' + filePath);
  end
  else
    Log('Datei war bereits versteckt: ' + filePath);
end;

begin
  try
    if ParamCount < 2 then
    begin
      Log('Usage: sleep_con.exe <Dateipfad> <Zeitoption>');
      Exit;
    end;

    var filePath := TPath.GetFullPath(ParamStr(1));
    var option := ParamStr(2);

    // Mutex für diese Datei erstellen
    var mutex := CreateMutexForFile(filePath);
    if GetLastError = ERROR_ALREADY_EXISTS then
    begin
      Log('⛔ Sleep läuft bereits für: ' + filePath);
      Exit;
    end;

    // WakeTime berechnen (abhängig von option)
    var wakeTime := GetWakeUpTime(option);

    HideFile(filePath);
    SaveToHiddenList(filePath, wakeTime);

  except
    on E: Exception do
    begin
      Log('💥 FEHLER: ' + E.Message);
      MessageBox(0, PChar(E.Message), 'Fehler in Sleep_con', MB_ICONERROR);
    end;
  end;
end.

