unit LastWakeStore;

interface

uses
  System.SysUtils, System.IOUtils, System.DateUtils, System.JSON;

function LoadLastWakeTime(out AWhen: TDateTime): Boolean;
procedure SaveLastWakeTime(const AWhen: TDateTime);
procedure ClearLastWakeTime;

implementation

function GetPrefsPath: string;
begin
  Result := TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'HiddenScheduler');
  ForceDirectories(Result);
end;

function GetLastWakePath: string;
begin
  Result := TPath.Combine(GetPrefsPath, 'last_wake.json');
end;

procedure SaveLastWakeTime(const AWhen: TDateTime);
var
  o: TJSONObject;
begin
  o := TJSONObject.Create;
  try
    o.AddPair('last', DateToISO8601(AWhen, True));
    o.AddPair('expires', DateToISO8601(IncMinute(Now, 1), True)); // 1 Min gültig
    TFile.WriteAllText(GetLastWakePath, o.ToJSON, TEncoding.UTF8);
  finally
    o.Free;
  end;
end;

function LoadLastWakeTime(out AWhen: TDateTime): Boolean;
var
  s, lastStr, expStr: string;
  o: TJSONObject;
  expDT: TDateTime;
begin
  Result := False;
  if not TFile.Exists(GetLastWakePath) then Exit;

  s := TFile.ReadAllText(GetLastWakePath, TEncoding.UTF8);
  o := TJSONObject(TJSONObject.ParseJSONValue(s));
  try
    if (o <> nil)
    and o.TryGetValue<string>('last', lastStr)
    and o.TryGetValue<string>('expires', expStr) then
    begin
      try expDT := ISO8601ToDate(expStr, True) except expDT := 0 end;
      if (expDT = 0) or (Now <= expDT) then
      begin
        AWhen := ISO8601ToDate(lastStr, True);
        Exit(True);
      end;
    end;
  finally
    o.Free;
  end;

  try TFile.Delete(GetLastWakePath); except end;
end;

procedure ClearLastWakeTime;
begin
  try TFile.Delete(GetLastWakePath) except end;
end;

end.
