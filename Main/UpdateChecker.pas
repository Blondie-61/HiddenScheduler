unit UpdateChecker;

interface

uses
  System.SysUtils, Net.HttpClient, Winapi.Windows, Winapi.ShellAPI, System.JSON;

type
  TUpdateInfo = record
    TagName: string;
    ReleaseNotes: string;
    DownloadURL: string;
    IsNewer: Boolean;
  end;

function SimplifyMarkdownForGitHub(const md: string): string;
procedure OpenURL(const URL: string);
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

function GetAppVersion: string;
var
  V1, V2, V3, V4: word;

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

begin
  GetBuildInfo(V1, V2, V3, V4);
//  Result := IntToStr(V1) + '.' + IntToStr(V2) + '.' + IntToStr(V3) + '.' + IntToStr(V4);
  Result := IntToStr(V1) + '.' + IntToStr(V2) + '.' + IntToStr(V3);
  Result := '1.0.0';
end;

function NormalizeVersion(const Version: string): string;
begin
  Result := Version.Trim.ToLower.Replace('v', '');
end;

function IsVersionNewer(const CurrentVer, RemoteVer: string): Boolean;
begin
  Result := NormalizeVersion(RemoteVer) > NormalizeVersion(CurrentVer);
end;

function CheckForUpdate(const CurrentVersion: string; out Info: TUpdateInfo): Boolean;
var
  client: THttpClient;
  response: IHTTPResponse;
  json: TJSONObject;
  assets: TJSONArray;
  asset: TJSONObject;
  i: Integer;
  releaseTag, releaseBody, downloadUrl: string;
begin
  Result := False;
  FillChar(Info, SizeOf(Info), 0);

  client := THttpClient.Create;
  try
    // Abfrage über die GitHub-API
    response := client.Get('https://api.github.com/repos/Blondie-61/HiddenScheduler/releases/latest');

    if response.StatusCode = 200 then
    begin
      json := TJSONObject.ParseJSONValue(response.ContentAsString()) as TJSONObject;
      try
        releaseTag := json.GetValue<string>('tag_name');
        releaseBody := json.GetValue<string>('body');

        Info.TagName := releaseTag;
        Info.ReleaseNotes := releaseBody;
        Info.IsNewer := IsVersionNewer(CurrentVersion, releaseTag);

        // Nach bestimmtem Asset suchen (Setup-Datei)
        if json.TryGetValue<TJSONArray>('assets', assets) then
        begin
          for i := 0 to assets.Count - 1 do
          begin
            asset := assets.Items[i] as TJSONObject;

            // Hier musst Du den echten Dateinamen eintragen:
            if asset.GetValue<string>('name').ToLower = 'sleepsetup.exe' then
            begin
              downloadUrl := asset.GetValue<string>('browser_download_url');
              Info.DownloadURL := downloadUrl;
              Break;
            end;
          end;
        end;

        // Falls keine URL gefunden wurde → generischen Download-Link versuchen
        if Info.DownloadURL = '' then
        begin
          Info.DownloadURL := Format(
            'https://github.com/Blondie-61/HiddenScheduler/releases/download/%s/SleepSetup.exe',
            [releaseTag]
          );
        end;

        Result := Info.IsNewer;
      finally
        json.Free;
      end;
    end;
  finally
    client.Free;
  end;
end;

end.
