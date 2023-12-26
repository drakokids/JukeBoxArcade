object Form1: TForm1
  Left = 296
  Top = 167
  BorderStyle = bsSingle
  Caption = 'Asynchronous scan of file system'
  ClientHeight = 425
  ClientWidth = 471
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    471
    425)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 56
    Width = 32
    Height = 13
    Caption = 'Folder:'
  end
  object Label2: TLabel
    Left = 8
    Top = 88
    Width = 92
    Height = 13
    Caption = 'Filter file extentions:'
  end
  object Label3: TLabel
    Left = 8
    Top = 8
    Width = 450
    Height = 33
    AutoSize = False
    Caption = 
      'This demo app shows how the TcbAsyncDirScan object scans asynchr' +
      'onously a directory using a separate thread, meaning the applica' +
      'tion won'#39't freeze while you scan your disk.'
    WordWrap = True
  end
  object Button2: TButton
    Left = 384
    Top = 48
    Width = 75
    Height = 25
    Caption = 'Async Scan'
    TabOrder = 0
    OnClick = Button2Click
  end
  object TreeView1: TTreeView
    Left = 8
    Top = 112
    Width = 273
    Height = 288
    Anchors = [akLeft, akTop, akBottom]
    Indent = 19
    TabOrder = 1
    OnChange = TreeView1Change
  end
  object ListBox1: TListBox
    Left = 288
    Top = 112
    Width = 169
    Height = 288
    Anchors = [akLeft, akTop, akBottom]
    ItemHeight = 13
    TabOrder = 2
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 406
    Width = 471
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object Edit1: TEdit
    Left = 48
    Top = 48
    Width = 281
    Height = 21
    TabOrder = 4
    Text = 'c:\'
  end
  object Button1: TButton
    Left = 336
    Top = 48
    Width = 25
    Height = 25
    Caption = '..'
    TabOrder = 5
    OnClick = Button1Click
  end
  object Button3: TButton
    Left = 384
    Top = 80
    Width = 75
    Height = 25
    Caption = 'Stop'
    TabOrder = 6
    OnClick = Button3Click
  end
  object Edit2: TEdit
    Left = 104
    Top = 80
    Width = 257
    Height = 21
    TabOrder = 7
    Text = '.*'
  end
end
