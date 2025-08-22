object frmUpdaterDownload: TfrmUpdaterDownload
  Left = 200
  Top = 150
  BorderStyle = bsDialog
  Caption = 'Update herunterladen'
  ClientHeight = 440
  ClientWidth = 840
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -22
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 192
  TextHeight = 30
  object lblTitle: TLabel
    Left = 32
    Top = 24
    Width = 86
    Height = 30
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = 'Updater'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -22
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblStatus: TLabel
    Left = 32
    Top = 300
    Width = 6
    Height = 30
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
  end
  object edtUrl: TEdit
    Left = 32
    Top = 90
    Width = 760
    Height = 38
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    TabOrder = 0
  end
  object edtFolder: TEdit
    Left = 32
    Top = 144
    Width = 600
    Height = 38
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    TabOrder = 1
  end
  object btnBrowse: TButton
    Left = 644
    Top = 140
    Width = 150
    Height = 50
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = '...'
    TabOrder = 2
    OnClick = btnBrowseClick
  end
  object pb: TProgressBar
    Left = 32
    Top = 220
    Width = 760
    Height = 40
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    TabOrder = 3
  end
  object btnStart: TButton
    Left = 480
    Top = 360
    Width = 150
    Height = 50
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = 'Start'
    TabOrder = 4
    OnClick = btnStartClick
  end
  object btnCancel: TButton
    Left = 660
    Top = 360
    Width = 150
    Height = 50
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Caption = 'Abbrechen'
    ModalResult = 2
    TabOrder = 5
  end
end
