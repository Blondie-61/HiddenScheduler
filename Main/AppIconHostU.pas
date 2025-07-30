// === Datei: AppIconHostU.pas ===
unit AppIconHostU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, Vcl.Forms, Vcl.Graphics, Vcl.Controls,
  IOUtils, IniFiles;

type
  TFormAppIconHost = class(TForm)
  private
    FShowAppIcon: Boolean;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
  public
    constructor Create(AOwner: TComponent); override;
    property ShowAppIcon: Boolean read FShowAppIcon write FShowAppIcon;
  end;

var
  FormAppIconHost: TFormAppIconHost;

implementation

uses ShwFilesU, WakeHiddenU;

{$R *.dfm}

constructor TFormAppIconHost.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BorderStyle := bsNone;
  BorderIcons := [];
  Width := 1;
  Height := 1;
  Left := -10000;
  Top := -10000;

  // NICHT sichtbar machen
  Visible := False;
  //ShowWindow(Handle, SW_HIDE); // redundant, aber zur Sicherheit
end;

procedure TFormAppIconHost.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);

  if not TaskbarIconEnabled then
    Params.ExStyle := Params.ExStyle or WS_EX_TOOLWINDOW
  else
    Params.ExStyle := Params.ExStyle or WS_EX_APPWINDOW;
end;

procedure TFormAppIconHost.WMSysCommand(var Msg: TWMSysCommand);
begin
  inherited;
  if Msg.CmdType = SC_RESTORE then
  begin
    if Assigned(ShwFiles) then
    begin
      ShwFiles.Show;
      ShwFiles.WindowState := wsNormal;
      ShwFiles.BringToFront;
      ShwFiles.SetFocus;
    end;
  end;
end;

end.
