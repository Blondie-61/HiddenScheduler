program WakeHidden;

uses
  Vcl.Forms,
  IniFiles,
  System.IOUtils,
  System.SysUtils,
  WakeHiddenU in 'WakeHiddenU.pas' {FormWake},
  ShwFilesU in 'ShwFilesU.pas' {ShwFiles},
  FormToastU in 'FormToastU.pas' {FormToastF},
  AppIconHostU in 'AppIconHostU.pas' {FormAppIconHost};

{$R *.res}
//  function TaskbarIconEnabled: Boolean;
//  var
//    ini: TIniFile;
//  begin
//    ini := TIniFile.Create(TPath.Combine(GetAppDataPath, 'settings.ini'));
//    try
//      Result := ini.ReadBool('Options', 'ShowInTaskbar', True); // Default: aktiv
//    finally
//      ini.Free;
//    end;
//  end;

begin
  Application.Initialize;

  if TaskbarIconEnabled then
  begin
    Application.MainFormOnTaskbar := True;
    Application.CreateForm(TShwFiles, ShwFiles); // sichtbar in Taskbar
  end
  else
  begin
    Application.MainFormOnTaskbar := True;
    Application.CreateForm(TFormAppIconHost, FormAppIconHost); // steuert Icon
    Application.CreateForm(TShwFiles, ShwFiles);
  end;

  Application.CreateForm(TFormToastF, FormToastF);
  Application.CreateForm(TFormWake, FormWake);
  Application.Run;
end.

