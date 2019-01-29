program MediaCleaner;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {Media_Cleaner},
  Vcl.Themes,
  Vcl.Styles,
  RenameFrm in 'RenameFrm.pas' {RenameForm},
  AboutForm in 'AboutForm.pas' {FormAbout},
  MainSettings in 'MainSettings.pas' {FrmSettings};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Media Cleaner';
  TStyleManager.TrySetStyle('Onyx Blue');
  Application.CreateForm(TMedia_Cleaner, Media_Cleaner);
  Application.CreateForm(TRenameForm, RenameForm);
  Application.CreateForm(TFormAbout, FormAbout);
  Application.CreateForm(TFrmSettings, FrmSettings);
  Application.Run;
end.
