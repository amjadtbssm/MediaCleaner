program MediaCleaner;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {Media_Cleaner},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Media Cleaner';
  TStyleManager.TrySetStyle('Onyx Blue');
  Application.CreateForm(TMedia_Cleaner, Media_Cleaner);
  Application.Run;
end.
