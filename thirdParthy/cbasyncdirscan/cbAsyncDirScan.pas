unit cbAsyncDirScan;

interface

uses
  ShlObj, ActiveX, Windows, Contnrs, SysUtils, Classes, SyncObjs, Messages;

type
  TcbShellFolder = class;
  TFolderScannedEvent = procedure (Sender: TObject; Folder: TcbShellFolder) of object;


  TcbShellFolder = class
  private
    FParent: TcbShellFolder;
    FInstance: IShellFolder;
    FLocation: PItemIDList;
    FFiles: array of record
      Filename: String;
      Location: PItemIDList;
    end;
    FName,
    FFullPath: String;
    FFileCapacity,
    FFileCount: Integer;
    FFolderList: TObjectList;
    FInvalidEnum: Boolean;

    procedure ClearFiles;
    function GetFileLocations(Idx: Integer): PItemIDList;
    function GetFiles(Idx: Integer): String;
    function GetFolderCount: Integer;
    function GetFolders(Idx: Integer): TcbShellFolder;
    procedure Initialize(Parent: TcbShellFolder; ParentFolder: IShellFolder);
    function IsValidFileExt(const Filename: String;
      FileExtensions: TStrings): Boolean;

  public
    constructor Create(Parent: TcbShellFolder; Location: PItemIDList); overload;
    constructor Create(Parent: TcbShellFolder; Path: WideString); overload;
    destructor Destroy; override;
    procedure Enumerate(MaxLevels: Integer; FileExtensions: TStrings=nil);

    property FileCount: Integer read FFileCount;
    property FileLocations[Idx: Integer]: PItemIDList read GetFileLocations;
    property Files[Idx: Integer]: String read GetFiles;
    property FolderCount: Integer read GetFolderCount;
    property Folders[Idx: Integer]: TcbShellFolder read GetFolders;
    property FullPath: String read FFullPath;
    property Location: PItemIDList read FLocation;
    property Instance: IShellFolder read FInstance;
    property InvalidEnum: Boolean read FInvalidEnum;
    property Name: String read FName;
    property Parent: TcbShellFolder read FParent;
  end;

  TcbAsyncDirScan = class(TThread)
  private
    FFileExtensions: TStringList;
    FTrigger: TEvent;
    FScanMutex: THandle;
    FOnFolderScanned: TFolderScannedEvent;
    FOnScanComplete: TNotifyEvent;
    FScanning: Boolean;
    FScanFolder: TcbShellFolder;
    FMaxLevels: Integer;
    FWindowHandle: THandle;
    FScanId: Word;
    FStopScan: Boolean;

    procedure WndProc(var Msg: TMessage);

  protected
    procedure Execute; override;

  public
    constructor Create;
    destructor Destroy; override;
    procedure Scan(Folder: TcbShellFolder; MaxLevels: Integer;
      FileExtensions: TStrings);
    procedure Stop;

    property OnFolderScanned: TFolderScannedEvent read FOnFolderScanned
      write FOnFolderScanned;
    property OnScanComplete: TNotifyEvent read FOnScanComplete
      write FOnScanComplete;
    property Scanning: Boolean read FScanning;
  end;

function BrowseLocation(WindowHandle: THandle; FolderCSIDL: Integer;
  Flags: DWord; out FolderName: String): Boolean;

  
implementation

const
  conFILE_CAPACITY_INC = 40;
  WM_SCANCOMPLETE = WM_USER + 1;
  WM_FOLDERSCANNED = WM_USER + 2;


var
  gMalloc: IMalloc;
  SHFolderLibHandle: THandle;
  SHGetFolderLocation: function(hwndOwner: THandle; nFolder: Integer;
    hToken: THandle; dwReserved: DWord; out ppidl: PITEMIDLIST): HRESULT; stdcall;


procedure SHCheck(Value: HResult);
var
  ErrInfo: IErrorInfo;
  ErrStr: WideString;
begin
  if Failed(Value) then
  begin
    if (GetErrorInfo(0, ErrInfo) = S_OK) then
    begin
      ErrInfo.GetDescription(ErrStr);
      raise Exception.Create('OLE call error: ' + ErrStr);
    end
    else
      raise Exception.Create('OLE call error: unknown');
  end;
end;

function StrRetToStr(StrRet: TStrRet; APIDL: PItemIDList): string;
var
  P: PChar;
