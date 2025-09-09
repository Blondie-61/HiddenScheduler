unit UpdaterDownloadU;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.StrUtils, System.Types, System.DateUtils, System.Math,
  Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Controls,
  Winapi.Windows, Winapi.ShlObj, Winapi.ActiveX,  Winapi.ShellAPI, System.Win.Registry,
  IdHTTP, IdComponent, IdSSLOpenSSL, IdSSLOpenSSLHeaders,
  System.JSON;

type
  TUpdateInfo = record
    TagName:      string;
    ReleaseNotes: string;
    DownloadURL:  string;
    IsNewer:      Boolean;
    PublishedAt:  TDateTime;
  end;

function CheckForUpdate(const CurrentVersion: string; out Info: TUpdateInfo): Boolean;
function TryUpdate(const CurrentVersion: string): Boolean;

type
  TfrmUpdaterDownload = class(TForm)
    edtUrl: TEdit;
    edtFolder: TEdit;
    btnBrowse: TButton;
    btnStart: TButton;
    btnCancel: TButton;
    pb: TProgressBar;
    lblStatus: TLabel;
    lblTitle: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FUrl: string;
    FCurrentVersion: string;
    FSuggestedName: string;
    FOutFile: string;
    FCancel: Boolean;

    FHttp: TIdHTTP;
    FSSL: TIdSSLIOHandlerSocketOpenSSL;
    FContentLen: Int64;
    FWorked: Int64;

    procedure SetDefaultFolder(const ADefault: string);
    function PickFolder(const AStartIn: string): string;
    function BytesToNice(const B: Int64): string;
    function ExtractFileNameFromUrl(const AUrl: string): string;
    procedure EnableUI(const AEnabled: Boolean);

    procedure SetupHttp;
    procedure HttpWorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
    procedure HttpWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
    procedure HttpWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
    function DoDownload(const AUrl, ATargetFile: string): Boolean;
  public
    class function Execute(const AUrl, ACurrentVersion: string;
      const ASuggestedFileName: string = ''; const ADefaultFolder: string = ''): Boolean;
  end;

procedure GetBuildInfo(var V1, V2, V3, V4: word);
function GetAppVersion: string;

const
  // GUID für Downloads-Folder {374DE290-123F-4565-9164-39C4925E467B}
  FOLDERID_Downloads: TGUID = '{374DE290-123F-4565-9164-39C4925E467B}';

implementation

{$R *.dfm}


{ Helpers }
function CoTaskMemStrToString(p: PWideChar): string;
begin
  Result := '';
  if p <> nil then
    Result := p;
end;

procedure GetBuildInfo(var V1, V2, V3, V4: word);
var
  VerInfoSize, VerValueSize, Dummy: DWord;
  VerInfo: Pointer;
  VerValue: PVSFixedFileInfo;

begin
  VerInfoSize := GetFileVersionInfoSize(PChar(ParamStr(0)), Dummy);
  GetMem(VerInfo, VerInfoSize);
  GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, VerInfo);
  VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
  with VerValue^ do
  begin
    V1 := dwFileVersionMS shr 16;
    V2 := dwFileVersionMS and $FFFF;
    V3 := dwFileVersionLS shr 16;
    V4 := dwFileVersionLS and $FFFF;
  end;
  FreeMem(VerInfo, VerInfoSize);
end;

function GetAppVersion: string;
var
  V1, V2, V3, V4: word;

begin
  GetBuildInfo(V1, V2, V3, V4);
  Result := IntToStr(V1) + '.' + IntToStr(V2) + '.' + IntToStr(V3);
  {$IFDEF DEBUG}
  //Result := '1.0.0';
  {$ENDIF};
end;

function GetDownloadsFolderPath: string;
var
  p: PWideChar;
begin
  Result := '';
  p := nil;
  if Succeeded(SHGetKnownFolderPath(FOLDERID_Downloads, 0, 0, p)) then
  try
    Result := p;
  finally
    CoTaskMemFree(p);
  end;

  if Result = '' then
    Result := TPath.Combine(TPath.GetHomePath, 'Downloads');

  if not TDirectory.Exists(Result) then
    ForceDirectories(Result);
