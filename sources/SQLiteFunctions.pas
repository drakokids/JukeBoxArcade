unit SQLiteFunctions;

interface

uses FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.VCLUI.Wait, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.DataSet,
  sysutils, MediaTypes;

procedure CreateSQLiteDB(connection1: TFDConnection);
function MediaFileExists(filename:string):boolean;
procedure MediaAddFile(filename: string; MediaInfo: TMediaInfo);
function EncodeString(Original: string):string;

implementation

uses mainunit;

procedure CreateSQLiteDB(connection1: TFDConnection);
begin
       connection1.ExecSQL('CREATE TABLE IF NOT EXISTS Config ('+
         'name TEXT not null, value TEXT );');

       connection1.ExecSQL('insert into Config (name,value) values ('+
         '''CLEAN_FILENAMES'',''1'')');

       connection1.ExecSQL('CREATE TABLE IF NOT EXISTS Singers ('+
       'ID INTEGER ,'+
       'SingerName TEXT NOT NULL,'+
       'CountryID INTEGER, Sex TEXT, Born text, Died text,'+
       'PRIMARY KEY ("ID" AUTOINCREMENT)'+
       ');');

       connection1.ExecSQL('CREATE TABLE IF NOT EXISTS Albums ('+
        'ID INTEGER ,'+
        'AlbumName TEXT NOT NULL,'+
        'AlbumDate text,'+
        'Cover text,'+
        'PRIMARY KEY ("ID" AUTOINCREMENT));');

       connection1.ExecSQL('CREATE TABLE IF NOT EXISTS Bands ('+
        'ID INTEGER,'+
        'BandName TEXT NOT NULL,'+
        'StartDate TEXT, EndedDate TEXT,PRIMARY KEY ("ID" AUTOINCREMENT));');

       connection1.ExecSQL('CREATE TABLE IF NOT EXISTS Musics ('+
        'ID INTEGER ,'+
        'MusicName TEXT NOT NULL,'+
        'Filename TEXT, Filetype TEXT,DELETED TEXT,'+
        'PRIMARY KEY ("ID" AUTOINCREMENT));');

       connection1.ExecSQL('CREATE TABLE IF NOT EXISTS AlbumBands ('+
        'AlbumID INTEGER, BandID INTEGER)');

       connection1.ExecSQL('CREATE TABLE IF NOT EXISTS AlbumSingers ('+
        'AlbumID INTEGER, SingerID INTEGER)');

       connection1.ExecSQL('CREATE TABLE IF NOT EXISTS AlbumMusics ('+
        'AlbumID INTEGER, MusicID INTEGER)');

       connection1.ExecSQL('CREATE TABLE IF NOT EXISTS RadioStreams ('+
        'ID INTEGER, '+
        'StreamName TEXT, URL TEXT,PRIMARY KEY ("ID" AUTOINCREMENT))');
end;

function MediaFileExists(filename:string):boolean;
var query1: TFDQuery;
begin
    query1:=TFDQuery.Create(nil);
    query1.Connection:=mainform.DB1;
    query1.SQL.Text:='Select count(*) as howmany from musics where upper(filename)='''+
      EncodeString(uppercase(filename))+'''';
    query1.open;

    result:=query1.fieldbyname('howmany').asstring<>'0';
    query1.Free;
end;

function PrepareSQL(sql: string):string;
begin
  sql:=StringReplace(sql,'''','''''',[rfreplaceall]);
  result:=sql;
end;

procedure MediaAddFile(filename: string; MediaInfo: TMediaInfo);
var s:string;
begin
    if not MediaFileExists(filename) then
     begin
      s:=EncodeString(filename);
      mainform.DB1.ExecSQL('insert into musics (MusicName,filename,filetype,deleted) values ('''+
       EncodeString(MediaInfo.title)+''','''+s+'',''+MediaInfo.fileType+'',''0'')');
     end
    else
     begin
      s:=EncodeString(uppercase(filename));
      mainform.DB1.ExecSQL('update musics set MusicName='''+EncodeString(MediaInfo.title)+
       ''' where upper(filename)='''+s+'''');
     end;
end;

function EncodeString(Original: string):string;
var destiny:string;
    i:integer;
begin
    for i := 1 to length(Original) do
     destiny:=destiny+inttohex(ord(Original[i]),1);
    result:=destiny;
end;

function DecodeString(Original: string):string;
var destiny:string;
    i:integer;
begin
    for i := 0 to length(Original) div 2 do
     begin
      destiny:=destiny+chr(StrToInt('$' +Original[i*2+1] +Original[i*2+2] ));
     end;
    result:=destiny;
end;

end.
