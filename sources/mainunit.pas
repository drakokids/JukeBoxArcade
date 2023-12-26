unit mainunit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.VCLUI.Wait, Data.DB,
  FireDAC.Comp.Client;

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
    procedure Config1Click(Sender: TObject);
    procedure AddFolder1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
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

uses configdlg, FileCtrl,MediaFilesFunctions;

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

    Needs2Create:=not FileExists(DBName);

    DB1.Params.Values['database'] := DBName;
    DB1.Connected:= True;

    if Needs2Create then
     begin
       DB1.ExecSQL('CREATE TABLE IF NOT EXISTS Singers ('+
       'ID INTEGER ,PRIMARY KEY ("ID" AUTOINCREMENT),'+
       'SingerName TEXT NOT NULL,'+
       'CountryID INTEGER, Sex TEXT, Born DATE, Died DATE'+
       ');');
       DB1.ExecSQL('CREATE TABLE IF NOT EXISTS Albums ('+
        'ID INTEGER ,PRIMARY KEY("ID" AUTOINCREMENT),'+
        'AlbumName TEXT NOT NULL,'+
        'AlbumDate DATE);');
       DB1.ExecSQL('CREATE TABLE IF NOT EXISTS Bands ('+
        'ID INTEGER ,PRIMARY KEY ("ID" AUTOINCREMENT),'+
        'BandName TEXT NOT NULL,'+
        'StartDate TEXT, EndedDate TEXT);');
       DB1.ExecSQL('CREATE TABLE IF NOT EXISTS Musics ('+
        'ID INTEGER ,PRIMARY KEY ("ID" AUTOINCREMENT),'+
        'MusicName TEXT NOT NULL,'+
        'Filename TEXT, Filetype TEXT);');
       DB1.ExecSQL('CREATE TABLE IF NOT EXISTS AlbumBands ('+
        'AlbumID INTEGER, BandID INTEGER)');
       DB1.ExecSQL('CREATE TABLE IF NOT EXISTS AlbumSingers ('+
        'AlbumID INTEGER, SingerID INTEGER)');
       DB1.ExecSQL('CREATE TABLE IF NOT EXISTS AlbumMusics ('+
        'AlbumID INTEGER, MusicID INTEGER)');
       DB1.ExecSQL('CREATE TABLE IF NOT EXISTS RadioStreams ('+
        'ID INTEGER PRIMARY KEY ("ID" AUTOINCREMENT), '+
        'StreamName TEXT, URL TEXT)');
     end;

end;

end.
