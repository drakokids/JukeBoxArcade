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
  Vcl.Imaging.pngimage, Vcl.ExtCtrls, MediaTypes, bass,mmsystem;

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
    StatusBar1: TStatusBar;
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
    procedure WndProc(var Msg: TMessage);
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
  //For BASS
  cthread: DWORD = 0;
  chan: HSTREAM = 0;
  win: hwnd;
  req: DWORD = 0; // request number/counter
  FTimerId: DWORD = 0;
  icy: PAnsiChar = nil;
  progress: integer = 0;

const
  SELDIRHELP = 1000;
  WM_INFO_UPDATE = WM_USER + 101;
  // HLS definitions (copied from BASSHLS.pas)
  BASS_SYNC_HLS_SEGMENT = $10300;
  BASS_TAG_HLS_EXTINF = $14000;

implementation

{$R *.dfm}

uses configdlg, FileCtrl,MediaFilesFunctions,SQLiteFunctions,
   apifunctions, inifiles, EnhGraphicLib,functions;

procedure Error(es: string);
begin
  logwrite('Error '+es);
  MessageBox(win, PChar(es + #13#10 + '(error code: ' + IntToStr(BASS_ErrorGetCode) + ')'), nil, 0);
end;

{ update stream title from metadata }

procedure DoMeta();
var
  meta: PAnsiChar;
  Artist, Title: string;
  p, p1, p2: integer;
begin
  logwrite('Dometa()');
  meta := BASS_ChannelGetTags(chan, BASS_TAG_META);
  if (meta <> nil) then
  begin
    // got Shoutcast metadata
    logwrite('StreamTitle='+String(AnsiString(meta)));
    p := Pos('StreamTitle=', String(AnsiString(meta)));
    if (p = 0) then
      Exit;
    p := p + 13;
    SendMessage(win, WM_INFO_UPDATE, 7, DWORD(PAnsiChar(AnsiString(Copy(meta, p, Pos(';', String(meta)) - p - 1)))));
    meta := nil;
  end
  else
    meta := BASS_ChannelGetTags(chan, BASS_TAG_OGG);
  if meta <> nil then
  begin
    // got Icecast/OGG tags
    p1 := Pos('artist=', string(meta));
    p2 := Pos('title=', string(meta));
    if p1 > 0 then
      Artist := Copy(string(meta), p1 + 7, Length(string(meta)));
    if p2 > 0 then
      Title := Copy(string(meta), p2 + 6, Length(string(meta)));
    if p1 > 0 then
      SendMessage(win, WM_INFO_UPDATE, 7, DWORD(PAnsiChar(AnsiString(Format('%s - %s', [Artist, Title])))))
    else
      SendMessage(win, WM_INFO_UPDATE, 7, DWORD(PAnsiChar(AnsiString(Format('%s', [Title])))));
  end
  else
  begin
    meta := BASS_ChannelGetTags(chan, BASS_TAG_HLS_EXTINF);
    if meta <> '' then
    begin
      // got HLS segment info
      SendMessage(win, WM_INFO_UPDATE, 7,
        DWORD(PAnsiChar((Copy(meta, Pos(',', string(meta)) + 1, Length(string(meta)))))));
    end;
  end;
end;

procedure MetaSync(handle: HSYNC; channel, data: DWORD; user: Pointer); stdcall;
begin
  DoMeta();
end;

procedure StatusProc(buffer: Pointer; len: DWORD; user: Pointer); stdcall;
begin
  if (buffer <> nil) and (len = 0) and (DWORD(user) = req) then
    SendMessage(win, WM_INFO_UPDATE, 8, DWORD(PAnsiChar(buffer)));
end;

procedure StallSync(handle: HSYNC; channel, data: DWORD; user: Pointer); stdcall;
begin
  if (data = 0) then // stalled
    FTimerId := SetTimer(win, 0, 50, nil); // start buffer monitoring
end;

procedure EndSync(handle: HSYNC; channel, data: DWORD; user: Pointer); stdcall;
begin
  KillTimer(win, FTimerId); // stop buffer monitoring
  SendMessage(win, WM_INFO_UPDATE, 1, 0); // reset Labels
end;

function OpenURL(url: PWideChar): integer;
var
  R: DWORD;
  C: HSTREAM;
  FLock: TRtlCriticalSection;
begin
  Result := 0;
  InitializeCriticalSection(FLock);
  EnterCriticalSection(FLock); // make sure only 1 thread at a time can do the following
  try
    inc(req);
    R := req;
  finally
    LeaveCriticalSection(FLock);
  end;

  KillTimer(win, FTimerId);
  BASS_StreamFree(chan); // close old stream

  SendMessage(win, WM_INFO_UPDATE, 0, 0); // reset the Labels and trying connecting

  //
  C := BASS_StreamCreateURL(url, 0, BASS_STREAM_BLOCK or BASS_STREAM_STATUS or BASS_STREAM_AUTOFREE or BASS_UNICODE,
    @StatusProc, Pointer(R));

  EnterCriticalSection(FLock);
  try
    if (R <> req) then
    begin // there is a newer request, discard this stream
      LeaveCriticalSection(FLock);
      DeleteCriticalSection(FLock);
      if C <> 0 then
        BASS_StreamFree(C);
      Exit;
    end;
    chan := C; // this is now the current stream
  finally
    LeaveCriticalSection(FLock);
    DeleteCriticalSection(FLock);
  end;
  if (chan = 0) then
  begin
    // lets catch the error here inside the Thread and send it to the WndProc
    SendMessage(win, WM_INFO_UPDATE, 1, BASS_ErrorGetCode()); // Oops Error
  end
  else
  begin

    FTimerId := SetTimer(win, 0, 25, nil);
  end;
  BASS_ChannelSetSync(chan, BASS_SYNC_META, 0, MetaSync, nil); // Shoutcast
  BASS_ChannelSetSync(chan, BASS_SYNC_OGG_CHANGE, 0, MetaSync, nil); // Vorbis/OGG
  BASS_ChannelSetSync(chan, BASS_SYNC_HLS_SEGMENT, 0, MetaSync, nil); // HLS
  // set sync for stalling/buffering
  BASS_ChannelSetSync(chan, BASS_SYNC_STALL, 0, StallSync, nil);
  // set sync for end of stream
  BASS_ChannelSetSync(chan, BASS_SYNC_END, 0, EndSync, nil);
  // play it!
  BASS_ChannelPlay(chan, FALSE);

  cthread := 0;
end;

procedure TMainform.WndProc(var Msg: TMessage);
// to be threadsave we are passing all Canvas Stuff(e.g. Labels) to this messages
begin
  inherited;
  case Msg.Msg of
    WM_TIMER:
      begin
        // Display Tags
        if (BASS_ChannelIsActive(chan) = BASS_ACTIVE_PLAYING) then
        begin
          KillTimer(win, FTimerId); // finished buffering, stop monitoring
          // get the broadcast name and bitrate
          icy := BASS_ChannelGetTags(chan, BASS_TAG_ICY);
          if (icy = nil) then
            icy := BASS_ChannelGetTags(chan, BASS_TAG_HTTP); // no ICY tags, try HTTP
          if (icy <> nil) then
            while (icy^ <> #0) do
            begin
              if (Copy(icy, 1, 9) = 'icy-name:') then
                SendMessage(win, WM_INFO_UPDATE, 3, DWORD(PAnsiChar(Copy(icy, 10, MaxInt))))
              else if (Copy(icy, 1, 7) = 'icy-br:') then
                SendMessage(win, WM_INFO_UPDATE, 4, DWORD(PAnsiChar('bitrate: ' + Copy(icy, 8, MaxInt))));
              icy := icy + Length(icy) + 1;
            end;
          // get the stream title and set sync for subsequent titles
          DoMeta();
        end
        else
        begin
          // monitor buffering progress
          if BASS_StreamGetFilePosition(chan, BASS_FILEPOS_BUFFERING) > 0 then
          // this check will prevent that the Buffer display do not start with 100
             SendMessage(win, WM_INFO_UPDATE, 2,(100 - (integer(BASS_StreamGetFilePosition(chan, BASS_FILEPOS_BUFFERING)))));
          // show the Progess value in the label
        end;
      end;
    WM_INFO_UPDATE:
      begin
        case Msg.WParam of
          0:
            begin
              logwrite('Connecting');
              StatusBar1.Panels[0].Text := 'connecting...';
              StatusBar1.Panels[1].Text := '';
              StatusBar1.Panels[2].Text := '';
            end;
          1:
            begin
              StatusBar1.Panels[0].Text := 'not playing';
              logwrite('Can''t play the stream');
              Error('Can''t play the stream');
            end;
          2:
            begin
             StatusBar1.Panels[0].Text := Format('buffering... %d%%', [Msg.LParam]);
             logwrite('Buffering');
            end;
          3:
            StatusBar1.Panels[0].Text := String(PAnsiChar(Msg.LParam));
          4:
            StatusBar1.Panels[2].Text := String(PAnsiChar(Msg.LParam));
          5:
            StatusBar1.Panels[2].Text := String(PAnsiChar(Msg.LParam));
          6:
            StatusBar1.Panels[1].Text := String(PAnsiChar(Msg.LParam));
          7:
            StatusBar1.Panels[1].Text := String(PAnsiChar(Msg.LParam));
          8:
            StatusBar1.Panels[2].Text := String(PAnsiChar(Msg.LParam));
        end;
      end;
  end;
end;


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
    if ACol=0 then GridRadios.Canvas.Textout(Rect.left+1,1,'');
    if ACol=1 then GridRadios.Canvas.Textout(Rect.left+1,1,'Icon');
    if ACol=2 then GridRadios.Canvas.Textout(Rect.left+1,1,'Radio');
    if ACol=3 then GridRadios.Canvas.Textout(Rect.left+1,1,'Country');
    if ACol=4 then GridRadios.Canvas.Textout(Rect.left+1,1,'Bitrate');
    end
   else
    begin
     if Acol=0 then
      if GridRadios.Row=ARow then
       begin
         GridRadios.Canvas.Textout(Rect.left+1,Rect.top+10,'>');
       end
      else
       GridRadios.Canvas.Textout(Rect.left+1,Rect.top+10,'   ');

     if Acol=1 then begin
                     if (AllRadios[ARow-1].coverid>=0) then
                      begin
                         GridRadios.Canvas.Draw(Rect.left,Rect.top,AllCovers[AllRadios[ARow-1].coverid]);
                      end;
                    end;

     if ACol=2 then GridRadios.Canvas.Textout(Rect.left+1,Rect.top+1,
                               DecodeString(AllRadios[ARow-1].Name));
     if ACol=3 then GridRadios.Canvas.Textout(Rect.left+1,Rect.top+1,
                               AllRadios[ARow-1].countrycode);
     if ACol=4 then GridRadios.Canvas.Textout(Rect.left+1,Rect.top+1,
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
    win := handle;
    AppFolder:=Extractfilepath(application.ExeName);

    myini:=TInifile.Create(AppFolder+'\config.ini');
    IconsFolder:=myini.ReadString('MAIN','mediafolder','')+'\icons';
    DBName:=myini.ReadString('MAIN','database','');
    myini.Free;

    if (HIWORD(BASS_GetVersion) <> BASSVERSION) then
      begin
        MessageBox(0, 'An incorrect version of BASS.DLL was loaded', nil, MB_ICONERROR);
        Halt;
      end;
    if not BASS_Init(-1,44100,0,Handle,nil) then
      ShowMessage('Can''t initialize device');

    BASS_SetConfig(BASS_CONFIG_NET_PLAYLIST, 1); // enable playlist processing
    BASS_PluginLoad('bass_aac.dll', BASS_Unicode); // load BASS_AAC (if present) for AAC support on older Windows
    BASS_PluginLoad('bassflac.dll', BASS_Unicode); // load BASSFLAC (if present) for FLAC support
    BASS_PluginLoad('basshls.dll', BASS_Unicode); // load BASSHLS (if present) for HLS support


    Needs2Create:=not FileExists(DBName);

    DB1.Params.Values['database'] := DBName;
    DB1.Connected:= True;

    if Needs2Create then
     begin
       CreateSQLiteDB(DB1);

     end;

    GridRadios.DefaultRowHeight:=130;
    GridRadios.RowHeights[0]:=32;
    GridRadios.ColWidths[0]:=32;
    GridRadios.ColWidths[1]:=130;
    GridRadios.ColWidths[2]:=400;

    LoadAllRadios;
    

end;

procedure TMainform.FormDestroy(Sender: TObject);
begin
    Bass_Free();
end;

procedure TMainform.Image1Click(Sender: TObject);
var
  ThreadId: Cardinal;
begin

  if (cthread <> 0) then
    MessageBeep(0)
  else
  begin
      BASS_SetConfigPtr(BASS_CONFIG_NET_PROXY, nil); // disable proxy
    // open URL in a new thread (so that main thread is free)
      cthread := BeginThread(nil, 0, @OpenURL,
          PWideChar(AllRadios[GridRadios.Row-1].url), 0, ThreadId)
   end;

end;

procedure TMainform.Image2Click(Sender: TObject);
begin
  KillTimer(win, FTimerId);
  BASS_StreamFree(chan); // close old stream

  SendMessage(win, WM_INFO_UPDATE, 0, 0); // reset the Labels and trying connecting
end;

procedure TMainform.Image4Click(Sender: TObject);
begin
  updateRadioStations('PT','','128','');
  LoadAllRadios;
end;

end.
