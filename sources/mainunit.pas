unit mainunit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.VCLUI.Wait, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.DataSet, Vcl.Grids, Vcl.ComCtrls,
  Vcl.Imaging.pngimage, Vcl.ExtCtrls;

type
  TMainform = class(TForm)
    MainMenu1: TMainMenu;
    Application1: TMenuItem;
    Config1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    View1: TMenuItem;
    VScreen1: TMenuItem;
    MiniScreen1: TMenuItem;
    Media1: TMenuItem;
    Locate1: TMenuItem;
    AddFolder1: TMenuItem;
    Radio1: TMenuItem;
    VideoPlayer1: TMenuItem;
    MediaPlayer1: TMenuItem;
    AudioStreams1: TMenuItem;
    ImportfromCDDVD1: TMenuItem;
    CDPlayer1: TMenuItem;
    DB1: TFDConnection;
    FDQuery1: TFDQuery;
    PageControl1: TPageControl;
    TabAlbums: TTabSheet;
    TabMusicFiles: TTabSheet;
    TabRadio: TTabSheet;
    DrawGrid1: TDrawGrid;
    DrawGrid2: TDrawGrid;
    DrawGrid3: TDrawGrid;
    Panel1: TPanel;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    procedure Config1Click(Sender: TObject);
    procedure AddFolder1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Mainform: TMainform;

const
  SELDIRHELP = 1000;

implementation

{$R *.dfm}

uses configdlg, FileCtrl,MediaFilesFunctions, MediaTypes,SQLiteFunctions,
   bass;

procedure TMainform.AddFolder1Click(Sender: TObject);
var Dir: string;
begin
    Dir := 'C:\';
    if FileCtrl.SelectDirectory(Dir, [sdAllowCreate, sdPerformCreate, sdPrompt],
       SELDIRHELP) then
     begin
      ScanFolder(Dir);
     end;
end;

procedure TMainform.Config1Click(Sender: TObject);
begin
      ConfigDialog.Execute;
end;

procedure TMainform.FormCreate(Sender: TObject);
var Needs2Create:boolean;
const
  DBName = 'c:\databases\jukebox.db';
begin

    if not BASS_Init(0,44100,0,Application.Handle,nil) then
      ShowMessage('Can''t initialize device');

    Needs2Create:=not FileExists(DBName);

    DB1.Params.Values['database'] := DBName;
    DB1.Connected:= True;

    if Needs2Create then
     begin
       CreateSQLiteDB(DB1);

     end;

end;

procedure TMainform.FormDestroy(Sender: TObject);
begin
    Bass_Free();
end;

end.