end;

// ===== Update-Logik (GitHub "latest") =====

function NormalizeVersion(const Version: string): string;
begin
  Result := Version.Trim.ToLower.Replace('v', '');
end;

function IsVersionNewer(const CurrentVer, RemoteVer: string): Boolean;
begin
  // Einfacher lexikographischer Vergleich – für 1.2.10 vs 1.2.2 ggf. durch SemVer ersetzen
  Result := NormalizeVersion(RemoteVer) > NormalizeVersion(CurrentVer);
end;

function SimplifyMarkdownForGitHub(const md: string): string;
var
  s: string;
begin
  s := md;
  // Checkboxen
  s := StringReplace(s, '[x]', '✅', [rfReplaceAll, rfIgnoreCase]);
  s := StringReplace(s, '[ ]', '⬜️', [rfReplaceAll, rfIgnoreCase]);
  // Emojis (kleine Auswahl)
  s := StringReplace(s, ':rocket:',  '🚀', [rfReplaceAll, rfIgnoreCase]);
  s := StringReplace(s, ':wrench:',  '🔧', [rfReplaceAll, rfIgnoreCase]);
  s := StringReplace(s, ':package:', '📦', [rfReplaceAll, rfIgnoreCase]);
  s := StringReplace(s, ':bug:',     '🐞', [rfReplaceAll, rfIgnoreCase]);
  s := StringReplace(s, ':zap:',     '⚡', [rfReplaceAll, rfIgnoreCase]);
  s := StringReplace(s, ':memo:',    '📝', [rfReplaceAll, rfIgnoreCase]);
  // Fett & Header vereinfachen
  s := StringReplace(s, '**', '', [rfReplaceAll]);
  s := StringReplace(s, '## ', '', [rfReplaceAll]);
  // Trennlinien
  s := StringReplace(s, '---', '', [rfReplaceAll]);
  Result := Trim(s);
end;

function CheckForUpdate(const CurrentVersion: string; out Info: TUpdateInfo): Boolean;
var
  http   : TIdHTTP;
  ssl    : TIdSSLIOHandlerSocketOpenSSL;
  resp   : string;
  json   : TJSONObject;
  assets : TJSONArray;
  asset  : TJSONObject;
  i      : Integer;
  tag, body, dtStr, dlUrl, name: string;
begin
  Result := False;
  FillChar(Info, SizeOf(Info), 0);

  http := TIdHTTP.Create(nil);
  ssl  := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  try
    ssl.SSLOptions.Method := sslvTLSv1_2;
    ssl.SSLOptions.Mode   := sslmClient;

    http.IOHandler := ssl;
    http.HandleRedirects := True;
    http.ReadTimeout := 30000;
    http.ConnectTimeout := 15000;

    // GitHub erwartet UA, Accept
    http.Request.UserAgent := 'HiddenScheduler-UpdateChecker/1.0 (+Indy)';
    http.Request.CustomHeaders.Values['Accept'] := 'application/vnd.github+json';

    resp := http.Get('https://api.github.com/repos/Blondie-61/HiddenScheduler/releases/latest');

    json := TJSONObject(TJSONObject.ParseJSONValue(resp));
    try
      if json = nil then Exit;

      tag  := json.GetValue<string>('tag_name');
      body := json.GetValue<string>('body');

      if json.TryGetValue<string>('published_at', dtStr) then
      try
        Info.PublishedAt := ISO8601ToDate(dtStr, True);
      except
        Info.PublishedAt := 0;
      end;

      Info.TagName      := tag;
      Info.ReleaseNotes := body;
      Info.IsNewer      := IsVersionNewer(CurrentVersion, tag);

      // Asset "SleepSetup.exe" suchen
      dlUrl := '';
      if json.TryGetValue<TJSONArray>('assets', assets) then
      begin
        for i := 0 to assets.Count - 1 do
        begin
          asset := TJSONObject(assets.Items[i]);
          if asset = nil then Continue;
          name := asset.GetValue<string>('name');
          if SameText(name, 'SleepSetup.exe') then
          begin
            dlUrl := asset.GetValue<string>('browser_download_url');
            Break;
          end;
        end;
      end;

      // Fallback: direkter Link per Tag
      if dlUrl = '' then
        dlUrl := Format(
          'https://github.com/Blondie-61/HiddenScheduler/releases/download/%s/SleepSetup.exe',
          [tag]
        );

      Info.DownloadURL := dlUrl;

      Result := Info.IsNewer;
    finally
      json.Free;
    end;
  finally
    http.Free;
    ssl.Free;
  end;
