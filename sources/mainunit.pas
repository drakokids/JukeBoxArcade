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
  Vcl.Imaging.pngimage, Vcl.ExtCtrls, MediaTypes;

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
    GridRadios: TDrawGrid;
    Panel1: TPanel;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    procedure Config1Click(Sender: TObject);
    procedure AddFolder1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Image4Click(Sender: TObject);
    procedure GridRadiosDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Image1Click(Sender: TObject);
    procedure Image2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Mainform: TMainform;
  AppFolder,IconsFolder,DBName: string;
  AllRadios: array of TRadioInfo;
  AllAuthors: array of TAuthorInfo;
  AllBands: array of TBandInfo;
  AllAlbums: array of TAlbumInfo;
  AllMedia: array of TMediaInfo;
  AllVideos: array of TVideoInfo;
  AllCovers: array of TBitmap;
  channel: integer; //Bass Channel

const
  SELDIRHELP = 1000;
  WM_INFO_UPDATE = WM_USER + 101;

implementation

{$R *.dfm}

uses configdlg, FileCtrl,MediaFilesFunctions,SQLiteFunctions,
   bass, apifunctions, inifiles, EnhGraphicLib;


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

procedure TMainform.GridRadiosDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var image: TPicture;
    extension: string;
    bmp1,bmp2: TBitmap;
begin
  if ARow=0 then
   begin
    if ACol=0 then GridRadios.Canvas.Textout(Rect.left+1,1,'Icon');
    if ACol=1 then GridRadios.Canvas.Textout(Rect.left+1,1,'Radio');
    if ACol=2 then GridRadios.Canvas.Textout(Rect.left+1,1,'Country');
    if ACol=3 then GridRadios.Canvas.Textout(Rect.left+1,1,'Bitrate');
    end
   else
    begin
     if Acol=0 then begin
                     if (AllRadios[ARow-1].coverid>=0) then
                      begin
                         GridRadios.Canvas.Draw(Rect.left,Rect.top,AllCovers[AllRadios[ARow-1].coverid]);
                      end;
                    end;

     if ACol=1 then GridRadios.Canvas.Textout(Rect.left+1,Rect.top+1,
                               DecodeString(AllRadios[ARow-1].Name));
     if ACol=2 then GridRadios.Canvas.Textout(Rect.left+1,Rect.top+1,
                               AllRadios[ARow-1].countrycode);
     if ACol=3 then GridRadios.Canvas.Textout(Rect.left+1,Rect.top+1,
                               AllRadios[ARow-1].bitrate);
    end;

end;

procedure TMainform.FormClose(Sender: TObject; var Action: TCloseAction);
var i: integer;
begin
    for i := 0 to length(AllCovers)-1 do
     AllCovers[i].Free;
end;

procedure TMainform.FormCreate(Sender: TObject);
var Needs2Create:boolean;
    myini: TInifile;
begin

    AppFolder:=Extractfilepath(application.ExeName);

    myini:=TInifile.Create(AppFolder+'\config.ini');
    IconsFolder:=myini.ReadString('MAIN','mediafolder','')+'\icons';
    DBName:=myini.ReadString('MAIN','database','');
    myini.Free;

    if not BASS_Init(0,44100,0,Application.Handle,nil) then
      ShowMessage('Can''t initialize device');

    BASS_SetConfigPtr(BASS_CONFIG_NET_PROXY, nil); // disable proxy
    BASS_SetConfig(BASS_CONFIG_NET_PLAYLIST, 1); // enable playlist processing
  BASS_SetConfig(BASS_CONFIG_NET_PREBUF, 0); // minimize automatic pre-buffering, so we can do it (and display it) instead

    Needs2Create:=not FileExists(DBName);

    DB1.Params.Values['database'] := DBName;
    DB1.Connected:= True;

    if Needs2Create then
     begin
       CreateSQLiteDB(DB1);

     end;

    GridRadios.DefaultRowHeight:=130;
    GridRadios.RowHeights[0]:=32;
    GridRadios.ColWidths[0]:=130;
    GridRadios.ColWidths[1]:=400;

    LoadAllRadios;
    

end;

procedure TMainform.FormDestroy(Sender: TObject);
begin
    Bass_Free();
end;

procedure TMainform.Image1Click(Sender: TObject);
var icy: PAnsiChar;
    Len, Progress: DWORD;
begin
  BASS_StreamFree(channel); // close old stream
  BASS_StreamCreateURL('http://www.radioparadise.com/m3u/mp3-128.m3u', 0,
                   BASS_STREAM_BLOCK or BASS_STREAM_AUTOFREE, nil, 0);
  if channel <> 0 then
    BASS_ChannelPlay(channel, false);
end;

procedure TMainform.Image2Click(Sender: TObject);
begin
if channel <> 0 then
    BASS_ChannelStop(channel);
end;

procedure TMainform.Image4Click(Sender: TObject);
begin
  updateRadioStations('PT','','128','');
  LoadAllRadios;
end;

end.
