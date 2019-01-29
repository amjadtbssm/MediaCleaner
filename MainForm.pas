unit MainForm;

interface


uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.UITypes,
  System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Math, Vcl.Imaging.pngimage,
  RzShellDialogs, Vcl.FileCtrl, Vcl.ComCtrls, ShellAPI, INIFiles,
  Vcl.Imaging.GIFImg, DSPack, AVPlayer, DirectShow9, StreamProtocol,
  UPushSource;

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
    BtnPre: TButton;
    BtnNext: TButton;
    Timer1: TTimer;
    SelectFolderDialog: TRzSelectFolderDialog;
    BtnRename: TButton;
    EdtSearch: TEdit;
    Label1: TLabel;
    LblSound: TLabel;
    VolTrackBar: TTrackBar;
    MediaPanel: TPanel;
    SeekBar: TDSTrackBar;
    VideoWindow: TVideoWindow;
    FilterGraph: TFilterGraph;
    VidPlayer: TAVPlayer;
    procedure FormCreate(Sender: TObject);
    procedure BtnAboutClick(Sender: TObject);
    procedure BtnSettingsClick(Sender: TObject);
    procedure BtnExitClick(Sender: TObject);
    procedure BtnHelpClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure BtnSelectFolderClick(Sender: TObject);
    procedure BtnPlayClick(Sender: TObject);
    procedure BtnPauseClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure BtnDeleteClick(Sender: TObject);
    procedure PlayMedia(Sender: TObject);
    procedure FileListBox1DblClick(Sender: TObject);
    procedure BtnCopyClick(Sender: TObject);
    procedure BtnMoveClick(Sender: TObject);
    procedure BtnNextClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure BtnPreClick(Sender: TObject);
    procedure BtnRenameClick(Sender: TObject);
    procedure EdtSearchChange(Sender: TObject);
    procedure LblSoundClick(Sender: TObject);
    procedure VolTrackBarChange(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    FMem:TMemoryStream;
    function IsVistaAndAbove:Boolean;
    procedure OpenVideoFile(AFile,AFormat:string;AStartTime,AEndTime:int64);
    function GetBestRenderMode():TVideoMode;
  public
    { Public declarations }
    Procedure CheckCurItem;
    Procedure UpdateCurItem;
    procedure CheckCopyPath(Sender: TObject);
    procedure CheckMovePath(Sender: TObject);
    Procedure PlayItem(Item: Integer);
    Function FileOperation(const source, dest : string; op, flags : Integer) : boolean;
    Procedure RemoveSelected;
    Procedure LoadSettings;
    Procedure SaveSettings;
    Procedure SetVolume(Vol: integer);
    function GetVolume: integer;
    Procedure GoMute;
    Procedure UnMutePlayer;
  end;

var
  Media_Cleaner: TMedia_Cleaner;
  InitOpenFile:string = '';
  Tracking: Boolean;
  MoveDir: string;
  CopyDir: string;
  CurItem: Boolean;
  CurFile, RenIndex, CurVolume: Integer;
  IsPlaying, PlayerMute: Boolean;

implementation

{$R *.dfm}

uses AboutForm, MainSettings, RenameFrm, DXSUtil, avlib,
     msvcrt, avlog, ActiveX, EVR9;

// Extract a file name after striping its extension and paths
function ExtractFileNameWithoutExtension (const AFileName: String): String;
var
I: Integer;
begin
  I := LastDelimiter('.' + PathDelim + DriveDelim,AFilename);
  if (I = 0) or (AFileName[I] <> '.') then I := MaxInt;
  Result := ExtractFileName(Copy(AFileName, 1, I - 1)) ;
end;

function SupportedFile(const FileName: string): Boolean;
 var
  S: string;
begin
  //Check for supported files
  Result := false;
  //Convert to All Caps before testing it
  S := UpperCase(ExtractFileExt(FileName));

   if S <> '' then begin
       // MP3 Audio Files
       if S = '.MP3' then Result := True else
       // WAVE Media Files
       if S = '.WAV' then Result := True else
       // MPG Video Files
       if S = '.MPG' then Result := True else
       // MPEG Video Files
       if S = '.MPEG' then Result := True else
       // MP4 Video Files
       if S = '.MP4' then Result := True else
       // MKV Video Files
       if S = '.MKV' then Result := True else
       // Flash FLV Video Files
       if S = '.FLV' then Result := True else
       // Windows Media Video (WMV) Files
       if S = '.WMV' then Result := True else
       // AVI Video
       if S = '.AVI' then Result := True else
       //A blank one to insert new file format
       //if S = '.' then Result := True else
       // DVD Vob Files
       if S = '.VOB' then Result := True;
   End else
   Begin
     Result := false;
   End;
end;

procedure LogCallback(Sender: pointer; level: integer; const Msg: PAnsiChar);
  cdecl;
var
  last_arg: pointer absolute Msg;
  ptr_args: array [0 .. 2047] of pointer absolute last_arg;
  Output: array [0 .. 2047] of AnsiChar;
  Log: String;
begin
  try
    FillChar(Output, SizeOf(Output), 0);
    _vsnprintf(Output, 1024, Msg, ptr_args[1]);
    Log := AnsiString(Output);    
  except
    // mask some weird invalid floating point exception
  end;
end;

procedure TMedia_Cleaner.BtnAboutClick(Sender: TObject);
begin
      //Show the About Box
      FormAbout.ShowModal;

end;

procedure TMedia_Cleaner.BtnCopyClick(Sender: TObject);
  Var
    FileName, TargetFileName: String;
    OpSuccess : boolean;
begin
    if FileListBox1.ItemIndex < 0 then Exit
      Else
      // Check if Copy to Folder Exists
      CheckCopyPath(Sender);
      // Copy the File
   FileName := IncludeTrailingPathDelimiter(FileListBox1.Directory)+FileListBox1.Items.Strings[FileListBox1.ItemIndex];
   TargetFileName := CopyDir +PathDelim+ FileListBox1.Items.Strings[FileListBox1.ItemIndex];
   OpSuccess := FileOperation(FileName, CopyDir, FO_COPY, FOF_ALLOWUNDO);
    if (OpSuccess) then begin
    LblStatus.Caption := 'File Copied to:';
    // File copied to below path
    LblFile.Caption := TargetFileName;
         end else begin
    LblStatus.Caption := 'Failed to Copy:';
    // Here the file title should be "Copied from" so that we can check
    // from where the copy command has failed
    LblFile.Caption := FileName;
         end;
end;

procedure TMedia_Cleaner.BtnDeleteClick(Sender: TObject);
  Var
    OpSuccess : boolean;
    FileOrFolder : string;
begin
      CurItem := False;
      if FileListBox1.ItemIndex < 0 then begin Exit
      end Else

        Begin

           if MessageDlg('Are you sure you want to Delete '+FileListBox1.Items.Strings[FileListBox1.ItemIndex]+' ???',
                mtWarning, [mbYes, mbNo], 0, mbYes) = mrYes then
            begin
            // Delete the selected file
            FileOrFolder := IncludeTrailingPathDelimiter(FileListBox1.Directory)+FileListBox1.Items.Strings[FileListBox1.ItemIndex];
            CheckCurItem;
                  if CurItem then Begin
                        //CurItem Collides free the filtergraph
                        btnStopClick(sender);
                        FilterGraph.Active := false;
                 end;

             OpSuccess := FileOperation(FileOrFolder, '', FO_DELETE, FOF_ALLOWUNDO or FOF_NOCONFIRMATION);
            if (OpSuccess) then begin
                        LblStatus.Caption := 'File Deleted:';
                        LblFile.Caption := FileOrFolder;
                        RemoveSelected;
                        UpdateCurItem;

                end else
                    begin
                        LblStatus.Caption := 'Failed to Delete:';
                        LblFile.Caption := FileOrFolder;
                        UpdateCurItem;
                    End;
                                if CurItem then  begin
                                     //Initialize the player
                                     FormShow(sender);
                                           end else
                                              begin
                                              Exit;

                                    end;

               BtnPlayClick(sender);
               End;  // Main Procedure
        End;
end;

procedure TMedia_Cleaner.BtnExitClick(Sender: TObject);
begin
      //Close the Application
      close;
end;

procedure TMedia_Cleaner.BtnHelpClick(Sender: TObject);
begin
      // Show the Help File
      ShellExecute(Handle, 'open', PChar(ExtractFilePath(Application.ExeName)+'\Help\Help.html'),nil,nil,SW_SHOWNORMAL) ;
end;

procedure TMedia_Cleaner.BtnMoveClick(Sender: TObject);
 Var
    OpSuccess : boolean;
    FileOrFolder, MoveTargetFile : string;
begin
      CurItem := False;
      if FileListBox1.ItemIndex < 0 then begin
      Exit
      end Else

        Begin
            CheckMovePath(Sender);
            // Delete File
            FileOrFolder := IncludeTrailingPathDelimiter(FileListBox1.Directory)+FileListBox1.Items.Strings[FileListBox1.ItemIndex];
            MoveTargetFile := MoveDir +PathDelim+ FileListBox1.Items.Strings[FileListBox1.ItemIndex];
            CheckCurItem;
                  if CurItem then Begin
                        //CurItem Collides free the player
                        btnStopClick(sender);
                        FilterGraph.Active := false;
                 end;
          OpSuccess := FileOperation(FileOrFolder, MoveDir, FO_MOVE, FOF_ALLOWUNDO);
            if (OpSuccess) then begin
                        LblStatus.Caption := 'File Moved to:';
                        LblFile.Caption := MoveTargetFile;
                        RemoveSelected;
                        UpdateCurItem;

                end else
                    begin
                        // RemoveSelected;
                        LblStatus.Caption := 'Failed to Move:';
                        LblFile.Caption := FileOrFolder;
                        UpdateCurItem;
                    End;

                                if CurItem then  begin
                                     // If the cuurent item was playing
                                     // the player was freed so re-initialize
                                     FormShow(sender);
                                     // Also play the next track ;-)
                                     BtnPlayClick(sender);
                                           end else
                                              begin
                                              Exit;
                                    end;
      End;  // Main Procedure

end;

procedure TMedia_Cleaner.BtnNextClick(Sender: TObject);
 var
  CurrentOne, NextOne: Integer;
begin
   // Play Next Item
  if FileListBox1.ItemIndex < 0 then
            Exit else
        Begin
          // Pick the current file
          CurrentOne := CurFile;
        // If current track has reached the end of list then go to first track
        if (CurrentOne = FileListBox1.Items.Count -1) then
          Begin
           CurrentOne := 0;
          end else begin
            //Go to the next track
            CurrentOne := CurrentOne + 1;
          end;
      // Get the Next Track ID Number and Play the track
      NextOne := CurrentOne;
      // Check if File Format is supported
      if SupportedFile(IncludeTrailingPathDelimiter(FileListBox1.Directory)+FileListBox1.Items.Strings[NextOne]) then Begin
      PlayItem(NextOne);
      //Set the current file to the new Track ID Number
      CurFile := NextOne;
      //Change the Now Playing Lable Caption
      FileListBox1.ItemIndex := NextOne;
      LblPlaying.Caption := IncludeTrailingPathDelimiter(FileListBox1.Directory)+FileListBox1.Items.Strings[NextOne];
        End else Begin
		    //If file format is not in supported extension list then raise error
            MessageDlg('This file format is not supported', mtError, [mbOK], 0, mbOK);
            exit;
     End;

  End;
end;

procedure TMedia_Cleaner.BtnPauseClick(Sender: TObject);
begin
    // Pause the playing Track
    FilterGraph.Pause;
end;

procedure TMedia_Cleaner.BtnPlayClick(Sender: TObject);
begin
  if FilterGraph.Active and  (FilterGraph.State in [gsStopped, gsPaused]) then
  Begin
     FilterGraph.Play;
  end else Begin
          if FileListBox1.ItemIndex < 0 then Exit else
            begin
              if SupportedFile(IncludeTrailingPathDelimiter(FileListBox1.Directory)+FileListBox1.Items.Strings[FileListBox1.ItemIndex]) then Begin
                  PlayItem(FileListBox1.ItemIndex);
                  CurFile := FileListBox1.ItemIndex;
                  LblPlaying.Caption := IncludeTrailingPathDelimiter(FileListBox1.Directory)+FileListBox1.Items.Strings[CurFile];
            end else Begin
                //If file format is not in supported extension list then raise error
				MessageDlg('This file format is not supported', mtError, [mbOK], 0, mbOK);
                exit;
            End;
      End;
         End;

end;

procedure TMedia_Cleaner.BtnPreClick(Sender: TObject);
 var
  CurrentOne, NextOne: Integer;
begin
  // Play Previous Item
  if FileListBox1.ItemIndex < 0 then
            Exit else
        Begin
          // Get current track
          CurrentOne := CurFile;
        // If current track is the first track then go to last track
        // (As previous of the first track would be last)
        if  CurrentOne = 0 then
          Begin
           CurrentOne := FileListBox1.Items.Count -1;
          end else begin
            // Go to previous track
            CurrentOne := CurrentOne - 1;
          end;
      // Assign the previous track
      NextOne := CurrentOne;
      if SupportedFile(IncludeTrailingPathDelimiter(FileListBox1.Directory)+FileListBox1.Items.Strings[NextOne]) then Begin
      // Play the previous track
      PlayItem(NextOne);
      // Set the current track file
      CurFile := NextOne;
      //Change the Now Playing Lable Caption
      FileListBox1.ItemIndex := NextOne;
      LblPlaying.Caption := IncludeTrailingPathDelimiter(FileListBox1.Directory)+FileListBox1.Items.Strings[NextOne];
      End else Begin
       //If file format is not in supported extension list then raise error
	   MessageDlg('This file format is not supported', mtError, [mbOK], 0, mbOK);
       exit;
     End;
  End;
end;

procedure TMedia_Cleaner.BtnRenameClick(Sender: TObject);
begin
      //Rename Selected File by showing the Rename File Dialog
      //Set the CurItem to False Before testing for It
      CurItem := False;
      //If nothing is selected then exit
      if FileListBox1.ItemIndex < 0 then begin Exit
      end Else

        Begin
          //Get the file name in the Rename Dialog
          RenameForm.EdtRename.Text := ExtractFileNameWithoutExtension(FileListBox1.Items.Strings[FileListBox1.ItemIndex]);
          //Get the file Extension
          //First Clear the EdtExt just to be sure it does not contain the Previous Extension
          RenameForm.EdtExt.Text := '';
          RenameForm.EdtExt.Text := ExtractFileExt(FileListBox1.Items.Strings[FileListBox1.ItemIndex]);
          //Set the Rename Index
          RenIndex := FileListBox1.ItemIndex;
          //Show the Rename Dialog
          RenameForm.ShowModal;
        End;

end;

procedure TMedia_Cleaner.BtnSelectFolderClick(Sender: TObject);
Var
  Path    : String;
begin
  if SelectFolderDialog.Execute then
  begin
    Path:=IncludeTrailingPathDelimiter(SelectFolderDialog.SelectedPathName);
    FileListBox1.Directory := Path;
    PathLabel.Caption := Path;
  end;
end;

procedure TMedia_Cleaner.BtnSettingsClick(Sender: TObject);
begin
      //Show the Settings Dialog
      FrmSettings.ShowModal;
end;

procedure TMedia_Cleaner.btnStopClick(Sender: TObject);
begin
  // Stop the current playing track
  FilterGraph.Stop;
  // Set the position of the player to start of the track
  FilterGraph.Position := 0;
  // Set the position of the seek bar to start
  SeekBar.Position := 0;
end;

procedure TMedia_Cleaner.CheckCopyPath(Sender: TObject);
begin
      // Check if the Copy to Directories exist if not create them

      if System.SysUtils.DirectoryExists (CopyDir) then
          begin
            Exit;
          end else
            ShowMessage('Copy To Folder does not exist' + #13#10 + 'It will be created');
            System.SysUtils.ForceDirectories(CopyDir);
end;

procedure TMedia_Cleaner.CheckCurItem;
  var
    CurntIndex: Integer;
begin
        // Check the current Playing Item Index
        CurntIndex := FileListBox1.ItemIndex;
        if CurntIndex > CurFile then begin
    exit
    end else if CurntIndex < CurFile then
    begin
      // As it is meant to check only do not alter index
      Exit;
    end

    // If playing the current selected index then set CurItem to True
     else if CurntIndex = CurFile then
     Begin
       CurItem := True;
     End;
end;

procedure TMedia_Cleaner.CheckMovePath(Sender: TObject);
begin
          // Check if the Move to Directories exist if not create them

      if System.SysUtils.DirectoryExists (MoveDir) then
          begin
            // ShowMessage('Copy To Folder Exists');
            Exit;
          end else
            ShowMessage('Move To Folder does not exist' + #13#10 + 'It will be created');
            System.SysUtils.ForceDirectories(MoveDir);
end;

procedure TMedia_Cleaner.EdtSearchChange(Sender: TObject);
begin
    FileListBox1.Mask := '*' + EdtSearch.Text + '*';
     //If nothing is entered for search or search is cleared
     //then Re-Enter the Old Mask (Intended for Media Files)
     //to ensure that TFileListBox shows the right files in the list
     if EdtSearch.Text = '' then Begin
        FileListBox1.Mask := '*.mp3;*.wav;*.mpg;*.mpeg;*.mp4;*.mkv;*.flv;*.wmv;*.avi;*.vob;';
     End;
end;


procedure TMedia_Cleaner.FileListBox1DblClick(Sender: TObject);
begin
     // Play the double clicked track
     PlayMedia(sender);
end;

function TMedia_Cleaner.FileOperation(const source, dest: string; op,
  flags: Integer): boolean;
{perform Copy, Move, Delete, Rename on files + folders via WinAPI}
var
  Structure : TSHFileOpStruct;
  src, dst : string;
  OpResult : integer;
begin
  {setup file op structure}
  FillChar(Structure, SizeOf (Structure), #0);
  src := source + #0#0;
  dst := dest + #0#0;
  Structure.Wnd := 0;
  Structure.wFunc := op;
  Structure.pFrom := PChar(src);
  Structure.pTo := PChar(dst);
  Structure.fFlags := flags or FOF_SILENT;
  case op of
    {set title for simple progress dialog}
    FO_COPY : Structure.lpszProgressTitle := 'Copying...';
    FO_DELETE : Structure.lpszProgressTitle := 'Deleting...';
    FO_MOVE : Structure.lpszProgressTitle := 'Moving...';
    FO_RENAME : Structure.lpszProgressTitle := 'Renaming...';
    end; {case op of..}
  OpResult := 1;
  try
    {perform operation}
    OpResult := SHFileOperation(Structure);
  finally
    {report success / failure}
    result := (OpResult = 0);
    end; {try..finally..}
end; {function FileOperation}

procedure TMedia_Cleaner.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    // Save Form and Directory Settings
    SaveSettings;
end;

procedure TMedia_Cleaner.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
   // Important
  FilterGraph.ClearGraph;
end;

procedure TMedia_Cleaner.FormCreate(Sender: TObject);
var
  mode:TVideoMode;
begin
       // Load the Settings i.e. Default Move and Copy Directories
       LoadSettings;
       //initialize the default values and set the video mode
         FMem:=TMemoryStream.Create;
		 // Get the best render mode
         mode:=GetBestRenderMode;
           if mode=vmEVR then
            begin
              VideoWindow.Mode := vmEVR;
            end
                else
                   VideoWindow.Mode := mode;
end;

procedure TMedia_Cleaner.FormDestroy(Sender: TObject);
begin    
	//Free the memory stream
    FMem.Free;
end;

procedure TMedia_Cleaner.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // Ctrl+P play/pause the track
  if (Key = 80) and (Shift = [ssCtrl]) then
    Begin
          if FilterGraph.Active and  (FilterGraph.State in [gsStopped, gsPaused]) then
  Begin
     FilterGraph.Play;
  end else Begin
     FilterGraph.pause;
        End;
	end;


  // Ctrl+O Open Select Folder Dialog
  if (Key = 79) and (Shift = [ssCtrl]) then Begin
  BtnSelectFolderClick(sender);
  End;

  // Ctrl+M Mute the Player
  if (Key = 77) and (Shift = [ssCtrl]) then Begin
  LblSoundClick(sender);
  End;


  // Ctrl+C Copy
  if (Key = 67) and (Shift = [ssCtrl]) then Begin
  BtnCopyClick(sender);
  End;

  // Ctrl+X Cut / Move
  if (Key = 88) and (Shift = [ssCtrl]) then Begin
  BtnMoveClick(sender);
  End;

  // Ctrl+Z Delete
  if (Key = 90) and (Shift = [ssCtrl]) then Begin
  BtnDeleteClick(sender);
  End;

  // Ctrl+B Previous
  if (Key = 66) and (Shift = [ssCtrl]) then Begin
  BtnPreClick(sender);
  End;

  // Ctrl+N Next
  if (Key = 78) and (Shift = [ssCtrl]) then Begin
  BtnNextClick(sender);
  End;

  // Ctrl+A Play
  if (Key = 65) and (Shift = [ssCtrl]) then Begin
  BtnPlayClick(sender);
  End;

  // Ctrl+S Stop
  if (Key = 83) and (Shift = [ssCtrl]) then Begin
  BtnStopClick(sender);
  End;

  //If F1 key is pressed show the help
  if (Key = VK_F1) then Begin
  BtnHelpClick(sender);
  End;

  //If F2 Rename
  if (Key = VK_F2) then Begin
  BtnRenameClick(sender);
  End;

  //If F3 key is pressed jump to search box
  if (Key = VK_F3) then Begin
  EdtSearch.SetFocus;
  End;

  //If F4 key is pressed show the about box
  if (Key = VK_F4) then Begin
  BtnAboutClick(sender);
  End;

  //If F5 key is pressed show the settings dialog
  if (Key = VK_F5) then Begin
  BtnSettingsClick(sender);
  End;

  //VK_PLAY
  if (Key = VK_PLAY) then Begin
  BtnPlayClick(sender);
  End;

  //VK_MEDIA_PLAY_PAUSE
  if (Key = VK_MEDIA_PLAY_PAUSE) then begin
  if FilterGraph.Active and  (FilterGraph.State in [gsStopped, gsPaused]) then
  Begin
     FilterGraph.Play;
  end else Begin
     FilterGraph.pause;
        End;
  end;

  //VK_MEDIA_STOP
  if (Key = VK_MEDIA_STOP) then Begin
  BtnStopClick(sender);
  End;

  //VK_PAUSE
  if (Key = VK_PAUSE) then Begin
  BtnPauseClick(sender);
  End;

  //VK_PRIOR
  if (Key = VK_PRIOR) then Begin
  BtnPreClick(sender);
  End;

  //VK_MEDIA_PREV_TRACK
  if (Key = VK_MEDIA_PREV_TRACK) then Begin
  BtnPreClick(sender);
  End;

  //VK_MEDIA_NEXT_TRACK
  if (Key = VK_MEDIA_NEXT_TRACK) then Begin
  BtnNextClick(sender);
  End;

  //VK_NEXT
  if (Key = VK_NEXT) then Begin
  BtnNextClick(sender);
  End;

  //VK_RETURN
  if (Key = VK_RETURN) then Begin
  BtnPlayClick(sender);
  End;

  //If escape Key is pressed Stop the Player
  if (Key = VK_ESCAPE) then Begin
  BtnStopClick(sender);
  End;

  //Delete the File if Delete Key is pressed
  if (Key = VK_DELETE) then Begin
  BtnDeleteClick(sender);
  End;

  //Show the Help file if HELP Key is pressed
  //This key exist on MultiMedia Keyboards Only
  if (Key = VK_HELP) then Begin
  BtnHelpClick(sender);
  End;

  //Slightly up the Volume if Volume UP Key is pressed
  //This key exist on MultiMedia Keyboards Only
  if (Key = VK_VOLUME_UP) then Begin
    //Slightly up the volume at each press
    if VolTrackBar.Position >= 100 then exit else begin
       //Up the Volume 5 ticks per key press
       VolTrackBar.Position := VolTrackBar.Position + 5;
    end;
  End;

  //Slightly Down the Volume if Volume Down Key is pressed
  //This key exist on MultiMedia Keyboards Only
  if (Key = VK_VOLUME_DOWN) then Begin
    //Slightly down the volume at each press
    if VolTrackBar.Position <= 0 then exit else begin
       //Down the Volume 5 ticks per key press
       VolTrackBar.Position := VolTrackBar.Position - 5;
    End;
  End;


  //Slightly UP the Volume if F6 Key is pressed
  if (Key = VK_F6) then Begin
    //Slightly up the volume at each press
    if VolTrackBar.Position >= 10000 then exit else begin
       //Up the Volume 5 ticks per key press
       VolTrackBar.Position := VolTrackBar.Position + 500;
    end;
  End;

  //Slightly Down the Volume if F7 Key is pressed
  if (Key = VK_F7) then Begin
    //Slightly down the volume at each press
    if VolTrackBar.Position <= 0 then exit else begin
       //Down the Volume 5 ticks per key press
       VolTrackBar.Position := VolTrackBar.Position - 500;
    End;
  End;



end;

procedure TMedia_Cleaner.FormShow(Sender: TObject);
begin
  //
  if FileExists(InitOpenFile) then
  begin
    OpenVideoFile(InitOpenFile, '', 0, 0);
  end;
end;


function TMedia_Cleaner.GetVolume: integer;
begin
      //Get the current Volume of Playing Track
      result := CurVolume;
end;

function TMedia_Cleaner.GetBestRenderMode: TVideoMode;
var
  fg:IGraphBuilder;
  evr:IBaseFilter;
  vmr:IBaseFilter;
  CW: Word;
  EVRService:IMFGetService;
  EVRDisplayControl:IMFVideoDisplayControl;
  VMRFilterConfig:IVMRFilterConfig9;
begin
  Result:=vmNormal;
  CoCreateInstance(CLSID_FilterGraph, nil, CLSCTX_INPROC_SERVER, IID_IFilterGraph2, fg);

  if IsVistaAndAbove then
  begin
    try
      CW := Get8087CW;
      try
        CoCreateInstance(CLSID_EnhancedVideoRenderer, nil, CLSCTX_INPROC, IID_IBaseFilter ,evr);

      finally
        Set8087CW(CW);
      end;

      fg.AddFilter(evr, 'EVR');

      if CheckDSError(evr.QueryInterface(IMFGetService, EVRService)) = S_OK then
      begin
        CheckDSError(EVRService.GetService(MR_VIDEO_RENDER_SERVICE, IID_IMFVideoDisplayControl, EVRDisplayControl));
      end
      else
        Exit;
      fg.RemoveFilter(evr);
      Exit(vmEVR);
    except
      fg:=nil;
      Exit;
    end;
  end;

  CW := Get8087CW;
  try
    CoCreateInstance(CLSID_VideoMixingRenderer9, nil, CLSCTX_INPROC, IID_IBaseFilter ,vmr);
    vmr.QueryInterface(IVMRFilterConfig9, VMRFilterConfig);
    try
      CheckDSError(VMRFilterConfig.SetRenderingMode(VMR9Mode_Windowed));
      Exit(vmVMR);
    except
      Exit;
    end;
  finally
    Set8087CW(CW);
  end;
end;

procedure TMedia_Cleaner.GoMute;
begin
      //Get the current volume
      CurVolume := GetVolume;
      //Mute.... Well you know what it mean  dont you :-p
      // BASS_ChannelSetAttribute(stream, BASS_ATTRIB_VOL, 0);
      FilterGraph.Volume := 0;
      PlayerMute := True;
      LblSound.Caption := 'X';
end;


function TMedia_Cleaner.IsVistaAndAbove: Boolean;
begin
  Result:= Win32MajorVersion >= 6;
end;

procedure TMedia_Cleaner.LblSoundClick(Sender: TObject);
begin
      //If player is not mute then Mute It
      if PlayerMute then UnMutePlayer
      //If Player is already muted then UnMute
      Else GoMute;
end;

procedure TMedia_Cleaner.LoadSettings;
var
    ini: TIniFile;
begin
  // Load INI File and load the settings
  INI := TIniFile.Create(ExtractFilePath(Application.ExeName)+ 'settings.ini');
    Try
       MoveDir := Ini.ReadString('MediaCleaner', 'MoveDir', MoveDir);
       CopyDir := Ini.ReadString('MediaCleaner', 'CopyDir', CopyDir);
       Top := INI.ReadInteger('Placement','Top', Top) ;
       Left := INI.ReadInteger('Placement','Left', Left);
       VolTrackBar.Position := INI.ReadInteger('MediaPlayer','Volume', VolTrackBar.Position);
       SetVolume(VolTrackBar.Position);
       PlayerMute := INI.ReadBool('MediaPlayer','PlayerMute',PlayerMute);
    Finally
       Ini.Free;
    End;
    // PlayerMute is true then Mute the Player
      if PlayerMute then Begin
          GoMute;
      End;
    // Initially create the MoveTo and CopyTo Directories if they do not exist
    if MoveDir <> '' then Begin
        if not System.SysUtils.DirectoryExists (MoveDir) then Begin
           //Create the Move To Directory
           System.SysUtils.ForceDirectories(MoveDir);
        End;
     End;

     if CopyDir <> '' then Begin
        if not System.SysUtils.DirectoryExists (CopyDir) then Begin
             //Create the Copy To Directory
             System.SysUtils.ForceDirectories(CopyDir);
        End;
     End;
end;

procedure TMedia_Cleaner.OpenVideoFile(AFile, AFormat: string; AStartTime,
  AEndTime: int64);
begin
      //Play the file
  FilterGraph.Active := False;
  //avpPlayer.LoopCount:=2;
  VidPlayer.InputFormat:=AFormat;
  VidPlayer.StartTime:=AStartTime;
  VidPlayer.EndTime:=AEndTime;
  if not VidPlayer.OpenFile(AFile) then
  begin
    ShowMessage(Format('Can not open the file %s!', [AFile]));
    Exit;
  end;
  //Todo:adjust window size to video file size
  FilterGraph.Active := true;
  //VolTrackBar.Position := FilterGraph.Volume;

  //VidPlayer.SeekPositionMode:=spBackwardRequest;

  FilterGraph.Play;
end;

procedure TMedia_Cleaner.PlayItem(Item: Integer);
var
  MyFile:String;
begin
    MyFile := IncludeTrailingPathDelimiter(FileListBox1.Directory)+FileListBox1.Items.Strings[Item];
     if item < 0  then exit;

     if SupportedFile(MyFile) then Begin
       OpenVideoFile(MyFile, '', 0,0);
            SetVolume(GetVolume);
             // If Player is in Mute State then Keep it as is
      if PlayerMute then Begin
        GoMute;
      End;
     End else Begin
       MessageDlg('This file format is not supported', mtError, [mbOK], 0, mbOK);
       exit;
     End;
end;

procedure TMedia_Cleaner.PlayMedia(Sender: TObject);
begin
      if SupportedFile(IncludeTrailingPathDelimiter(FileListBox1.Directory)+FileListBox1.Items.Strings[FileListBox1.ItemIndex]) then Begin
      // Play the selected Item in BASS
      PlayItem(FileListBox1.ItemIndex);
      CurFile := FileListBox1.ItemIndex;
      // Change the Now Playing Lable Caption
      LblPlaying.Caption := IncludeTrailingPathDelimiter(FileListBox1.Directory)+FileListBox1.Items.Strings[FileListBox1.ItemIndex];
      End else Begin
       MessageDlg('This file format is not supported', mtError, [mbOK], 0, mbOK);
       exit;
     End;
end;

procedure TMedia_Cleaner.RemoveSelected;
var
  PrevIndex: Integer;
begin
            // Remove The selected Entry

            //Get the current Track ID
            PrevIndex := FileListBox1.ItemIndex;
            // Remove it from the FileListBox
            FileListBox1.Items.Delete(PrevIndex);

            //if removed Track ID is grater than FileListBox items
          if PrevIndex > (FileListBox1.Items.Count -1) then
              begin
              //Then move Track ID to one track previous
              PrevIndex := FileListBox1.Items.Count -1;
              //Set the current selected track to the previous track
              FileListBox1.ItemIndex := PrevIndex;
              end else
                  begin
                    //If Its not larger than the deleted track then leave as is
                    FileListBox1.ItemIndex := PrevIndex;
                  end;

          // If the remaining track is single then make it selected
          if (PrevIndex = 0) and  (FileListBox1.Items.Count <> -1) then
                 FileListBox1.ItemIndex := 0;
end;

procedure TMedia_Cleaner.SaveSettings;
  var
    ini: TIniFile;
begin
    // Save Settings to INI File
  INI := TIniFile.Create(ExtractFilePath(Application.ExeName)+ 'settings.ini');
    Try
  with INI do
     begin
       WriteString('MediaCleaner','MoveDir', MoveDir);
       WriteString('MediaCleaner','CopyDir', CopyDir);
       WriteInteger('Placement','Top', Top);
       WriteInteger('Placement','Left', Left);
       WriteBool('MediaPlayer','PlayerMute',PlayerMute);
       WriteInteger('MediaPlayer','Volume', VolTrackBar.Position);
     end;
   finally
     Ini.Free;
    End;
end;


procedure TMedia_Cleaner.SetVolume(Vol: integer);
begin
     // Set the Volume Current Playing Track
     //OMG I was doing the vice versa here
     //Vol := CurVolume;
     CurVolume := Vol;
     FilterGraph.Volume := Vol;
     // BASS_ChannelSetAttribute(stream, BASS_ATTRIB_VOL, CurVolume);
end;


procedure TMedia_Cleaner.Timer1Timer(Sender: TObject);
begin
    // Show the progress of the playing item
    if Tracking = False then
    // ProgressBar1.Position := BASS_ChannelGetPosition(stream,0);
end;

procedure TMedia_Cleaner.UnMutePlayer;
begin
       CurVolume := VolTrackBar.Position;
       SetVolume(CurVolume);
       PlayerMute := False;
       LblSound.Caption := 'Xð';
end;

procedure TMedia_Cleaner.UpdateCurItem;
var
  CurntItem: Integer;
begin
      // Check the current Playing Item Index
        if CurFile <> -1 then
         begin
        CurntItem := FileListBox1.ItemIndex;
        if CurntItem > CurFile then begin
      //Current Playing File is prior to the index
      // CurFile Variable will not be disturbed
    exit
    end else if CurntItem = CurFile then
    begin
        // If CurntItem equals the CurFile then simply exit the function
        CurFile := CurntItem;
        Exit;
        end else if CurntItem < CurFile then
    begin
      // CurFile is Greater than current index so 1 will be minused
      CurFile := CurFile - 1;
    end;
         end;
end;

procedure TMedia_Cleaner.VolTrackBarChange(Sender: TObject);
begin
     //If player was mute when changing the Volume
     //UnMute it and then set the volume
     if PlayerMute then Begin
       UnMutePlayer;
     End;
     SetVolume(VolTrackBar.Position);
     FilterGraph.Volume := VolTrackBar.Position;
end;

initialization
  FFMPEG_DLL_PATH:= ExtractFilePath(Application.ExeName);
  LoadLibs;
  av_log_set_callback(@LogCallback);
finalization
  UnloadLibs;
end.

