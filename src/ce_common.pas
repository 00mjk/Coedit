unit ce_common;

{$I ce_defines.inc}

interface

uses
  Classes, SysUtils,
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  ActnList, dialogs, forms, process, asyncprocess;

const
  DdiagFilter = 'D source|*.d|D interface|*.di|All files|*.*';
  exeExt = {$IFDEF WINDOWS} '.exe' {$ELSE} ''   {$ENDIF};
  objExt = {$IFDEF WINDOWS} '.obj' {$ELSE} '.o' {$ENDIF};
  libExt = {$IFDEF WINDOWS} '.lib' {$ELSE} '.a' {$ENDIF};

var
  dExtList: TStringList;
  DCompiler: string = 'dmd';

type

  (**
   * MRU list for strings
   *)
  TMRUList = class(TStringList)
  private
    fMaxCount: Integer;
    fObj: TObject;
  protected
    fChecking: boolean;
    procedure clearOutOfRange;
    procedure setMaxCount(aValue: Integer);
    function checkItem(const S: string): boolean; virtual;
    procedure Put(Index: Integer; const S: string); override;
    procedure InsertItem(Index: Integer; const S: string); override;
  published
    property maxCount: Integer read fMaxCount write setMaxCount;
  public
    constructor Create;
    procedure Insert(Index: Integer; const S: string); override;
    property objectTag: TObject read fObj write fObj;
  end;

  (**
   * MRU list for filenames
   *)
  TMRUFileList = class(TMRUList)
  protected
    function checkItem(const S: string): boolean; override;
  public
    procedure assign(src: TPersistent); override;
  end;

  (**
   *  TProcess with assign() 'overriden'.
   *)
  TProcessEx = class helper for TProcess
  public
    procedure Assign(aValue: TPersistent);
  end;

  (**
   * Makes TReader.ReadProperties visible
   *)
  TReaderEx = class helper for TReader
  public
    procedure ReadPersistent(aValue: TPersistent);
  end;

  (**
   * Makes TWriter.WriteProperties visible
   * W
   *)
  TWriterEx = class helper for TWriter
  public
    // works as bin but raises because of 'ObjectBinaryToText'
    procedure WritePersistent(aValue: TPersistent);
  end;

  (**
   * Save a component with a readable aspect.
   *)
  procedure saveCompToTxtFile(const aComp: TComponent; const aFilename: string);

  (**
   * Load a component.
   *)
  procedure loadCompFromTxtFile(const aComp: TComponent; const aFilename: string;
    aPropNotFoundHandler: TPropertyNotFoundEvent = nil; anErrorHandler: TReaderError = nil);

  (**
   * Converts a relative path to an absolute path.
   *)
  function expandFilenameEx(const aBasePath, aFilename: string): string;

  (**
   * Patches the directory separators from a string.
   * This is used to ensure that a project saved on a platform can be loaded
   * on another one.
   *)
  function patchPlateformPath(const aPath: string): string;
  procedure patchPlateformPaths(const sPaths: TStrings);

  (**
   * Patches the file extension from a string.
   * This is used to ensure that a project saved on a platform can be loaded
   * on another one. Note that the ext which are handled are specific to coedit projects.
   *)
  function patchPlateformExt(const aFilename: string): string;

  (**
   * Ok/Cancel modal dialog
   *)
  function dlgOkCancel(const aMsg: string): TModalResult;

  (**
   * Info message
   *)
  function dlgOkInfo(const aMsg: string): TModalResult;

  (**
   * Error message
   *)
  function dlgOkError(const aMsg: string): TModalResult;

  (**
   * Returns an unique object identifier, based on its heap address.
   *)
  function uniqueObjStr(const aObject: Tobject): string;

  (**
   * Reduces a filename if its length is over the threshold defined by charThresh.
   * Even if the result is not usable anymore, it avoids any "visually-overloaded" MRU menu.
   *)
  function shortenPath(const aPath: string; charThresh: Word = 60): string;

  (**
   * Returns the folder Coedit documents and settings.
   *)
  function getDocPath: string;

  (**
   * Fills aList with the names of the files located in aPath.
   *)
  procedure listFiles(const aList: TStrings; const aPath: string; recursive: boolean = false);

  (**
   * Fills aList with the names of the folders located in aPath.
   *)
  procedure listFolders(const aList: TStrings; const aPath: string);

  (**
   * Checks if aPath contains at least one sub-folder.
   *)
  function hasFolder(const aPath: string): boolean;

  (**
   * Fills aList with the system drives.
   *)
  procedure listDrives(const aList: TStrings);

  (**
   * If aPath ends with an asterisk then fills aList with the names of the files located in aPath.
   * Returns true if aPath was 'asterisk-ifyed'.
   *)
  function listAsteriskPath(const aPath: string; const aList: TStrings; const someExts: TStrings = nil): boolean;

  (**
   * Lets the shell open a file
   *)
  function shellOpen(const aFilename: string): boolean;

  (**
   * Returns true if anExeName can be spawn without its full path.
   *)
  function exeInSysPath(anExeName: string): boolean;

  (**
   * Clears then fills aList with aProcess output stream.
   *)
  procedure processOutputToStrings(const aProcess: TProcess; var aList: TStringList);

  (**
   * Terminates and frees aProcess;
   *)
  procedure killProcess(var aProcess: TAsyncProcess);

  (**
   * Ensures that the in/out process pipes are not redirected, that it has a console, if it waits on exit.
   *)
  procedure ensureNoPipeIfWait(const aProcess: TProcess);