end;

function WriteRunOnceToRestart: Boolean;
var
  R: TRegistry;
  exePath, valueData: string;
begin
  Result := False;
  exePath := ParamStr(0);
  valueData := '"' + exePath + '" /afterupdate';  // ggf. eigenen Parameter anpassen

  R := TRegistry.Create(KEY_SET_VALUE);
  try
    R.RootKey := HKEY_CURRENT_USER;
    if R.OpenKey('\Software\Microsoft\Windows\CurrentVersion\RunOnce', True) then
    begin
      R.WriteString('HiddenScheduler_Restart', valueData); // WriteString ist eine Prozedur
      R.CloseKey;
      Result := True;
    end;
  finally
    R.Free;
  end;
end;

function StartInstallerAndExit(const InstallerPath: string): Boolean;
const
  // Wunsch-Flags: bei Bedarf /VERYSILENT statt /SILENT verwenden
  INNO_PARAMS =
    '/SILENT /SUPPRESSMSGBOXES /NOCANCEL ' +
    '/CLOSEAPPLICATIONS /FORCECLOSEAPPLICATIONS /NORESTART';
var
  sei: TShellExecuteInfo;
  logPath, params: string;
  pid: DWORD;
  exeToRestart, psCmd: string;
begin
  Result := False;

  if not FileExists(InstallerPath) then
  begin
    MessageDlg('Installer nicht gefunden:'#13#10 + InstallerPath, mtError, [mbOK], 0);
    Exit;
  end;

  // (Optional) Fallback: RunOnce setzen – falls der Relauncher scheitert,
  // startet die App beim nächsten Login trotzdem.
  WriteRunOnceToRestart;

  logPath := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) +
             'HiddenScheduler_Update_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.log';
  params  := INNO_PARAMS + ' /LOG="' + logPath + '"';

  ZeroMemory(@sei, SizeOf(sei));
  sei.cbSize := SizeOf(sei);
  sei.fMask := SEE_MASK_NOCLOSEPROCESS;
  sei.Wnd := Application.Handle;
  sei.lpVerb := 'runas'; // Elevation anfordern
  sei.lpFile := PChar(InstallerPath);
  sei.lpParameters := PChar(params);
  sei.lpDirectory := PChar(ExtractFileDir(InstallerPath));
  sei.nShow := SW_SHOWNORMAL;

  if not ShellExecuteEx(@sei) then
  begin
    MessageDlg('Installer-Start abgebrochen oder fehlgeschlagen.', mtWarning, [mbOK], 0);
    Exit;
  end;

  // PID des Installer-Prozesses holen
  pid := 0;
  if sei.hProcess <> 0 then
    pid := GetProcessId(sei.hProcess);

  // Relaunch-Helfer starten (unabhängig von unserer App)
  // Wartet auf Ende des Installers und startet dann unsere EXE neu.
  exeToRestart := ParamStr(0);
  // PowerShell: Wait-Process -Id <pid>; Start-Process "<exe>" "/afterupdate"
  if pid <> 0 then
  begin
    psCmd :=
      Format(
        'powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command '+
        '"try { Wait-Process -Id %d -ErrorAction SilentlyContinue } catch {} ; ' +
        'Start-Sleep -Seconds 1; ' +
        'Start-Process -FilePath ''%s'' -ArgumentList ''/afterupdate'' "',
        [pid, exeToRestart]
      );

    // Startet den Helfer detached; blockiert uns nicht
    ShellExecute(0, 'open', 'cmd.exe', PChar('/c ' + psCmd), nil, SW_HIDE);
  end
  else
  begin
    // Falls keine PID (extrem selten): trotzdem direkt neu starten nach kurzer Wartezeit
    psCmd :=
      Format(
        'powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command '+
        '"Start-Sleep -Seconds 10; Start-Process -FilePath ''%s'' -ArgumentList ''/afterupdate'' "',
        [exeToRestart]
      );
    ShellExecute(0, 'open', 'cmd.exe', PChar('/c ' + psCmd), nil, SW_HIDE);
  end;

  // Jetzt sofort sauber beenden, damit Dateien ersetzt werden können
  Application.Terminate;
  Result := True;