begin
  case StrRet.uType of
    STRRET_CSTR:
      SetString(Result, StrRet.cStr, lStrLen(StrRet.cStr));
    STRRET_OFFSET:
      begin
        if Assigned(APIDL) then
        begin
          P := @(APIDL).mkid.abID[StrRet.uOffset - SizeOf(APIDL.mkid.cb)];
          SetString(Result, P, StrLen(P));
        end else
          Result := '';
      end;
    STRRET_WSTR:
      Result := WideCharToString(StrRet.pOleStr);
  end;
end;

procedure LoadSHFolderLibrary;
begin
  SHFolderLibHandle := LoadLibrary('SHFolder.dll');
  if SHFolderLibHandle <> 0 then
  begin
    SHGetFolderLocation := GetProcAddress(SHFolderLibHandle, 'SHGetFolderLocationA');
  end;
end;

procedure UnloadSHFolderLibrary;
begin
  FreeLibrary(SHFolderLibHandle);
end;

function BrowseLocation(WindowHandle: THandle; FolderCSIDL: Integer;
  Flags: DWord; out FolderName: String): Boolean;
var
  LocationRoot,
  LocationSelected: PItemIdList;
  Bi: TBrowseInfo;
  Filename: array [0..MAX_PATH] of Char;
begin
  if not Assigned(gMalloc) then
    SHCheck(SHGetMalloc(gMalloc));

  if (FolderCSIDL <> 0) and Assigned(SHGetFolderLocation) then
    SHCheck(SHGetFolderLocation(WindowHandle, FolderCSIDL, 0, 0, LocationRoot))
  else
    LocationRoot := nil;

  ZeroMemory(@Bi, SizeOf(Bi));
  Bi.hwndOwner := WindowHandle;
  Bi.pidlRoot := LocationRoot;
  Bi.pszDisplayName := @FileName[0];
  Bi.lpszTitle := 'Choose a folder';
  Bi.ulFlags := Flags;

  LocationSelected := SHBrowseForFolder(Bi);
  Result := Assigned(LocationSelected);

  if Result then
  begin
    SHGetPathFromIDList(LocationSelected, Filename);
    gMalloc.Free(LocationSelected);
    FolderName := Filename;
  end;

  if Assigned(LocationRoot) then
    gMalloc.Free(LocationRoot);
end;

//******** TcbShellFolder

constructor TcbShellFolder.Create(Parent: TcbShellFolder; Location: PItemIDList);
var
  ParentFolder: IShellFolder;
begin
  inherited Create;

  FLocation := Location;

  // get IShellFolder interface
  if Assigned(Parent) then
    ParentFolder := Parent.Instance
  else
    SHCheck(SHGetDesktopFolder(ParentFolder));

  Initialize(Parent, ParentFolder);
end;

constructor TcbShellFolder.Create(Parent: TcbShellFolder; Path: WideString);
var
  DesktopFolder: IShellFolder;
  Eaten,
  Attr: DWord;
begin
  inherited Create;

  SHCheck(SHGetDesktopFolder(DesktopFolder));
  SHCheck(DesktopFolder.ParseDisplayName(0, nil, PWideChar(Path), Eaten, FLocation,
    Attr));

  Initialize(Parent, DesktopFolder);
end;

procedure TcbShellFolder.Initialize(Parent: TcbShellFolder;
  ParentFolder: IShellFolder);
var
  StrDispName: TSTRRET;
begin
  FParent := Parent;

  // get Global Malloc instance
  if not Assigned(gMalloc) then
    SHCheck(SHGetMalloc(gMalloc));

  SHCheck(ParentFolder.BindToObject(FLocation, nil, IID_IShellFolder,
    FInstance));

  FFolderList := TObjectList.Create;

  // get relative and absolute path
  SHCheck(ParentFolder.GetDisplayNameOf(FLocation, SHGDN_NORMAL or SHGDN_FORPARSING,
    StrDispName));
  FFullPath := StrRetToStr(StrDispName, FLocation);

  SHCheck(ParentFolder.GetDisplayNameOf(FLocation, SHGDN_INFOLDER or SHGDN_FORPARSING,
    StrDispName));
  FName := StrRetToStr(StrDispName, FLocation);
end;

destructor TcbShellFolder.Destroy;
begin
  ClearFiles;

  FreeAndNil(FFolderList);

  if Assigned(gMalloc) and Assigned(FLocation) then
    gMalloc.Free(FLocation);

  inherited Destroy;
end;