implementation

// https://stackoverflow.com/questions/25438091/objectbinarytotext-error-with-a-treader-twriter-helper-class
// http://forum.lazarus.freepascal.org/index.php/topic,25557.0.html
procedure TProcessEx.Assign(aValue: TPersistent);
var
  src: TProcess;
begin
  if aValue is TProcess then
  begin
    src := TProcess(aValue);
    PipeBufferSize := src.PipeBufferSize;
    Active := src.Active;
    Executable := src.Executable;
    Parameters := src.Parameters;
    ConsoleTitle := src.ConsoleTitle;
    CurrentDirectory := src.CurrentDirectory;
    Desktop := src.Desktop;
    Environment := src.Environment;
    Options := src.Options;
    Priority := src.Priority;
    StartupOptions := src.StartupOptions;
    ShowWindow := src.ShowWindow;
    WindowColumns := src.WindowColumns;
    WindowHeight := src.WindowHeight;
    WindowLeft := src.WindowLeft;
    WindowRows := src.WindowRows;
    WindowTop := src.WindowTop;
    WindowWidth := src.WindowWidth;
    FillAttribute := src.FillAttribute;
    XTermProgram := src.XTermProgram;
  end
  else inherited;
end;

procedure TReaderEx.ReadPersistent(aValue: TPersistent);
begin
  ReadListBegin;
  while not EndOfList do
    ReadProperty(aValue);
  ReadListEnd;
end;

procedure TWriterEx.WritePersistent(aValue: TPersistent);
begin
  WriteListBegin;
  WriteProperties(aValue);
  WriteListEnd;
end;

constructor TMRUList.Create;
begin
  fMaxCount := 10;
end;

procedure TMRUList.clearOutOfRange;
begin
  while Count > fMaxCount do
    delete(Count-1);
end;

procedure TMRUList.setMaxCount(aValue: Integer);
begin
  if aValue < 0 then
    aValue := 0;
  if fMaxCount = aValue then
    exit;
  clearOutOfRange;
end;

function TMRUList.checkItem(const S: string): boolean;
var
  i: NativeInt;
begin
  i := indexOf(S);
  if i = -1 then
    exit(true);
  if i = 0 then
    exit(false);
  if Count < 2 then
    exit(false);
  exchange(i, i-1);
  exit( false);
end;

procedure TMRUList.Put(Index: Integer; const S: string);
begin
  if not (checkItem(S)) then
    exit;
  inherited;
  clearOutOfRange;
end;

procedure TMRUList.InsertItem(Index: Integer; const S: string);
begin
  if not (checkItem(S)) then
    exit;
  inherited;
  clearOutOfRange;
