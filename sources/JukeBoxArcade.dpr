program JukeBoxArcade;

uses
  Vcl.Forms,
  mainunit in 'mainunit.pas' {Mainform},
  ConfigDlg in 'ConfigDlg.pas' {ConfigDialog},
  MediaFilesFunctions in 'MediaFilesFunctions.pas',
  SQLiteFunctions in 'SQLiteFunctions.pas',
  MediaTypes in 'MediaTypes.pas',
  apifunctions in 'apifunctions.pas',
  djson in 'djson.pas',
  MiniWindowFrm in 'MiniWindowFrm.pas' {FormMiniWindow};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainform, Mainform);
  Application.CreateForm(TConfigDialog, ConfigDialog);
  Application.CreateForm(TFormMiniWindow, FormMiniWindow);
  Application.Run;
end.