procedure TcbShellFolder.ClearFiles;
var
  Cnt: Integer;
begin
  FFolderList.Clear;
  
  if Assigned(gMalloc) then
    for Cnt := 0 to FFileCount-1 do
      gMalloc.Free(FFiles[Cnt].Location);

  FFileCount := 0;
end;

procedure TcbShellFolder.Enumerate(MaxLevels: Integer;
  FileExtensions: TStrings);
var
  Enum: IEnumIdList;
  PIdlItems: PItemIDList;
  Fetched: DWord;
  StrDispName: TSTRRET;
  Attr: DWord;
  Cnt: Integer;
  Filename: String;
  Valid: Boolean;
begin
  ClearFiles;

  // enumerate files
  FInvalidEnum := Failed(FInstance.EnumObjects(0, SHCONTF_NONFOLDERS, Enum));
  if FInvalidEnum then
    exit;

  while ((Enum.Next(1, PIdlItems, Fetched) = S_OK) and (Fetched = 1)) do
  begin
    Valid := Succeeded(FInstance.GetDisplayNameOf(PIdlItems, SHGDN_INFOLDER,
      StrDispName));

    if Valid then
    begin
      Filename := StrRetToStr(StrDispName, PIdlItems);

      Valid := IsValidFileExt(Filename, FileExtensions);
    end;

    if Valid then
    begin
      if (FFileCount = FFileCapacity) then
      begin
        Inc(FFileCapacity, conFILE_CAPACITY_INC);
        SetLength(FFiles, FFileCapacity);
      end;
      FFiles[FFileCount].Filename := Filename;
      FFiles[FFileCount].Location := PIdlItems;

      Inc(FFileCount);
    end
    else
      gMalloc.Free(PIdlItems);
  end;

  // enumerate folders
  FInvalidEnum := Failed(FInstance.EnumObjects(0, SHCONTF_FOLDERS, Enum));
  if FInvalidEnum then
  begin
    ClearFiles;
    exit;
  end;

  while ((Enum.Next(1, PIdlItems, Fetched) = S_OK) and (Fetched = 1)) do
  begin
    Attr := SFGAO_FILESYSTEM or SFGAO_FILESYSANCESTOR;
    Valid := Succeeded(FInstance.GetAttributesOf(1, PIdlItems, Attr));

    if Valid and ((Attr and (SFGAO_FILESYSTEM or SFGAO_FILESYSANCESTOR)) =
      (SFGAO_FILESYSTEM or SFGAO_FILESYSANCESTOR)) then
      // add folder
      FFolderList.Add(TcbShellFolder.Create(Self, PIdlItems))
    else
      gMalloc.Free(PIdlItems);
  end;

  // enumerate subfolders
  if (MaxLevels > 0) then
    for Cnt := FFolderList.Count-1 downto 0 do
      TcbShellFolder(FFolderList[Cnt]).Enumerate(MaxLevels-1, FileExtensions);
end;

function TcbShellFolder.GetFileLocations(Idx: Integer): PItemIDList;
begin
  if ((Idx < 0) or (Idx >= FFileCount)) then
    raise Exception.Create('Index out of bounds');

  Result := FFiles[Idx].Location;
end;

function TcbShellFolder.GetFiles(Idx: Integer): String;
begin
  if ((Idx < 0) or (Idx >= FFileCount)) then
    raise Exception.Create('Index out of bounds');

  Result := FFiles[Idx].Filename;
end;

function TcbShellFolder.GetFolderCount: Integer;
begin
  Result := FFolderList.Count;
end;

function TcbShellFolder.GetFolders(Idx: Integer): TcbShellFolder;
begin
  Result := TcbShellFolder(FFolderList[Idx]);
end;

function TcbShellFolder.IsValidFileExt(const Filename: String;
  FileExtensions: TStrings): Boolean;
var
  Cnt: Integer;
  Ext: String;
begin
  if (not Assigned(FileExtensions)) or (FileExtensions.Count = 0) then
    Result := True
  else
  begin
    Result := False;

    Ext := ExtractFileExt(Filename);
    for Cnt := 0 to FileExtensions.Count-1 do
      if (CompareText(Ext, FileExtensions[Cnt]) = 0) then
      begin
        Result := True;
        exit;
      end;
  end;
end;



//******** TcbAsyncDirScan

