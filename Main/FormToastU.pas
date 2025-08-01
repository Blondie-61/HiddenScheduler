unit FormToastU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Forms, Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Graphics;

type
  TFormToastF = class(TForm)
    lblTitle, lblMsg: TLabel;
    tmrLife: TTimer;
    tmrFade: TTimer;
    btnSnooze5: TButton;
    btnSnooze15: TButton;
    btnSnooze60: TButton;
    btnClose: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmrLifeTimer(Sender: TObject);
    procedure tmrFadeTimer(Sender: TObject);
    procedure btnSnoozeClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FOpacityTarget: Byte;
  public
    procedure ShowToast(const title, msg: string);
    procedure StartFadeOut;
  end;

var
  FormToastF: TFormToastF;

implementation

uses
  WakeHiddenU, Math;

{$R *.dfm}

procedure TFormToastF.FormCreate(Sender: TObject);
begin
  Visible := False;

  const Margin = 20;
  BorderStyle := bsNone;
  AlphaBlend := True;
  AlphaBlendValue := 0;
  FOpacityTarget := 255;
  Color := clWebAliceBlue;
  Position := poDesigned;

//  Width := 942;
//  Height := 294;
//  Left := 0;
//  Top := 0;

  //Rechts oben
  Left := Screen.WorkAreaWidth - Width - Margin;
  Top := Margin;

  //Rechts unten
//  Left := Screen.WorkAreaWidth - Width - Margin;
//  Top := Screen.WorkAreaHeight - Height - Margin;

//  btnSnooze5.SetBounds(10, 10, 55, 25);
//  btnSnooze15.SetBounds(70, 10, 55, 25);
//  btnSnooze60.SetBounds(130, 10, 55, 25);
//  btnClose.SetBounds(190, 10, 60, 25);
end;

procedure TFormToastF.FormShow(Sender: TObject);
begin
  AlphaBlendValue := 0;
  FOpacityTarget := 255;

  tmrLife.Interval := 20000;
  tmrLife.Enabled := True;

  tmrFade.Interval := 100;
  tmrFade.Enabled := True;
end;

procedure TFormToastF.tmrFadeTimer(Sender: TObject);
begin
  if AlphaBlendValue < FOpacityTarget then
    AlphaBlendValue := Min(AlphaBlendValue + 20, FOpacityTarget)
  else if AlphaBlendValue > FOpacityTarget then
  begin
    AlphaBlendValue := Max(AlphaBlendValue - 20, FOpacityTarget);
    if AlphaBlendValue = 0 then
    begin
      tmrFade.Enabled := False;
      Hide;
    end;
  end
  else
    tmrFade.Enabled := False;
end;

procedure TFormToastF.ShowToast(const title, msg: string);
begin
  lblTitle.Caption := title;
  lblMsg.Caption := msg;
  Show;
end;

procedure TFormToastF.tmrLifeTimer(Sender: TObject);
begin
  tmrLife.Enabled := False;
  StartFadeOut;
  Close;
end;

procedure TFormToastF.StartFadeOut;
begin
  FOpacityTarget := 0;
  tmrFade.Enabled := True;
end;

procedure TFormToastF.btnCloseClick(Sender: TObject);
begin
  StartFadeOut;
  Close;
end;

procedure TFormToastF.btnSnoozeClick(Sender: TObject);
begin
  if TButton(Sender).Name = 'btnSnooze5' then WakeHiddenU.DoSnooze(5)
  else if TButton(Sender).Name = 'btnSnooze15' then WakeHiddenU.DoSnooze(15)
  else if TButton(Sender).Name = 'btnSnooze60' then WakeHiddenU.DoSnooze(60);
  StartFadeOut;
  Close;
end;

end.
