unit MiniWindowFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls;

type
  TFormMiniWindow = class(TForm)
    PaintBox1: TPaintBox;
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormMiniWindow: TFormMiniWindow;
  CurrentScene: integer;

const
  MainScene=0;
  ConfigScene=1;
  RadiosBrowseScene=2;
  AlbunsBrowseScene=3;
  RadioPlayScene=4;
  AlbumPlayScene=5;
  CDPlayScene=6;
  CDImportScene=7;



implementation

{$R *.dfm}

procedure TFormMiniWindow.FormShow(Sender: TObject);
begin
  PaintBox1.align:=alclient;
end;

end.
