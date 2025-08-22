program WakeHidden;

uses
  Vcl.Forms,
  IniFiles,
  System.IOUtils,
  System.SysUtils,
  WakeHiddenU in 'WakeHiddenU.pas' {FormWake},
  ShwFilesU in 'ShwFilesU.pas' {ShwFiles},
  FormToastU in 'FormToastU.pas' {FormToastF},
  AppIconHostU in 'AppIconHostU.pas' {FormAppIconHost},
  WakeTimeDialog in 'WakeTimeDialog.pas' {frmWakeTimeDialog},
  UpdaterDownloadU in 'UpdaterDownloadU.pas' {frmUpdaterDownload},
  SemVerCompare in 'SemVerCompare.pas';

{$R *.res}

begin
  Application.Initialize;

  if TaskbarIconEnabled then
  begin
    Application.MainFormOnTaskbar := True;
    Application.CreateForm(TShwFiles, ShwFiles);
  Application.CreateForm(TfrmWakeTimeDialog, frmWakeTimeDialog);
  // sichtbar in Taskbar
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

