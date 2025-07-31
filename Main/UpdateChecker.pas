unit UpdateChecker;

interface

uses
  System.SysUtils, Net.HttpClient, Winapi.Windows, System.JSON;

type
  TUpdateInfo = record
    TagName: string;
    ReleaseNotes: string;
    DownloadURL: string;
    IsNewer: Boolean;
  end;

function CheckForUpdate(const CurrentVersion: string; out Info: TUpdateInfo): Boolean;

implementation

uses
  System.Net.URLClient, System.NetConsts;

function strBuildInfo: string;
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
  result := IntToStr(V1) + '.' + IntToStr(V2) + '.' + IntToStr(V3) + '.' + IntToStr(V4);
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
begin
  Result := False;
  FillChar(Info, SizeOf(Info), 0);

  client := THttpClient.Create;
  try
    response := client.Get('https://api.github.com/repos/Blondie-61/HiddenScheduler/releases/latest');

    if response.StatusCode = 200 then
    begin
      json := TJSONObject.ParseJSONValue(response.ContentAsString()) as TJSONObject;
      try
        Info.TagName := json.GetValue<string>('tag_name');
        Info.ReleaseNotes := json.GetValue<string>('body');
        Info.IsNewer := IsVersionNewer(CurrentVersion, Info.TagName);

        if json.TryGetValue('assets', assets) then
        begin
          for i := 0 to assets.Count - 1 do
          begin
            asset := assets.Items[i] as TJSONObject;
            if asset.GetValue<string>('name').ToLower = 'setup.exe' then
            begin
              Info.DownloadURL := asset.GetValue<string>('browser_download_url');
              Break;
            end;
          end;
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
