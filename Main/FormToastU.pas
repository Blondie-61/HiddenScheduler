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
    lblQueueCount: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

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

  tmrFade.Interval := 50;
  tmrFade.Enabled := True;
end;

procedure TFormToastF.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  tmrLife.Enabled := False;
end;

procedure TFormToastF.ShowToast(const title, msg: string);
begin
  lblTitle.Caption := title;
  lblMsg.Caption := msg;

  var iCnt := GetQueueCount;
  case iCnt of
//    0: lblQueueCount.Caption := 'Keine weitere Datei in der Warteschlange';
    0: lblQueueCount.Caption := '';
    1: lblQueueCount.Caption := 'Eine weitere Datei in der Warteschlange';
    else
      lblQueueCount.Caption := iCnt.ToString + ' weitere Dateien in der Warteschlange';
  end;

  // Auto-Close/Fade sauber neu initialisieren
  if Assigned(tmrLife) then
  begin
    tmrLife.Enabled := False;
    tmrLife.Interval := 15000;  // oder aus Settings laden
    tmrLife.Enabled := True;
  end;

  // Falls vorhanden: einen Fade-Timer ebenfalls zurücksetzen
  if Assigned(TmrFade) then
    TmrFade.Enabled := False;

  Show;  // erst zeigen, nachdem Timer neu gesetzt ist
end;

procedure TFormToastF.tmrLifeTimer(Sender: TObject);
begin
  tmrLife.Enabled := False;
  StartFadeOut; // nur Animation
  // ⚠ KEIN Close hier, sonst AdvanceQueueNow zu früh
end;

procedure TFormToastF.StartFadeOut;
begin
  FOpacityTarget := 0;
  tmrFade.Enabled := True;
end;

//procedure TFormToastF.tmrFadeTimer(Sender: TObject);
//begin
//  if AlphaBlendValue < FOpacityTarget then
//  begin
//    // Fade‑IN
//    AlphaBlendValue := Min(AlphaBlendValue + 20, FOpacityTarget);
//    if AlphaBlendValue = FOpacityTarget then
//      tmrFade.Enabled := False;
//  end
//  else if AlphaBlendValue > FOpacityTarget then
//  begin
//    // Fade‑OUT
//    AlphaBlendValue := Max(AlphaBlendValue - 20, FOpacityTarget);
//    if AlphaBlendValue = 0 then
//    begin
//      tmrFade.Enabled := False;
//      Hide;  // << nur verstecken – NICHT AdvanceQueueNow hier!
//    end;
//  end
//  else
//    tmrFade.Enabled := False;
//end;

procedure TFormToastF.tmrFadeTimer(Sender: TObject);
begin
  if AlphaBlendValue < FOpacityTarget then
  begin
    AlphaBlendValue := Min(AlphaBlendValue + 20, FOpacityTarget);
    if AlphaBlendValue = FOpacityTarget then
      tmrFade.Enabled := False;
  end
  else if AlphaBlendValue > FOpacityTarget then
  begin
    AlphaBlendValue := Max(AlphaBlendValue - 20, FOpacityTarget);
    if AlphaBlendValue = 0 then
    begin
      tmrFade.Enabled := False;
      Hide;

      // ⬇️ NEU: sofort den nächsten Toast starten (falls in Queue),
      //        statt die restliche Zeit der 60s abzuwarten
      TThread.Queue(nil,
        procedure
        begin
          WakeHiddenU.AdvanceNowDueToUserAction;
        end);
    end;
  end
  else
    tmrFade.Enabled := False;
end;

procedure TFormToastF.btnCloseClick(Sender: TObject);
begin
  StartFadeOut; // danach übernimmt tmrFadeTimer das Weiterketteln
end;

procedure TFormToastF.btnSnoozeClick(Sender: TObject);
begin
  if TButton(Sender).Name = 'btnSnooze5' then WakeHiddenU.DoSnooze(5)
  else if TButton(Sender).Name = 'btnSnooze15' then WakeHiddenU.DoSnooze(15)
  else if TButton(Sender).Name = 'btnSnooze60' then WakeHiddenU.DoSnooze(60);

  StartFadeOut; // KEIN Close, kein Advance hier
end;

end.
