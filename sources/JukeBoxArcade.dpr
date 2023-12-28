program JukeBoxArcade;

uses
  Vcl.Forms,
  mainunit in 'mainunit.pas' {Mainform},
  ConfigDlg in 'ConfigDlg.pas' {ConfigDialog},
  MediaFilesFunctions in 'MediaFilesFunctions.pas',
  SQLiteFunctions in 'SQLiteFunctions.pas',
  MediaTypes in 'MediaTypes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainform, Mainform);
  Application.CreateForm(TConfigDialog, ConfigDialog);
  Application.Run;
end.
