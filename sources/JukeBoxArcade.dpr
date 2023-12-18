program JukeBoxArcade;

uses
  Vcl.Forms,
  mainunit in 'mainunit.pas' {Mainform};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainform, Mainform);
  Application.Run;
end.
