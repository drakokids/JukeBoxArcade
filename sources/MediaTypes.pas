unit MediaTypes;

interface

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
  TRadioInfo=record
   id,Name,tags,url,bitrate,codec,countrycode: string;
  end;

implementation

end.
