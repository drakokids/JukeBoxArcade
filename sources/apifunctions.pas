unit apifunctions;

interface

uses system.Classes,system.SysUtils;

procedure updateRadioStations(countrycode,tags,bitratemin,codec: string);

implementation

uses functions,djson,sqliteFunctions;

procedure updateRadioStations(countrycode,tags,bitratemin,codec: string);
var netfile,url,stationuuid: string;
    jsonfile: TStrings;
    radios, radio:  TdJSON;
    radioname,radiourl,radiotags,radiobitrate,radiocodec,radiocountrycode,radiofavicon:string;
begin
  //http://de1.api.radio-browser.info/xml/stations/bycountry/portugal
  //http://de1.api.radio-browser.info/json/stations/search?countrycode=PT&bitrateMin=256&codec=MP3&tag=rock
  url:='http://de1.api.radio-browser.info/json/stations/search?';
  if countrycode='' then countrycode:='PT';
  url:=url+'countrycode='+countrycode;
  if tags<>'' then url:=url+'&tag='+tags;
  if codec<>'' then url:=url+'&codec='+codec;
  if bitratemin<>'' then url:=url+'&bitrateMin='+codec;

  //netfile:=DownloadFile(url);
  NewDownloadFile(url,'c:\temp\radios.txt');
  jsonfile:=TStringList.Create;
  jsonfile.LoadFromFile('c:\temp\radios.txt', TEncoding.UTF8);

  radios := TdJSON.Parse(jsonfile.Text);
  for radio in radios do
   begin
    stationuuid:=radio['stationuuid'].AsString;
    radioname:=radio['name'].AsString;
    radiourl:=radio['url_resolved'].AsString;
    radiotags:=radio['tags'].AsString;
    radiobitrate:=radio['bitrate'].AsString;
    radiocodec:=radio['codec'].AsString;
    radiocountrycode:=radio['countrycode'].AsString;
    radiofavicon:=radio['favicon'].AsString;
    AddRadio(stationuuid,radioname,radiourl,radiotags,radiofavicon,radiocountrycode,
        radiocodec,radiobitrate);
   end;
  radios.Free;
end;

end.
