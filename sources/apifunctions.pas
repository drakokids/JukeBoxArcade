unit apifunctions;

interface

procedure updateRadioStations(countrycode,tags,bitratemin,codec: string);

implementation

uses functions,djson;

procedure updateRadioStations(countrycode,tags,bitratemin,codec: string);
var netfile,url: string;
    radios, radio:  TdJSON;
    radioname:string;
begin
  //http://de1.api.radio-browser.info/xml/stations/bycountry/portugal
  //http://de1.api.radio-browser.info/json/stations/search?countrycode=PT&bitrateMin=256&codec=MP3&tag=rock
  url:='http://de1.api.radio-browser.info/json/stations/search?';
  if countrycode='' then countrycode:='PT';
  url:=url+'countrycode='+countrycode;
  if tags<>'' then url:=url+'&tag='+tags;
  if codec<>'' then url:=url+'&codec='+codec;
  if bitratemin<>'' then url:=url+'&bitrateMin='+codec;



  netfile:=DownloadFile(url);
  radios := TdJSON.Parse(netfile);
  for radio in radios do
   begin
    radioname:=radio['name'].AsString;
   end;
  radios.Free;
end;

end.
