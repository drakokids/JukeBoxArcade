unit MediaFilesFunctions;

interface

uses system.Types, MediaTypes,sysutils,System.StrUtils,
    FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.VCLUI.Wait, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.DataSet, graphics;

procedure ScanFolder(folder: string);
function GetMediaInfo(filename: string): TMediaInfo;
function ValidMusicExtension(fileext: string):boolean;
procedure LoadAllRadios;
procedure LoadAllMusic;
procedure LoadAllVideos;

implementation

uses mainunit,SQLiteFunctions,System.IOUtils, tags, bass, basswma,
    functions, ImagingTypes, Imaging, ImagingComponents,dialogs;

procedure ScanFolder(folder: string);
Var
  LList: TStringDynArray;
  I: Integer;
  LSearchOption: TSearchOption;
  MyFileInfo: TMediaInfo;
  FileExt: string;
begin

  LSearchOption := TSearchOption.soAllDirectories;
  LList := TDirectory.GetFiles(folder, '*.*', LSearchOption);

  for I := 0 to Length(LList) - 1 do
   begin
    FileExt:=TPath.GetExtension(LList[i]);
    if uppercase(FileExt)='.MP3' then
     MyFileInfo:=GetMediaInfo(LList[i]);
    if ValidMusicExtension(FileExt) then
      MediaAddFile(LList[i],MyFileInfo);
   end;

end;

function GetMediaInfo(filename: string): TMediaInfo;
var Channel: HStream;
    info: TMediaInfo;
begin
    Bass_StreamFree(Channel);
    Channel := Bass_StreamCreateFile(false, PChar(filename), 0, 0, Bass_Stream_Decode {$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});
    if Channel = 0 then
      Channel := Bass_WMA_StreamCreateFile(false, PChar(filename), 0, 0, Bass_Stream_Decode {$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});
    if Channel = 0 then
     begin
      result:=info;
      exit;
     end;
    info.TrackNr:=string(TAGS_Read(Channel, '%TRCK'));
    info.Title:=string(TAGS_Read(Channel, '%TITL'));
    info.Interpret:=string(TAGS_Read(Channel, '%ARTI'));
    info.Album:=string(TAGS_Read(Channel, '%ALBM'));
    info.Genre:=string(TAGS_Read(Channel, '%GNRE'));
    info.Year:=string(TAGS_Read(Channel, '%YEAR'));
    info.FileType:=StringReplace(Uppercase(TPath.GetExtension(filename)),'.','',[rfreplaceall]);
    result:=info;
end;

function ValidMusicExtension(fileext: string):boolean;
begin
   fileext:=uppercase(fileext);
   result:=MatchText(fileext, ['.MP3', '.WAV','.FLAC','.AAC','.AIFF','.OGG',
     '.WMA','.CDA']);

end;

//Load All Radios from DB to structure
procedure LoadAllRadios;
var query1: TFDQuery;
    index:integer;
    extension:string;
    Img: TImageData;
begin
   SetLength(AllRadios,0);

   query1:=TFDQuery.Create(nil);
   query1.Connection:=mainform.DB1;
   query1.SQL.Text:='Select * from RadioStreams';
   query1.open;

   index:=0;
   while not query1.eof do
    begin

     SetLength(AllRadios,Length(AllRadios)+1);

     AllRadios[index].id:=query1.fieldbyname('ID').asstring;
     AllRadios[index].Name:=query1.fieldbyname('StreamName').asstring;
     AllRadios[index].url:=query1.fieldbyname('URL').asstring;
     AllRadios[index].cover:=query1.fieldbyname('COVER').asstring;
     AllRadios[index].bitrate:=query1.fieldbyname('BITRATE').asstring;
     AllRadios[index].codec:=query1.fieldbyname('CODEC').asstring;
     AllRadios[index].countrycode:=query1.fieldbyname('COUNTRYCODE').asstring;
     AllRadios[index].coverid:=-1;

     if AllRadios[index].cover<>'' then
     if fileexists(IconsFolder+'\'+AllRadios[index].cover) then
      begin
       extension:=uppercase(ExtractFileExt(IconsFolder+'\'+AllRadios[index].cover));
       if (extension='.PNG') or ((extension='.JPG')) or ((extension='.GIF'))
       then
        begin
         AllRadios[index].coverid:=length(AllCovers);
         Setlength(AllCovers,length(AllCovers)+1);

         logwrite('Working Image '+AllRadios[index].cover);
         InitImage(Img);

         if LoadImageFromFile(IconsFolder+'\'+AllRadios[index].cover, Img) then
          begin
           ResizeImage(Img, 128, 128, rfBicubic);

           AllCovers[length(AllCovers)-1]:=TBitmap.Create(128,128);
           ConvertDataToBitmap(Img,AllCovers[length(AllCovers)-1]);
          end;

         FreeImage(Img);


        end;
      end;


     query1.next;
     index:=index+1;
    end;


   query1.Free;

   mainform.GridRadios.RowCount:=Length(AllRadios)+1;
   mainform.GridRadios.Invalidate;

end;

//Load All Music from DB to structure
procedure LoadAllMusic;
begin
   SetLength(AllMedia,0);
end;

//Load All Videos from DB to structure
procedure LoadAllVideos;
begin
   SetLength(AllVideos,0);
end;


end.
