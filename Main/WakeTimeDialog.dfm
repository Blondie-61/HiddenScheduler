object frmWakeTimeDialog: TfrmWakeTimeDialog
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Aufweckzeit festlegen'
  ClientHeight = 373
  ClientWidth = 660
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -22
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 192
  TextHeight = 30
  object lblPrompt: TLabel
    Left = 32
    Top = 32
    Width = 321
    Height = 30
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = 'Bitte Aufweckzeitpunkt festlegen:'
  end
  object dtWakeTime: TDateTimePicker
    Left = 40
    Top = 74
    Width = 380
    Height = 38
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Date = 45263.000000000000000000
    Time = 0.500000000000000000
    Kind = dtkDateTime
    TabOrder = 0
    OnKeyPress = dtWakeTimeKeyPress
  end
  object btnPlus1h: TButton
    Left = 40
    Top = 144
    Width = 180
    Height = 50
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = '+1 Stunde'
    TabOrder = 1
    OnClick = btnPlus1hClick
  end
  object btnMorgen: TButton
    Left = 232
    Top = 144
    Width = 180
    Height = 50
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = 'Sa 14:00'
    TabOrder = 3
    OnClick = btnMorgenClick
  end
  object btnWochenende: TButton
    Left = 432
    Top = 144
    Width = 180
    Height = 50
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = 'Mo 08:00'
    TabOrder = 4
    OnClick = btnWochenendeClick
  end
  object btnOK: TButton
    Left = 290
    Top = 304
    Width = 150
    Height = 50
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 5
  end
  object btnCancel: TButton
    Left = 462
    Top = 304
    Width = 150
    Height = 50
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Cancel = True
    Caption = 'Abbrechen'
    ModalResult = 2
    TabOrder = 6
  end
  object BtnJetzt: TButton
    Left = 432
    Top = 70
    Width = 180
    Height = 50
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = 'Jetzt'
    TabOrder = 2
    OnClick = BtnJetztClick
  end
  object BtnPlus1d: TButton
    Left = 40
    Top = 224
    Width = 180
    Height = 50
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = '+1 Tag'
    TabOrder = 7
    OnClick = BtnPlus1dClick
  end
end
