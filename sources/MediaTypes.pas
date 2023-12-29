unit MediaTypes;

interface

uses graphics;

type
 TRadioInfo=record
  id,Name,tags,url,bitrate,codec,countrycode: string;
 end;

type
 TAuthorInfo=Record
   id,Name,country_code,band_id: string;
   photo: TBitmap;
 End;

type
 TBandInfo=record
  id,Name,tags,musicstyle,creation_date: string;
 end;

type
 TAlbumInfo=record
  id,Name,tags,musicstyle,songs_count,total_length: string;
  cover: TBitmap;
 end;

type
 TMediaInfo=record
  TrackNr:string;
  Title:string;
  Interpret:string;
  Album:string;
  Genre:string;
  Year:string;
  FileType: string;
 end;

type
 TVideoInfo=record
   id,Name,tags,filename,codec,language,legendsfile,length_hhmmss: string;
   cover: TBitmap;
 end;

implementation

end.