end;

procedure TMRUList.Insert(Index: Integer; const S: string);
begin
  if not (checkItem(S)) then
    exit;
  inherited;
  clearOutOfRange;
end;

procedure TMRUFileList.assign(src: TPersistent);
var
  i: NativeInt;
begin
  inherited;
  for i := Count-1 downto 0 do
    if not fileExists(Strings[i]) then
      Delete(i);
end;

function TMRUFileList.checkItem(const S: string): boolean;
begin
  exit( inherited checkItem(S) and fileExists(S));
end;

procedure saveCompToTxtFile(const aComp: TComponent; const aFilename: string);
var
  str1, str2: TMemoryStream;
begin
  str1 := TMemoryStream.Create;
  str2 := TMemoryStream.Create;
  try
    str1.WriteComponent(aComp);
    str1.Position := 0;
    ObjectBinaryToText(str1,str2);
    str2.SaveToFile(aFilename);
  finally
    str1.Free;
    str2.Free;
  end;
end;

procedure loadCompFromTxtFile(const aComp: TComponent; const aFilename: string;
  aPropNotFoundHandler: TPropertyNotFoundEvent = nil; anErrorHandler: TReaderError = nil);
var
  str1, str2: TMemoryStream;
  rdr: TReader;
begin
  str1 := TMemoryStream.Create;
  str2 := TMemoryStream.Create;
  try
    str1.LoadFromFile(aFilename);
    str1.Position := 0;
    ObjectTextToBinary(str1,str2);
    str2.Position := 0;
    try
      rdr := TReader.Create(str2, 4096);
      try
        rdr.OnPropertyNotFound := aPropNotFoundHandler;
        rdr.OnError := anErrorHandler;
        rdr.ReadRootComponent(aComp);
      finally
        rdr.Free;
      end;
    except
    end;
  finally
    str1.Free;
    str2.Free;
  end;
end;

function expandFilenameEx(const aBasePath, aFilename: string): string;
var
  curr: string;
begin
  curr := '';
  getDir(0, curr);
  try
    if curr <> aBasePath then
      chDir(aBasePath);
    result := expandFileName(aFilename);
  finally
    chDir(curr);
  end;
end;

function patchPlateformPath(const aPath: string): string;
function patchProc(const src: string; const invalid: char): string;
var
  i: Integer;
  dir: string;
begin
  dir := ExtractFileDrive(src);
  if length(dir) > 0 then
    result := src[length(dir)+1..length(src)]
  else
    result := src;
  i := pos(invalid, result);
  if i <> 0 then
  begin
    repeat
      result[i] := directorySeparator;
      i := pos(invalid,result);
    until
      i = 0;
  end;
  result := dir + result;
