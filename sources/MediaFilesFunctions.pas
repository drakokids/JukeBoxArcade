unit MediaFilesFunctions;

interface

uses system.Types;

procedure ScanFolder(folder: string);

implementation

uses System.IOUtils;

procedure ScanFolder(folder: string);
Var
  LList: TStringDynArray;
  I: Integer;
  LSearchOption: TSearchOption;
begin

  LSearchOption := TSearchOption.soAllDirectories;
  LList := TDirectory.GetFiles(folder, '*.*', LSearchOption);

  for I := 0 to Length(LList) - 1 do
   begin

   end;

end;

end.
