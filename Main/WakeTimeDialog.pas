unit WakeTimeDialog;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  System.DateUtils, System.IOUtils, System.JSON, Vcl.Graphics, Winapi.Windows, Winapi.Messages;  // ← IOUtils/JSON hinzu

  function AllowSetForegroundWindow(dwProcessId: DWORD): BOOL; stdcall;
  external user32 name 'AllowSetForegroundWindow';
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
    procedure FormCreate(Sender: TObject); // <-- neu    procedure ForceActivate;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnPlus1hClick(Sender: TObject);
    procedure BtnMorgenClick(Sender: TObject);
    procedure BtnWochenendeClick(Sender: TObject);
    procedure BtnJetztClick(Sender: TObject);
    procedure BtnPlus1dClick(Sender: TObject);
    procedure dtWakeTimeKeyPress(Sender: TObject; var Key: Char);
  private
    lblPrevHint: TLabel;      // ← dynamisches Label
    FLoadedFromLast: Boolean;
    FTopMostTimer: TTimer;
    procedure TopMostTimerTick(Sender: TObject);
    procedure ForceToForeground;
  public
    class function Execute(out selectedTime: TDateTime): Boolean;
  end;

var
  frmWakeTimeDialog: TfrmWakeTimeDialog;

implementation

{$R *.dfm}

uses LastWakeStore;

procedure TfrmWakeTimeDialog.FormCreate(Sender: TObject);
begin
  FTopMostTimer := TTimer.Create(Self);
  FTopMostTimer.Enabled := False;
  FTopMostTimer.Interval := 150;   // 100–200 ms
  FTopMostTimer.OnTimer := TopMostTimerTick;
end;

procedure TfrmWakeTimeDialog.FormShow(Sender: TObject);
var
  lastWake: TDateTime;
begin
  // Grund-Default
  DTWakeTime.DateTime := IncMinute(Now, 1);

  // Vorbelegung aus letzter Eingabe – defensiv, falls Funktion nicht vorhanden
  try
    if LoadLastWakeTime(lastWake) then
    begin
      DTWakeTime.DateTime := lastWake;
      if Assigned(lblPrompt) then
        lblPrompt.Caption := 'Letzte Eingabe übernommen: ' + FormatDateTime('dd.mm.yyyy hh:nn', lastWake);
    end
    else if Assigned(lblPrompt) then
      lblPrompt.Caption := 'Bitte Weckzeit auswählen:';
  except
    on E: Exception do
      if Assigned(lblPrompt) then
        lblPrompt.Caption := 'Bitte Weckzeit auswählen:';
  end;

  // Fenster nach vorne + Fokus
  ForceToForeground;
end;

procedure TfrmWakeTimeDialog.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FTopMostTimer <> nil then
    FTopMostTimer.Enabled := False;
  SetWindowPos(Handle, HWND_NOTOPMOST, 0,0,0,0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
end;

procedure TfrmWakeTimeDialog.ForceToForeground;
var
  fg: HWND;
  fgThread, curThread: DWORD;
begin
  // optional: Erlaubnis fürs Vordergrundfenster (harmlos, wenn’s nicht nötig ist)
  AllowSetForegroundWindow($FFFFFFFF); // ASFW_ANY

  fg := GetForegroundWindow;
  curThread := GetCurrentThreadId;

  if fg <> 0 then
  begin
    fgThread := GetWindowThreadProcessId(fg, nil);
    AttachThreadInput(curThread, fgThread, True);
    try
      ShowWindow(Handle, SW_SHOWNORMAL);
      SetWindowPos(Handle, HWND_TOPMOST, 0,0,0,0, SWP_NOMOVE or SWP_NOSIZE or SWP_SHOWWINDOW);
      BringWindowToTop(Handle);
      SetForegroundWindow(Handle);
      SetActiveWindow(Handle);
      // Fokus auf das Eingabecontrol legen
      if Assigned(DTWakeTime) and DTWakeTime.CanFocus then
        DTWakeTime.SetFocus;
    finally
      AttachThreadInput(curThread, fgThread, False);
    end;
  end
  else
  begin
    ShowWindow(Handle, SW_SHOWNORMAL);
    SetWindowPos(Handle, HWND_TOPMOST, 0,0,0,0, SWP_NOMOVE or SWP_NOSIZE or SWP_SHOWWINDOW);
    BringWindowToTop(Handle);
    SetForegroundWindow(Handle);
    SetActiveWindow(Handle);
    if Assigned(DTWakeTime) and DTWakeTime.CanFocus then
      DTWakeTime.SetFocus;
  end;

  // Nach kurzer Zeit TopMost wieder entfernen (siehe Timer)
  FTopMostTimer.Enabled := True;
end;

procedure TfrmWakeTimeDialog.TopMostTimerTick(Sender: TObject);
begin
  FTopMostTimer.Enabled := False;
  SetWindowPos(Handle, HWND_NOTOPMOST, 0,0,0,0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
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
  else if (Key = '-') then
  begin
    DTWakeTime.DateTime := IncMinute(DTWakeTime.DateTime, -1);
    Key := #0;
  end
  else if (Key = '*') then
  begin
    DTWakeTime.DateTime := IncMinute(DTWakeTime.DateTime, 15);
    Key := #0;
  end
  else if (Key = '/') then
  begin
    DTWakeTime.DateTime := IncMinute(DTWakeTime.DateTime, -15);
    Key := #0;
  end
  else if (UpCase(Key) = 'J') then
  begin
    DTWakeTime.DateTime := Now;
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
    begin
      selectedTime := dlg.DTWakeTime.DateTime;
      SaveLastWakeTime(selectedTime); // für nächste Dialoge/Follower merken
    end;
  finally
    dlg.Free;
  end;
end;

end.
