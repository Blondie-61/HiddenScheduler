unit WakeTimeDialog;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  System.DateUtils;

type
  TfrmWakeTimeDialog = class(TForm)
    lblPrompt: TLabel;
    DTWakeTime: TDateTimePicker;
    BtnOK: TButton;
    BtnCancel: TButton;
    BtnPlus1h: TButton;
    BtnMorgen: TButton;
    BtnWochenende: TButton;
    BtnJetzt: TButton;
    BtnPlus1d: TButton;
    procedure FormShow(Sender: TObject);
    procedure BtnPlus1hClick(Sender: TObject);
    procedure BtnMorgenClick(Sender: TObject);
    procedure BtnWochenendeClick(Sender: TObject);
    procedure BtnJetztClick(Sender: TObject);
    procedure BtnPlus1dClick(Sender: TObject);
    procedure dtWakeTimeKeyPress(Sender: TObject; var Key: Char);
  private

  public
//    class function Execute(out selectedTime: TDateTime): Boolean;
    class function Execute(out selectedTime: TDateTime): Boolean; overload;
    class function Execute(out selectedTime: TDateTime; out autoHideAfter: Integer): Boolean; overload;
  end;

var
  frmWakeTimeDialog: TfrmWakeTimeDialog;

implementation

{$R *.dfm}

procedure TfrmWakeTimeDialog.FormShow(Sender: TObject);
begin
  //btnJetzt.Click;
  DTWakeTime.DateTime := IncMinute(Now(), 1);
end;

procedure TfrmWakeTimeDialog.BtnPlus1hClick(Sender: TObject);
begin
  DTWakeTime.DateTime := DTWakeTime.DateTime + EncodeTime(1, 0, 0, 0);
end;

procedure TfrmWakeTimeDialog.BtnMorgenClick(Sender: TObject);
var
  dt: TDateTime;
  i: Integer;
begin
  dt := Now;
  for i := 1 to 7 do
  begin
    dt := IncDay(Now, i);
    if DayOfWeek(dt) = 7 then
    begin
      dt := RecodeDateTime(dt, YearOf(dt), MonthOf(dt), DayOf(dt), 14, 0, 0, 0);
      Break;
    end;
  end;

  DTWakeTime.DateTime := dt;
end;

procedure TfrmWakeTimeDialog.BtnWochenendeClick(Sender: TObject);
var
  dt: TDateTime;
begin
  dt := Now;
  while DayOfWeek(dt) <> 2 do // 2 = Montag
    dt := IncDay(dt);
  dt := RecodeDateTime(dt, YearOf(dt), MonthOf(dt), DayOf(dt), 8, 0, 0, 0);
  DTWakeTime.DateTime := dt;
end;

procedure TfrmWakeTimeDialog.BtnJetztClick(Sender: TObject);
var
  dt: TDateTime;
  hour, min: Word;
begin
  dt := Now;
  hour := HourOf(dt);
  min := MinuteOf(dt);

  if min > 0 then
    Inc(hour);

  if hour >= 24 then
  begin
    dt := IncDay(StartOfTheDay(dt), 1);
    hour := 0;
  end
  else
    dt := StartOfTheDay(dt);

  dt := dt + EncodeTime(hour, 0, 0, 0);
  DTWakeTime.DateTime := dt;
end;

procedure TfrmWakeTimeDialog.BtnPlus1dClick(Sender: TObject);
begin
  DTWakeTime.DateTime := DTWakeTime.DateTime + 1;
end;

procedure TfrmWakeTimeDialog.dtWakeTimeKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = '+') then
  begin
    DTWakeTime.DateTime := IncMinute(DTWakeTime.DateTime, 1);
    Key := #0;
  end
  else
  if (Key = '-') then
  begin
    DTWakeTime.DateTime := IncMinute(DTWakeTime.DateTime, (- 1));
    Key := #0;
  end
  else
    if (Key = '*') then
  begin
    DTWakeTime.DateTime := IncMinute(DTWakeTime.DateTime, 15);
    Key := #0;
  end
  else
  if (Key = '/') then
  begin
    DTWakeTime.DateTime := IncMinute(DTWakeTime.DateTime, (- 15));
    Key := #0;
  end
  else
  if (Uppercase(Key) = 'J') then
  begin
    DTWakeTime.DateTime := Now();
    Key := #0;
  end;
end;

class function TfrmWakeTimeDialog.Execute(out selectedTime: TDateTime): Boolean;
var
  dlg: TfrmWakeTimeDialog;
begin
  dlg := TfrmWakeTimeDialog.Create(nil);
  try
    Result := (dlg.ShowModal = mrOk);
    if Result then
      selectedTime := Dlg.DTWakeTime.DateTime;
  finally
    dlg.Free;
  end;
end;

// Neue Overload-Variante mit AutoHideAfter
class function TfrmWakeTimeDialog.Execute(out selectedTime: TDateTime; out autoHideAfter: Integer): Boolean;
begin
  autoHideAfter := 0; // Standardwert, bis Feature genutzt wird
  Result := Execute(selectedTime); // Ruft die bestehende Version auf
end;

end.
