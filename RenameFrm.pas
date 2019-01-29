unit RenameFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.UITypes, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TRenameForm = class(TForm)
    EdtRename: TEdit;
    BtnRename: TButton;
    BtnCancel: TButton;
    LblStatus: TLabel;
    EdtExt: TEdit;
    procedure BtnRenameClick(Sender: TObject);
    procedure BtnCancelClick(Sender: TObject);
    procedure EdtRenameKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  RenameForm: TRenameForm;
  ext: string;


implementation

{$R *.dfm}

uses AboutForm, MainForm, MainSettings;

procedure TRenameForm.BtnCancelClick(Sender: TObject);
begin
          //Close the Dialog
          Close;
end;

procedure TRenameForm.BtnRenameClick(Sender: TObject);
 var
   CurrentPos: integer;
begin
        //Get the Extension
        ext := EdtExt.Text;
        //Initilize CurrentPos
        CurrentPos := 0;
        //Rename the File
        with Media_Cleaner.FileListBox1 do begin

          //Check before hand if the target file exists
          If System.SysUtils.FileExists(Directory + pathdelim + EdtRename.Text+Ext) Then
            Begin
              //File is already there ask for a new name
              MessageDlg('The file "'+EdtRename.Text+Ext+'" already exists', mtError, [mbOK], 0, mbOK);
              exit;
            End;
          Media_Cleaner.CheckCurItem;
           if CurItem then Begin
             //If It is the current Item then free the FilterGraph
                        CurrentPos := Media_Cleaner.FilterGraph.Position;
                        Media_Cleaner.FilterGraph.Active := false;
             end;
          if not RenameFile(Directory + pathdelim + Items[RenIndex], Directory + pathdelim + EdtRename.Text+Ext)  then begin
          //If file rename failed then report the error
          ShowMessage('An error has occurred while renaming the file');
          //Show the status at the main form
          Media_Cleaner.LblStatus.Caption := 'Error:';
          Media_Cleaner.LblFile.Caption := 'An error has occurred while renaming the file';
          //Update the Current Item
          Media_Cleaner.UpdateCurItem;
          end else Begin
            //Rename was OK then update the Current Item
            //to match the new file name
            Media_Cleaner.FileListBox1.Items.Strings[Media_Cleaner.FileListBox1.ItemIndex] := (EdtRename.Text+Ext);
            //Show the status at the main form
            Media_Cleaner.LblStatus.Caption := 'File Renamed To:';
            Media_Cleaner.LblFile.Caption := (EdtRename.Text + Ext);
            //Update the Current Item
            Media_Cleaner.UpdateCurItem;
          End;
                  //If the current Item was renamed then Re-Initialize FilterGraph
                  if CurItem then
                  begin
                      Media_Cleaner.FormShow(sender);
                      Media_Cleaner.BtnPlayClick(sender);
                      Media_Cleaner.FilterGraph.Position := CurrentPos;
                    end else
                  begin
                    //Do nothing
                  end;
            //Close the Rename Dialog
            Close;
        end;
end;

procedure TRenameForm.EdtRenameKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
      //If enter key is pressed then Rename File
      if Key = VK_RETURN then
      BtnRenameClick(sender);
end;

procedure TRenameForm.FormShow(Sender: TObject);
begin
      //Set Focus to the EdtRename
      EdtRename.SetFocus;
end;

end.
