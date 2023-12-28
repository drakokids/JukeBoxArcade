unit MediaFilesFunctions;

interface

uses system.Types, MediaTypes,sysutils,System.StrUtils;

procedure ScanFolder(folder: string);
function GetMediaInfo(filename: string): TMediaInfo;
function ValidMusicExtension(fileext: string):boolean;

implementation

uses SQLiteFunctions,System.IOUtils, tags, bass, basswma;

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


end.
