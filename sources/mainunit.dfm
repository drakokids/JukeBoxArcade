object Mainform: TMainform
  Left = 0
  Top = 0
  Caption = 'JukeBox Arcade Beta'
  ClientHeight = 650
  ClientWidth = 842
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu1
  OnCreate = FormCreate
  TextHeight = 15
  object MainMenu1: TMainMenu
    Left = 56
    Top = 128
    object Application1: TMenuItem
      Caption = 'Application'
      object Config1: TMenuItem
        Caption = 'Config'
        OnClick = Config1Click
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        Caption = 'Exit'
      end
    end
    object View1: TMenuItem
      Caption = 'View'
      object VScreen1: TMenuItem
        Caption = 'TV Screen'
      end
      object MiniScreen1: TMenuItem
        Caption = 'Mini Screen'
      end
      object Radio1: TMenuItem
        Caption = 'Radio'
      end
      object VideoPlayer1: TMenuItem
        Caption = 'Video Player'
      end
      object MediaPlayer1: TMenuItem
        Caption = 'Media Player'
      end
    end
    object Media1: TMenuItem
      Caption = 'Media'
      object Locate1: TMenuItem
        Caption = 'Locate'
      end
      object AddFolder1: TMenuItem
        Caption = 'Add Folder'
        OnClick = AddFolder1Click
      end
      object AudioStreams1: TMenuItem
        Caption = 'Audio Streams'
      end
      object ImportfromCDDVD1: TMenuItem
        Caption = 'Import from CD/DVD'
      end
      object CDPlayer1: TMenuItem
        Caption = 'CD Player'
      end
    end
  end
  object DB1: TFDConnection
    Params.Strings = (
      'DriverID=SQLite')
    Left = 224
    Top = 56
  end
end
