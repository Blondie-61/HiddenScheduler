unit UpdateChecker;

interface

uses
  System.SysUtils, Net.HttpClient, Winapi.Windows, Winapi.ShellAPI, System.JSON;

type
  TUpdateInfo = record
    TagName:      string;
    ReleaseNotes: string;
    DownloadURL:  string;
    IsNewer:      Boolean;
    PublishedAt:  TDateTime;
  end;

function SimplifyMarkdownForGitHub(const md: string): string;
procedure OpenURL(const URL: string);
procedure GetBuildInfo(var V1, V2, V3, V4: word);
function GetAppVersion: string;
function CheckForUpdate(const CurrentVersion: string; out Info: TUpdateInfo): Boolean;

implementation

function SimplifyMarkdownForGitHub(const md: string): string;
var
  s: string;
begin
  s := md;

  // --- Checkboxen ---
  s := StringReplace(s, '[x]', '✅', [rfReplaceAll, rfIgnoreCase]);
  s := StringReplace(s, '[ ]', '⬜️', [rfReplaceAll, rfIgnoreCase]);

  // --- Emojis ---
  s := StringReplace(s, ':rocket:', '🚀', [rfReplaceAll, rfIgnoreCase]);
  s := StringReplace(s, ':wrench:', '🔧', [rfReplaceAll, rfIgnoreCase]);
  s := StringReplace(s, ':package:', '📦', [rfReplaceAll, rfIgnoreCase]);
  s := StringReplace(s, ':bug:', '🐞', [rfReplaceAll, rfIgnoreCase]);
  s := StringReplace(s, ':zap:', '⚡', [rfReplaceAll, rfIgnoreCase]);
  s := StringReplace(s, ':memo:', '📝', [rfReplaceAll, rfIgnoreCase]);

  // --- Fett-Schrift entfernen ---
  s := StringReplace(s, '**', '', [rfReplaceAll]);

  // --- Markdown-Header ##
  s := StringReplace(s, '## ', '', [rfReplaceAll]);

  // --- Trennlinien (---) entfernen
  s := StringReplace(s, '---', '', [rfReplaceAll]);

  // --- Leerzeilen am Ende abschneiden ---
  s := Trim(s);

  Result := s;
end;

procedure OpenURL(const URL: string);
begin
  ShellExecute(0, 'open', PChar(URL), nil, nil, SW_SHOWNORMAL);
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
//  Result := '1.0.0';
end;

function NormalizeVersion(const Version: string): string;
begin
  Result := Version.Trim.ToLower.Replace('v', '');
end;

function IsVersionNewer(const CurrentVer, RemoteVer: string): Boolean;
begin
  Result := NormalizeVersion(RemoteVer) > NormalizeVersion(CurrentVer);
end;

/// Liefert TRUE, wenn auf GitHub eine neuere Version als CurrentVersion vorliegt.
/// Füllt Info.TagName, Info.ReleaseNotes, Info.DownloadURL (asset "SleepSetup.exe").
/// Fallback-URL wird automatisch gebildet, falls kein Asset gefunden wird.
function CheckForUpdate(const CurrentVersion: string; out Info: TUpdateInfo): Boolean;
var
  client : THTTPClient;
  resp   : IHTTPResponse;
  json   : TJSONObject;
  assets : TJSONArray;
  asset  : TJSONObject;
  i      : Integer;
  tag    : string;
  body   : string;
  dlUrl  : string;
  dtStr  : string;
begin
  Result := False;
  FillChar(Info, SizeOf(Info), 0);

  client := THTTPClient.Create;
  try
    // GitHub möchte einen UA-Header, sonst drohen 403 in manchen Umgebungen
    client.UserAgent := 'HiddenScheduler-UpdateChecker/1.0 (+Delphi)';
    client.CustomHeaders['Accept'] := 'application/vnd.github+json';

    // "latest" = neuester Stable-Release (kein PreRelease)
    resp := client.Get('https://api.github.com/repos/Blondie-61/HiddenScheduler/releases/latest');

    if resp.StatusCode <> 200 then
      Exit; // sauber abbrechen

    json := TJSONObject(TJSONObject.ParseJSONValue(resp.ContentAsString(TEncoding.UTF8)));
    try
      if json = nil then Exit;

      tag  := json.GetValue<string>('tag_name');
      body := json.GetValue<string>('body');

      // Veröffentlichungszeitpunkt (optional)
      if json.TryGetValue<string>('published_at', dtStr) then
      try
        Info.PublishedAt := ISO8601ToDate(dtStr, True);
      except
        Info.PublishedAt := 0;
      end;

      Info.TagName      := tag;
      Info.ReleaseNotes := body;
      Info.IsNewer      := IsVersionNewer(CurrentVersion, tag);

      // Passendes Asset finden (Case-insensitive) → "SleepSetup.exe"
      dlUrl := '';
      if json.TryGetValue<TJSONArray>('assets', assets) then
      begin
        for i := 0 to assets.Count - 1 do
        begin
          asset := TJSONObject(assets.Items[i]);
          if asset = nil then Continue;

          var name := asset.GetValue<string>('name');
          if SameText(name, 'SleepSetup.exe') then
          begin
            dlUrl := asset.GetValue<string>('browser_download_url');
            Break;
          end;
        end;
      end;

      // Fallback: direkter Release-Download-Link
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
    client.Free;
  end;
end;

end.
