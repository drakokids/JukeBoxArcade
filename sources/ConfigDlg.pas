unit ConfigDlg;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs;

type
  TConfigDialog = class(TForm)
  private
    { Private declarations }
  public
    function Execute: boolean;

  end;

var
  ConfigDialog: TConfigDialog;

implementation

{$R *.dfm}

{ TConfigDialog }

function TConfigDialog.Execute: boolean;
begin
  Showmodal;
  if modalresult=mrok then
   result:=true else result:=false;
end;

end.