end;
begin
  result := aPath;
  {$IFDEF MSWINDOWS}
  result := patchProc(result, '/');
  result := patchProc(result, ':');
  {$ENDIF}
  {$IFDEF POSIX}
  result := patchProc(result, '\');
  result := patchProc(result, ':');
  {$ENDIF}
end;

procedure patchPlateformPaths(const sPaths: TStrings);
var
  i: Integer;
  str: string;
begin
  for i:= 0 to sPaths.Count-1 do
  begin
    str := sPaths.Strings[i];
    sPaths.Strings[i] := patchPlateformPath(str);
  end;
end;

function patchPlateformExt(const aFilename: string): string;
var
  ext, newext: string;
begin
  ext := extractFileExt(aFilename);
  newext := '';
  result := aFilename[1..length(aFilename)-length(ext)];
  {$IFDEF MSWINDOWS}
  case ext of
    '.so': newext := '.dll';
    '.dylib': newext := '.dll';
    '.a':  newext := '.lib';
    '.o':  newext := '.obj';
    else  newext := ext;
  end;
  {$ENDIF}
  {$IFDEF LINUX}
  case ext of
    '.dll': newext := '.so';
    '.dylib': newext := '.so';
    '.lib': newext := '.a';
    '.obj': newext := '.o';
    '.exe': newext := '';
    else  newext  := ext;
  end;
  {$ENDIF}
  {$IFDEF MACOS}
  case ext of
    '.dll': newext := '.dylib';
    '.so':  newext := '.dylib';
    '.lib': newext := '.a';
    '.obj': newext := '.o';
    '.exe': newext := '';
    else  newext  := ext;
  end;
  {$ENDIF}
  result += newext;
end;

function dlgOkCancel(const aMsg: string): TModalResult;
const
  Btns = [mbOK,mbCancel];
begin
  exit( MessageDlg('Coedit', aMsg, mtConfirmation, Btns, ''));
end;

function dlgOkInfo(const aMsg: string): TModalResult;
const
  Btns = [mbOK];
begin
  exit( MessageDlg('Coedit', aMsg, mtInformation, Btns, ''));
end;

function dlgOkError(const aMsg: string): TModalResult;
const
  Btns = [mbOK];
begin
  exit( MessageDlg('Coedit', aMsg, mtError, Btns, ''));
end;

function uniqueObjStr(const aObject: Tobject): string;
begin
  {$HINTS OFF}{$WARNINGS OFF}
  exit( format('%.8X',[NativeUint(@aObject)]));
  {$HINTS ON}{$WARNINGS ON}
end;

function shortenPath(const aPath: string; charThresh: Word = 60): string;
var
  i: NativeInt;
  sepCnt: NativeInt;
  drv: string;
  pth1: string;
begin
  sepCnt := 0;
  if length(aPath) <= charThresh then
    exit(aPath);

  drv := extractFileDrive(aPath);
  i := length(aPath);
  while(i <> length(drv)+1) do
  begin
    Inc(sepCnt, Byte(aPath[i] = directorySeparator));
    if sepCnt = 2 then
      break;
    Dec(i);
  end;
  pth1 := aPath[i..length(aPath)];
  exit( format('%s%s...%s',[drv,directorySeparator,pth1]) );
end;

function getDocPath: string;
{$IFDEF WINDOWS}
var
  PIDL : PItemIDList;
  Folder : array[0..MAX_PATH] of Char;
const
  CSIDL_APPDATA = $001A;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  PIDL := nil;
  SHGetSpecialFolderLocation(0, CSIDL_APPDATA, PIDL);
  SHGetPathFromIDList(PIDL, Folder);
  result := Folder;
  {$ENDIF}
  {$IFDEF UNIX}
  result := ExpandFileName('~/');
  {$ENDIF}
  result += directorySeparator + 'Coedit' + directorySeparator;
end;

function isFolder(sr: TSearchRec): boolean;
begin
  result := (sr.Name <> '.') and  (sr.Name <> '..' ) and  (sr.Name <> '' ) and
    (sr.Attr and faDirectory = faDirectory);
end;

procedure listFiles(const aList: TStrings; const aPath: string; recursive: boolean = false);
var
  sr: TSearchrec;
procedure tryAdd;
begin
  if sr.Attr and faDirectory <> faDirectory then
    aList.Add(aPath+ directorySeparator + sr.Name);
end;
begin
  if findFirst(aPath + directorySeparator + '*', faAnyFile, sr) = 0 then
  try
    repeat
      tryAdd;
      if recursive then if isFolder(sr) then
        listFiles(aList, aPath + directorySeparator + sr.Name, recursive);
    until
      findNext(sr) <> 0;
  finally
    sysutils.FindClose(sr);
  end;
end;

procedure listFolders(const aList: TStrings; const aPath: string);
var
  sr: TSearchrec;
begin
  if findFirst(aPath + '*', faAnyFile, sr) = 0 then
  try
    repeat if isFolder(sr) then
      aList.Add(aPath + sr.Name);
    until findNext(sr) <> 0;
  finally
    sysutils.FindClose(sr);
  end;
end;

function hasFolder(const aPath: string): boolean;
var
  sr: TSearchrec;
  res: boolean;
begin
  res := false;
  if findFirst(aPath + directorySeparator + '*', faDirectory, sr) = 0 then
  try
    repeat if isFolder(sr) then
    begin
      res := true;
      break;
    end;
    until findNext(sr) <> 0;
  finally
    sysutils.FindClose(sr);
  end;
  result := res;
end;

function listAsteriskPath(const aPath: string; const aList: TStrings; const someExts: TStrings = nil): boolean;
var
  pth, ext, fname: string;
  files: TStringList;
begin
  result := false;
  if aPath = '' then
    exit;
  //
  if aPath[length(aPath)] = '*' then
  begin
    pth := aPath[1..length(aPath)-1];
    if pth[length(pth)] in ['/', '\'] then
      pth := pth[1..length(pth)-1];
    if not directoryExists(pth) then exit(false);
    //
    files := TStringList.Create;
    try
      listFiles(files, pth, true);
      for fname in files do
      begin
        if someExts = nil then
          aList.Add(fname)
        else
        begin
          ext := extractFileExt(fname);
          if someExts.IndexOf(ext) <> -1 then
            aList.Add(fname);
        end;
      end;
    finally
      files.Free;
    end;
    exit(true);
  end;
  exit(false);
end;

procedure listDrives(const aList: TStrings);
{$IFDEF WINDOWS}
var
  drv: char;
  ltr: string;
  {$ENDIF}
begin
  {$IFDEF WINDOWS}
  for drv := 'A' to 'Z' do
  begin
    ltr := drv + ':\';
    case GetDriveType(PChar(ltr)) of
       DRIVE_REMOVABLE,
       DRIVE_FIXED,
       DRIVE_REMOTE: aList.Add(ltr);
    end;
  end;
  {$ENDIF}
  {$IFDEF LINUX}
  // aList.LoadFromFile('/etc/fstab'); // to be parsed
  aList.Add('/home/'); //TODO-cbugfix: AV when scanning non-users folder (e.g replace '/home/'' with '/')
  {$ENDIF}
end;

function shellOpen(const aFilename: string): boolean;
begin
  {$IFDEF WINDOWS}
  result := ShellExecute(0, 'OPEN', PChar(aFilename), nil, nil, SW_SHOW) > 32;
  {$ENDIF}
  {$IFDEF LINUX}
  with TProcess.Create(nil) do
  try
    Executable := 'xdg-open';
    Parameters.Add(aFilename);
    Execute;
  finally
    result := true;
    Free;
  end;
  {$ENDIF}
end;

function exeInSysPath(anExeName: string): boolean;
var
  ext: string;
begin
  ext := extractFileExt(anExeName);
  if ext <> exeExt then
    anExeName += exeExt;
  if FileExists(anExeName) then
    exit(true)
  else
    exit(ExeSearch(anExeName, '') <> '');
end;

procedure processOutputToStrings(const aProcess: TProcess; var aList: TStringList);
var
  str: TMemoryStream;
  sum: Integer;
  cnt: Integer;
const
  buffSz = 1024;
begin
  if not (poUsePipes in aProcess.Options) then
    exit;
  //
  sum := 0;
  str := TMemoryStream.Create;
  try
    while aProcess.Output.NumBytesAvailable <> 0 do begin
      str.Size := str.Size + buffSz;
      cnt := aProcess.Output.Read((str.Memory + sum)^, buffSz);
      sum += cnt;
    end;
    str.Size := sum;
    aList.LoadFromStream(str);
  finally
    str.Free;
  end;
end;

procedure killProcess(var aProcess: TAsyncProcess);
begin
  if aProcess = nil then
    exit;
  if aProcess.Running then
    aProcess.Terminate(0);
  aProcess.Free;
  aProcess := nil;
end;

procedure ensureNoPipeIfWait(const aProcess: TProcess);
begin
  if not (poWaitonExit in aProcess.Options) then
    exit;
  //
  aProcess.Options := aProcess.Options - [poStderrToOutPut, poUsePipes];
  aProcess.Options := aProcess.Options + [poNewConsole];
end;

initialization
  RegisterClasses([TMRUList, TMRUFileList]);
  dExtList := TStringList.Create;
  dExtList.AddStrings(['.d', '.D', '.di', '.DI', '.Di', '.dI']);
finalization
  dExtList.Free;
end.