end;

function TryUpdate(const CurrentVersion: string): Boolean;
var
  Info: TUpdateInfo;
  notes: string;
  installerPath: string;
begin
  Result := False;

  if not CheckForUpdate(CurrentVersion, Info) then
    Exit;

  notes := SimplifyMarkdownForGitHub(Info.ReleaseNotes);

  if MessageDlg(
       Format('Neue Version verfügbar: %s (Du hast %s)'#13#10#13#10 +
              'Jetzt herunterladen und installieren?'#13#10#13#10 +
              'Änderungen:'#13#10'%s',
              [Info.TagName, CurrentVersion, notes]),
       mtInformation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  // 1) Download mit deiner bestehenden Maske
  if not TfrmUpdaterDownload.Execute(Info.DownloadURL, CurrentVersion,
                                     'SleepSetup.exe', '') then
    Exit;

  // 2) Installerpfad im Downloads-Ordner (Name entspricht dem Vorschlag oben)
  installerPath := TPath.Combine(GetDownloadsFolderPath, 'SleepSetup.exe');

  // 3) Installer starten (elevated) + App schließen; RunOnce sorgt für Neustart
  if StartInstallerAndExit(installerPath) then
    Result := True;
end;

{ TfrmUpdaterDownload }

class function TfrmUpdaterDownload.Execute(const AUrl, ACurrentVersion: string;
  const ASuggestedFileName: string; const ADefaultFolder: string): Boolean;
var
  F: TfrmUpdaterDownload;
begin
  Result := False;
  F := TfrmUpdaterDownload.Create(nil);
  try
    F.FUrl := AUrl;
    F.FCurrentVersion := ACurrentVersion;
    F.FSuggestedName := ASuggestedFileName;

    if Assigned(F.lblTitle) then
      F.lblTitle.Caption := Format('Update herunterladen (aktuell: %s)', [ACurrentVersion]);

    F.SetDefaultFolder(ADefaultFolder);
    F.edtUrl.Text := AUrl;

    Result := (F.ShowModal = mrOk);
  finally
    F.Free;
  end;
end;

procedure TfrmUpdaterDownload.FormCreate(Sender: TObject);
begin
  Caption := 'Update herunterladen';
  if Assigned(lblTitle) then
    lblTitle.Caption := 'Updater';
  pb.Min := 0;
  pb.Max := 100;
  pb.Position := 0;
  lblStatus.Caption := '';
  FCancel := False;

  SetupHttp;
end;

procedure TfrmUpdaterDownload.FormDestroy(Sender: TObject);
begin
  try
    if Assigned(FHttp) and FHttp.Connected then
      FHttp.Disconnect;
  except end;

  FreeAndNil(FHttp);
  FreeAndNil(FSSL);
end;

procedure TfrmUpdaterDownload.SetupHttp;
begin
  // SSL?Handler
  FSSL := TIdSSLIOHandlerSocketOpenSSL.Create(Self);
  FSSL.SSLOptions.Method := sslvTLSv1_2;   // i.d.R. ausreichend
  FSSL.SSLOptions.Mode   := sslmClient;

  // HTTP?Client
  FHttp := TIdHTTP.Create(Self);
  FHttp.IOHandler := FSSL;                 // HTTPS unterstützen
  FHttp.HandleRedirects := True;
  FHttp.ProtocolVersion := pv1_1;
  FHttp.ReadTimeout := 60 * 1000;
  FHttp.ConnectTimeout := 30 * 1000;
  FHttp.Request.UserAgent := 'Sleep-Updater/1.0';
  FHttp.Request.Accept := '*/*';
  FHttp.Request.AcceptEncoding := 'identity'; // progressfreundlich

  // Progress?Events
  FHttp.OnWorkBegin := HttpWorkBegin;
  FHttp.OnWork := HttpWork;
  FHttp.OnWorkEnd := HttpWorkEnd;
end;

procedure TfrmUpdaterDownload.HttpWorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
begin
  FContentLen := AWorkCountMax;  // kann -1 sein (unbekannt)
  FWorked := 0;
  pb.Position := 0;
  lblStatus.Caption := 'Verbunden …';
  lblStatus.Update;
end;

procedure TfrmUpdaterDownload.HttpWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
var
  percent: Integer;
  s: string;
begin
  FWorked := AWorkCount;

  if (FContentLen > 0) then
    percent := EnsureRange(Round((FWorked / FContentLen) * 100), 0, 100)
  else
    percent := 0;

  pb.Position := percent;
  s := Format('%s von %s',
    [BytesToNice(FWorked), BytesToNice(FContentLen)]);
  lblStatus.Caption := s;
  lblStatus.Update;

  if FCancel then
  begin
    // sauber abbrechen
    try
      if FHttp.Connected then
        FHttp.Disconnect;
    except end;
    Abort; // hebt das Get() sauber auf
  end;
end;

procedure TfrmUpdaterDownload.HttpWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
begin
  // optional
end;

procedure TfrmUpdaterDownload.EnableUI(const AEnabled: Boolean);
begin
  edtUrl.Enabled := AEnabled;
  edtFolder.Enabled := AEnabled;
  btnBrowse.Enabled := AEnabled;
  btnStart.Enabled := AEnabled;
  btnCancel.Enabled := not AEnabled; // während Download nur „Abbrechen“
end;

function TfrmUpdaterDownload.BytesToNice(const B: Int64): string;
const
  KB = 1024.0; MB = 1024.0 * 1024.0; GB = 1024.0 * 1024.0 * 1024.0;
begin
  if B < 0 then Exit('—');
  if B < KB then
    Result := Format('%d B', [B])
  else if B < MB then
    Result := Format('%.1f KB', [B / KB])
  else if B < GB then
    Result := Format('%.1f MB', [B / MB])
  else
    Result := Format('%.2f GB', [B / GB]);
end;

function TfrmUpdaterDownload.ExtractFileNameFromUrl(const AUrl: string): string;
var
  u: string; q: Integer;
begin
  u := AUrl.Trim;
  q := Pos('?', u);
  if q > 0 then
    u := Copy(u, 1, q-1);
  Result := TPath.GetFileName(u);
  if Result = '' then
    Result := 'download.bin';
end;

procedure TfrmUpdaterDownload.SetDefaultFolder(const ADefault: string);
var
  base: string;
begin
  if ADefault <> '' then base := ADefault else base := GetDownloadsFolderPath;
  try
    if (base = '') or not TDirectory.Exists(base) then
      base := GetDownloadsFolderPath;
  except
    base := GetDownloadsFolderPath;
  end;
  edtFolder.Text := base;
end;

function TfrmUpdaterDownload.PickFolder(const AStartIn: string): string;
var
  dlg: IFileOpenDialog; hr: HRESULT; flags: DWORD; it: IShellItem; ws: PWideChar;
begin
  Result := '';
  try
    hr := CoCreateInstance(CLSID_FileOpenDialog, nil, CLSCTX_INPROC_SERVER,
                           IFileOpenDialog, dlg);
    if Failed(hr) or (dlg = nil) then
      Exit('');

    flags := FOS_PICKFOLDERS or FOS_FORCEFILESYSTEM or FOS_PATHMUSTEXIST;
    dlg.SetOptions(flags);

    if AStartIn <> '' then
      if Succeeded(SHCreateItemFromParsingName(PWideChar(AStartIn), nil, IID_IShellItem, it)) then
        dlg.SetFolder(it);

    hr := dlg.Show(Handle);
    if Failed(hr) then Exit('');

    if Succeeded(dlg.GetResult(it)) then
      if Succeeded(it.GetDisplayName(SIGDN_FILESYSPATH, ws)) then
      try
        Result := ws;
      finally
        CoTaskMemFree(ws);
      end;
  except
    with TFileOpenDialog.Create(nil) do
    try
      Options := [fdoPickFolders, fdoPathMustExist, fdoForceFileSystem];
      if AStartIn <> '' then
        DefaultFolder := AStartIn;
      if Execute then
        Result := FileName;
    finally
      Free;
    end;
  end;
end;

procedure TfrmUpdaterDownload.btnBrowseClick(Sender: TObject);
var
  sel: string;
begin
  sel := PickFolder(edtFolder.Text);
  if sel <> '' then
    edtFolder.Text := sel;
end;

procedure TfrmUpdaterDownload.btnCancelClick(Sender: TObject);
begin
  FCancel := True;
  lblStatus.Caption := 'Abbruch wird vorbereitet …';
end;

procedure TfrmUpdaterDownload.btnStartClick(Sender: TObject);
var
  folder, name: string;
begin
  FCancel := False;
  FUrl := Trim(edtUrl.Text);
  folder := Trim(edtFolder.Text);

  if FUrl = '' then
    raise Exception.Create('Bitte eine URL angeben.');
  if (folder = '') or not TDirectory.Exists(folder) then
    raise Exception.Create('Zielordner ist ungültig.');

  name := FSuggestedName;
  if name = '' then
    name := ExtractFileNameFromUrl(FUrl);

  FOutFile := TPath.Combine(folder, name);

  if TFile.Exists(FOutFile) then
  begin
    if MessageDlg('Datei existiert bereits: ' + FOutFile + sLineBreak +
                  'Überschreiben?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then Exit;
    TFile.Delete(FOutFile);
  end;

  EnableUI(False);
  try
    if DoDownload(FUrl, FOutFile) then
    begin
      lblStatus.Caption := 'Fertig.';
      ModalResult := mrOk;
    end;
  finally
    EnableUI(True);
  end;
end;

function TfrmUpdaterDownload.DoDownload(const AUrl, ATargetFile: string): Boolean;
var
  fs: TFileStream;
begin
  Result := False;
  FContentLen := -1;
  FWorked := 0;
  pb.Position := 0;
  lblStatus.Caption := 'Verbinde …';
  lblStatus.Update;

  fs := TFileStream.Create(ATargetFile, fmCreate or fmShareDenyWrite);
  try
    try
      FHttp.Get(AUrl, fs); // löst OnWork/OnWorkBegin aus
      if not FCancel then
      begin
        pb.Position := 100;
        lblStatus.Caption := 'Download abgeschlossen: ' + ATargetFile;
        Result := True;
      end
      else
      begin
        lblStatus.Caption := 'Abgebrochen.';
        Result := False;
      end;
    except
      on E: EAbort do
      begin
        lblStatus.Caption := 'Abgebrochen.';
        Result := False;
      end;
      on E: Exception do
      begin
        lblStatus.Caption := 'Fehler: ' + E.Message;
        Result := False;
      end;
    end;
  finally
    fs.Free;
    if not Result then
      try TFile.Delete(ATargetFile); except end;
  end;
end;

end.
