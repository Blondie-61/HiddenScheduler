object FormToastF: TFormToastF
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'FormToastF'
  ClientHeight = 294
  ClientWidth = 942
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -24
  Font.Name = 'Segoe UI'
  Font.Style = []
  FormStyle = fsStayOnTop
  Position = poDesigned
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 192
  TextHeight = 32
  object lblTitle: TLabel
    Left = 48
    Top = 48
    Width = 96
    Height = 45
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = 'lblTitle'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object lblMsg: TLabel
    Left = 48
    Top = 105
    Width = 81
    Height = 37
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = 'lblMsg'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object btnClose: TButton
    Left = 688
    Top = 192
    Width = 150
    Height = 50
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = 'Schlie'#223'en'
    TabOrder = 3
    OnClick = btnCloseClick
  end
  object btnSnooze5: TButton
    Left = 48
    Top = 192
    Width = 150
    Height = 50
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = '5 Min'
    TabOrder = 0
    OnClick = btnSnoozeClick
  end
  object btnSnooze15: TButton
    Left = 210
    Top = 192
    Width = 150
    Height = 50
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = '15 Min'
    TabOrder = 1
    OnClick = btnSnoozeClick
  end
  object btnSnooze60: TButton
    Left = 372
    Top = 192
    Width = 150
    Height = 50
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = '60 Min'
    TabOrder = 2
    OnClick = btnSnoozeClick
  end
  object tmrLife: TTimer
    Enabled = False
    OnTimer = tmrLifeTimer
    Left = 416
    Top = 64
  end
  object tmrFade: TTimer
    Enabled = False
    OnTimer = tmrFadeTimer
    Left = 528
    Top = 64
  end
end