constructor TcbAsyncDirScan.Create;
begin
  inherited Create(True);

  CoInitializeEx(nil, COINIT_MULTITHREADED);

  FFileExtensions := TStringList.Create;

  FScanMutex := CreateMutex(nil, False, nil);
  FTrigger := TEvent.Create(nil, False, False, '');

  // create window to receive messages from thread
  FWindowHandle := AllocateHWnd(WndProc);

  Resume;
end;

destructor TcbAsyncDirScan.Destroy;
begin
  // stop thread
  Terminate;

  // prevent from receiving any more messages
  Stop;

  //
  if Suspended then
    Resume;

  // wait to finish
  if Assigned(FTrigger) then
  begin
    FTrigger.SetEvent;

    WaitFor;

    FreeAndNil(FTrigger);
  end;
  CloseHandle(FScanMutex);

  if (FWindowHandle <> 0) then
    DeallocateHWnd(FWindowHandle);

  //
  FreeAndNil(FFileExtensions);

  CoUninitialize;

  inherited Destroy;
end;

procedure TcbAsyncDirScan.Execute;
var
  FolderStack,
  LevelStack: TStack;
  CurFolder: TcbShellFolder;
  CurLevel,
  Cnt: Integer;
begin
  FolderStack := nil;
  LevelStack := nil;
  try
    FolderStack := TStack.Create;
    LevelStack := TStack.Create;

    while not Terminated do
    begin
      WaitForSingleObject(FTrigger.Handle, INFINITE);

      if FScanning then
      // execute scan
      begin
        WaitForSingleObject(FScanMutex, INFINITE);
        try
          // set stack with initial folder
          while (FolderStack.Count > 0) do
          begin
            FolderStack.Pop;
            LevelStack.Pop;
          end;
          FolderStack.Push(FScanFolder);
          LevelStack.Push(Pointer(FMaxLevels));

          while (not Terminated) and (not FStopScan) and (FolderStack.Count > 0) do
          begin
            // get folder from stack
            CurFolder := TcbShellFolder(FolderStack.Pop);
            CurLevel := Integer(LevelStack.Pop);

            // enumerate current folder
            CurFolder.Enumerate(0, FFileExtensions);
            PostMessage(FWindowHandle, WM_FOLDERSCANNED, FScanId,
              Integer(CurFolder));

            // insert sub-folders into stack in inverse order
            if (CurLevel > 0) then
              for Cnt := CurFolder.FolderCount-1 downto 0 do
              begin
                FolderStack.Push(CurFolder.Folders[Cnt]);
                LevelStack.Push(Pointer(CurLevel-1));
              end;
          end;

          FScanning := False;
          PostMessage(FWindowHandle, WM_SCANCOMPLETE, FScanId, 0);
        finally
          ReleaseMutex(FScanMutex);
        end;
      end;
    end;
  finally
    LevelStack.Free;
    FolderStack.Free;
  end;
end;

procedure TcbAsyncDirScan.Scan(Folder: TcbShellFolder; MaxLevels: Integer;
  FileExtensions: TStrings);
begin
  if FScanning then
    raise Exception.Create('Trying to scan while another scan is progressing');

  // save parameters
  FScanFolder := Folder;
  FMaxLevels := MaxLevels;

  // set file extensions
  FFileExtensions.Clear;
  if Assigned(FileExtensions) then
    FFileExtensions.AddStrings(FileExtensions);

  // signal thread
  Inc(FScanId);
  FStopScan := False;
  FScanning := True;
  FTrigger.SetEvent;
end;

procedure TcbAsyncDirScan.Stop;
begin
  if not FScanning then
    exit;

  // stop scanning
  FStopScan := True;

  // wait till thread really leaves scanning
  WaitForSingleObject(FScanMutex, INFINITE);
  Inc(FScanId);
  ReleaseMutex(FScanMutex);
end;

procedure TcbAsyncDirScan.WndProc(var Msg: TMessage);
begin
  if (Msg.WParam <> FScanId) then
    // drop old messages
    exit;

  case Msg.Msg of
    WM_SCANCOMPLETE:
      if Assigned(FOnScanComplete) then
        FOnScanComplete(Self);

    WM_FOLDERSCANNED:
      if Assigned(FOnFolderScanned) then
        FOnFolderScanned(Self, TcbShellFolder(Msg.LParam));
  end;
end;


initialization
CoInitializeEx(nil, COINIT_MULTITHREADED);
LoadSHFolderLibrary;


finalization
gMalloc := nil;
UnloadSHFolderLibrary;
CoUninitialize;

end.
