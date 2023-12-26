unit TestMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ShlObj, cbAsyncDirScan, ActiveX, ComCtrls, Contnrs;

type
  TForm1 = class(TForm)
    Button2: TButton;
    TreeView1: TTreeView;
    ListBox1: TListBox;
    StatusBar1: TStatusBar;
    Edit1: TEdit;
    Label1: TLabel;
    Button1: TButton;
    Button3: TButton;
    Label2: TLabel;
    Edit2: TEdit;
    Label3: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    FAsyncScan: TcbAsyncDirScan;
    FScanFolder: TcbShellFolder;

    function FindTreeParent(Folder: TcbShellFolder): TTreeNode;
    procedure OnScanComplete(Sender: TObject);
    procedure OnFolderScanned(Sender: TObject; Folder: TcbShellFolder);

  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.OnScanComplete(Sender: TObject);
begin
  ShowMessage('done');
end;

function TForm1.FindTreeParent(Folder: TcbShellFolder): TTreeNode;
var
  Stack: TStack;
begin
  Result := TreeView1.Items.GetFirstNode;

  Stack := TStack.Create;
  try
    // push folder hierarchy to stack
    while Assigned(Folder.Parent) do
    begin
      Stack.Push(Folder.Parent);
      Folder := Folder.Parent;
    end;

    // for each folder search treeview node
    while (Stack.Count > 0) do
    begin
      Folder := Stack.Pop;
      while (Result <> nil) and (Result.Data <> Folder) do
        Result := Result.GetNext;

      Assert(Assigned(Result), 'folder not found in treeview');
    end;
  finally
    Stack.Free;
  end;
end;

procedure TForm1.OnFolderScanned(Sender: TObject; Folder: TcbShellFolder);
var
  T: TTreeNode;
begin
  StatusBar1.SimpleText := '"' + Folder.FullPath + '" scanned';

  T := FindTreeParent(Folder);

  TreeView1.Items.AddChildObject(T, Folder.Name, Folder);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FAsyncScan := TcbAsyncDirScan.Create;
  FAsyncScan.OnFolderScanned := OnFolderScanned;
  FAsyncScan.OnScanComplete := OnScanComplete;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FAsyncScan.Free;
  FScanFolder.Free;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  SL: TStringList;
  Cnt: Integer;
begin
  if not FAsyncScan.Scanning then
  begin
    FreeAndNil(FScanFolder);
    TreeView1.Items.Clear;
    FScanFolder := TcbShellFolder.Create(nil, Edit1.Text);

    SL := TStringList.Create;
    ExtractStrings([';'], [], PChar(Edit2.Text), SL);
    for Cnt := SL.Count-1 downto 0 do
    begin
      if (SL[Cnt][1] <> '.') then
        SL.Delete(Cnt)
      else
        if (SL[Cnt] = '.*') then
        begin
          SL.Clear;
          break;
        end;
    end;

    FAsyncScan.Scan(FScanFolder, 30, SL);
    SL.Free;
  end;
end;

procedure TForm1.TreeView1Change(Sender: TObject; Node: TTreeNode);
var
  Cnt: Integer;
  Folder: TcbShellFolder;
begin
  Folder := TcbShellFolder(Node.Data);

  ListBox1.Items.Clear;
  for Cnt := 0 to Folder.FileCount-1 do
    ListBox1.Items.Add(Folder.Files[Cnt]);
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  FolderName: String;
begin
  if BrowseLocation(Handle, 0, BIF_RETURNONLYFSDIRS, FolderName) then
    Edit1.Text := FolderName;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  FAsyncScan.Stop;
end;

end.
