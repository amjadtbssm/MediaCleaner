unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RzShellDialogs, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.StdCtrls, Vcl.FileCtrl, Vcl.Imaging.pngimage;

type
  TMedia_Cleaner = class(TForm)
    Image1: TImage;
    Label3: TLabel;
    LblPlaying: TLabel;
    Label5: TLabel;
    PathLabel: TLabel;
    LblStatus: TLabel;
    LblFile: TLabel;
    Image2: TImage;
    Label1: TLabel;
    LblSound: TLabel;
    BtnSelectFolder: TButton;
    BtnSettings: TButton;
    BtnAbout: TButton;
    BtnPlay: TButton;
    BtnPause: TButton;
    btnStop: TButton;
    BtnDelete: TButton;
    BtnCopy: TButton;
    BtnMove: TButton;
    BtnExit: TButton;
    FileListBox1: TFileListBox;
    BtnHelp: TButton;
    ProgressBar1: TProgressBar;
    BtnPre: TButton;
    BtnNext: TButton;
    BtnRename: TButton;
    EdtSearch: TEdit;
    VolTrackBar: TTrackBar;
    Timer1: TTimer;
    SelectFolderDialog: TRzSelectFolderDialog;
    MediaPanel: TPanel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Media_Cleaner: TMedia_Cleaner;

implementation

{$R *.dfm}

end.
