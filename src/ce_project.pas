unit ce_project;

{$I ce_defines.inc}

interface

uses
  {$IFDEF DEBUG}
  LclProc,
  {$ENDIF}
  Classes, SysUtils, ce_common, ce_writableComponent ,ce_dmdwrap, ce_libman,
  ce_observer;

type

(*****************************************************************************
 * Represents a D project.
 *
 * It includes all the options defined in ce_dmdwrap, organized in
 * a collection to allow multiples configurations.
 *
 * Basically it' s designed to provide the options for the dmd process.
 *)
  TCEProject = class(TWritableComponent)
  private
    fOnChange: TNotifyEvent;
    fModified: boolean;
    fRootFolder: string;
    fBasePath: string;
    fLibAliases: TStringList;
    fOptsColl: TCollection;
    fSrcs, fSrcsCop: TStringList;
    fConfIx: Integer;
    fLibMan: TLibraryManager;
    fChangedCount: NativeInt;
    fProjectSubject: TCECustomSubject;
    procedure doChanged;
    procedure setLibAliases(const aValue: TStringList);
    procedure subMemberChanged(sender : TObject);
    procedure setOptsColl(const aValue: TCollection);
    procedure setRoot(const aValue: string);
    procedure setSrcs(const aValue: TStringList);
    procedure setConfIx(aValue: Integer);
    function getConfig(const ix: integer): TCompilerConfiguration;
    function getCurrConf: TCompilerConfiguration;
  protected
    procedure afterSave; override;
    procedure afterLoad; override;
    procedure setFilename(const aValue: string); override;
    procedure readerPropNoFound(Reader: TReader; Instance: TPersistent;
      var PropName: string; IsPath: boolean; var Handled, Skip: Boolean); override;
  published
    property RootFolder: string read fRootFolder write setRoot;
    property OptionsCollection: TCollection read fOptsColl write setOptsColl;
    property Sources: TStringList read fSrcs write setSrcs; // 'read' should return a copy to avoid abs/rel errors
    property ConfigurationIndex: Integer read fConfIx write setConfIx;
    property LibraryAliases: TStringList read fLibAliases write setLibAliases;
  public
    constructor create(aOwner: TComponent); override;
    destructor destroy; override;
    procedure beforeChanged;
    procedure afterChanged;
    procedure reset;
    procedure addDefaults;
    function getAbsoluteSourceName(const aIndex: integer): string;
    function getAbsoluteFilename(const aFilename: string): string;
    procedure addSource(const aFilename: string);
    function addConfiguration: TCompilerConfiguration;
    procedure getOpts(const aList: TStrings);
    function outputFilename: string;
    //
    property libraryManager: TLibraryManager read fLibMan write fLibMan;
    property configuration[ix: integer]: TCompilerConfiguration read getConfig;
    property currentConfiguration: TCompilerConfiguration read getCurrConf;
    property onChange: TNotifyEvent read fOnChange write fOnChange;
    property modified: boolean read fModified;
  end;

implementation

uses
  ce_interfaces, controls, dialogs;

constructor TCEProject.create(aOwner: TComponent);
begin
  inherited create(aOwner);
  fProjectSubject := TCEProjectSubject.create;
  //
  fLibAliases := TStringList.Create;
  fSrcs := TStringList.Create;
  fSrcs.OnChange := @subMemberChanged;
  fSrcsCop := TStringList.Create;
  fOptsColl := TCollection.create(TCompilerConfiguration);
  //
  reset;
  addDefaults;
  subjProjChanged(TCEProjectSubject(fProjectSubject), self);
  //
  fModified := false;
end;

destructor TCEProject.destroy;
begin
  subjProjClosing(TCEProjectSubject(fProjectSubject), self);
  fProjectSubject.Free;
  //
  fOnChange := nil;
  fLibAliases.Free;
  fSrcs.free;
  fSrcsCop.Free;
  fOptsColl.free;
  inherited;
end;

function TCEProject.addConfiguration: TCompilerConfiguration;
begin
  result := TCompilerConfiguration(fOptsColl.Add);
  result.onChanged := @subMemberChanged;
end;

procedure TCEProject.setOptsColl(const aValue: TCollection);
var
  i: nativeInt;
begin
  fOptsColl.Assign(aValue);
  for i:= 0 to fOptsColl.Count-1 do
    Configuration[i].onChanged := @subMemberChanged;
end;

procedure TCEProject.addSource(const aFilename: string);
var
  relSrc, absSrc: string;
begin
  for relSrc in fSrcs do
  begin
    absSrc := expandFilenameEx(fBasePath,relsrc);
    if aFilename = absSrc then exit;
  end;
  fSrcs.Add(ExtractRelativepath(fBasePath,aFilename));
end;

procedure TCEProject.setRoot(const aValue: string);
begin
  if fRootFolder = aValue then exit;
  beforeChanged;
  fRootFolder := aValue;
  afterChanged;
end;

procedure TCEProject.setFilename(const aValue: string);
var
  oldAbs, newRel, oldBase: string;
  i: NativeInt;
begin
  if fFilename = aValue then exit;
  //
  beforeChanged;

  fFilename := aValue;
  oldBase := fBasePath;
  fBasePath := extractFilePath(fFilename);
  //
  for i:= 0 to fSrcs.Count-1 do
  begin
    oldAbs := expandFilenameEx(oldBase,fSrcs[i]);
    newRel := ExtractRelativepath(fBasePath, oldAbs);
    fSrcs[i] := newRel;
  end;
  //
  afterChanged;
end;

procedure TCEProject.setLibAliases(const aValue: TStringList);
begin
  beforeChanged;
  fLibAliases.Assign(aValue);
  afterChanged;
end;

procedure TCEProject.setSrcs(const aValue: TStringList);
begin
  beforeChanged;
  fSrcs.Assign(aValue);
  patchPlateformPaths(fSrcs);
  afterChanged;
end;

procedure TCEProject.setConfIx(aValue: Integer);
begin
  beforeChanged;
  if aValue < 0 then aValue := 0;
  if aValue > fOptsColl.Count-1 then aValue := fOptsColl.Count-1;
  fConfIx := aValue;
  afterChanged;
end;

procedure TCEProject.subMemberChanged(sender : TObject);
begin
  beforeChanged;
  fModified := true;
  afterChanged;
end;

procedure TCEProject.beforeChanged;
begin
  Inc(fChangedCount);
end;

procedure TCEProject.afterChanged;
begin
  Dec(fChangedCount);
  if fChangedCount > 0 then
  begin
    {$IFDEF DEBUG}
    DebugLn('project update count > 0');
    {$ENDIF}
    exit;
  end;
  fChangedCount := 0;
  doChanged;
end;

procedure TCEProject.doChanged;
{$IFDEF DEBUG}
var
  lst: TStringList;
{$ENDIF}
begin
  fModified := true;
  subjProjChanged(TCEProjectSubject(fProjectSubject), self);
  if assigned(fOnChange) then fOnChange(Self);
  {$IFDEF DEBUG}
  lst := TStringList.Create;
  try
    lst.Add('---------begin----------');
    getOpts(lst);
    lst.Add('---------end-----------');
    DebugLn(lst.Text);
  finally
    lst.Free;
  end;
  {$ENDIF}
end;

function TCEProject.getConfig(const ix: integer): TCompilerConfiguration;
begin
  result := TCompilerConfiguration(fOptsColl.Items[ix]);
  result.onChanged := @subMemberChanged;
end;

function TCEProject.getCurrConf: TCompilerConfiguration;
begin
  result := TCompilerConfiguration(fOptsColl.Items[fConfIx]);
end;

procedure TCEProject.addDefaults;
begin
  with TCompilerConfiguration(fOptsColl.Add) do
  begin
    Name := 'debug';
    debugingOptions.debug := true;
    debugingOptions.addCInformations := true;
  end;
  with TCompilerConfiguration(fOptsColl.Add) do
  begin
    Name := 'unittest';
    outputOptions.unittest := true;
  end;
  with TCompilerConfiguration(fOptsColl.Add) do
  begin
    Name := 'release';
    outputOptions.release := true;
    outputOptions.inlining := true;
    outputOptions.boundsCheck := offAlways;
    outputOptions.optimizations := true;
  end;
end;

procedure TCEProject.reset;
var
  defConf: TCompilerConfiguration;
begin
  beforeChanged;
  fConfIx := 0;
  fOptsColl.Clear;
  defConf := addConfiguration;
  defConf.name := 'default';
  fSrcs.Clear;
  fFilename := '';
  afterChanged;
  fModified := false;
end;

function TCEProject.outputFilename: string;
begin
  result := currentConfiguration.pathsOptions.outputFilename;
  if result <> '' then
  begin
    if not fileExists(result) then
      result := getAbsoluteFilename(result);
    exit;
  end;
  result := extractFilename(Sources.Strings[0]);
  result := result[1..length(result) - length(extractFileExt(result))];
  result := extractFilePath(fileName) + DirectorySeparator + result + exeExt;
end;

procedure TCEProject.getOpts(const aList: TStrings);
var
  rel, abs: string;
begin
  if fConfIx = -1 then exit;
  for rel in fSrcs do if rel <> '' then
  begin
    abs := expandFilenameEx(fBasePath,rel);
    aList.Add(abs); // process.inc ln 249. double quotes are added if there's a space.
  end;
  //
  if fLibMan <> nil then
  begin
    fLibMan.getLibFiles(fLibAliases, aList);
    fLibMan.getLibSources(fLibAliases, aList);
  end;
  //
  TCompilerConfiguration(fOptsColl.Items[fConfIx]).getOpts(aList);
end;

function TCEProject.getAbsoluteSourceName(const aIndex: integer): string;
begin
  if aIndex < 0 then exit('');
  if aIndex > fSrcs.Count-1 then exit('');
  result := expandFileNameEx(fBasePath, fSrcs.Strings[aIndex]);
end;

function TCEProject.getAbsoluteFilename(const aFilename: string): string;
begin
  result := expandFileNameEx(fBasePath, aFilename);
end;

procedure TCEProject.afterSave;
begin
  fModified := false;
end;

procedure TCEProject.afterLoad;
var
  i, j: Integer;
  src, ini, newdir: string;
  hasPatched: boolean;
begin
  patchPlateformPaths(fSrcs);
  doChanged;
  fModified := false;
  hasPatched := false;

  // patch location: this only works when the project file is moved.
  // if the source structure changes this doesn't help much.
  // if both appends then the project must be restarted from scratch.
  for i := 0 to fSrcs.Count-1 do
  begin
    src := getAbsoluteSourceName(i);
    if fileExists(src) then
      continue;
    if ce_common.dlgOkCancel(
      'The project source(s) point to invalid file(s). ' + LineEnding +
      'This can be encountered if the project file has been moved from its original location.' + LineEnding + LineEnding +
      'Do you wish to select the new root folder ?') <> mrOk then
        exit;
    // hint for the common dir
    src := fSrcs.Strings[i];
    while (src[1] = '.') or (src[1] = DirectorySeparator) do
        src := src[2..length(src)];
    // prompt
    ini := extractFilePath(fFilename);
    if not selectDirectory( format('select the folder (which contains "%s")',[src]), ini, newdir) then
      exit;
    // patch
    for j := i to fSrcs.Count-1 do
    begin
      src := fSrcs.Strings[j];
      while (src[1] = '.') or (src[1] = DirectorySeparator) do
        src := src[2..length(src)];
      if fileExists(expandFilenameEx(fBasePath, newdir + DirectorySeparator + src)) then
        fSrcs.Strings[j] := ExtractRelativepath(fBasePath, newdir + DirectorySeparator + src)
      else break; // next pass: patch from another folder.
    end;
    hasPatched := true;
  end;
  //
  if hasPatched then begin
    saveToFile(fFilename);
    // warning for other relative paths
    if fileExists(getAbsoluteSourceName(0)) then
      ce_common.dlgOkInfo('the main sources paths has been patched, some others invalid ' +
      'paths may still exists (-of, -od, etc.) but cannot be automatically handled');
  end;
end;

procedure TCEProject.readerPropNoFound(Reader: TReader; Instance: TPersistent;
      var PropName: string; IsPath: boolean; var Handled, Skip: Boolean);
//var
  //idt: string;
  //curr: TCompilerConfiguration;
begin
  // continue loading: this method ensures the project compat. in case of drastic changes.

  {curr := self.configuration[OptionsCollection.Count-1];
  if PropName = 'debugIdentifier' then
  begin
    idt := Reader.ReadUnicodeString; // next prop starts one char too late
    if curr.debugingOptions.debugIdentifiers.IndexOf(idt) = -1 then
      curr.debugingOptions.debugIdentifiers.Add(idt);
    Skip := true;
    Handled := true;
  end
  else if PropName = 'versionIdentifier' then
  begin
    idt := Reader.ReadString; // next prop starts one char too late
    if curr.outputOptions.versionIdentifiers.IndexOf(idt) = -1 then
      curr.outputOptions.versionIdentifiers.Add(idt);
    Skip := true;
    Handled := true;
    exit;
  end
  else}
  begin
    Skip := true;
    Handled := false;
  end;
end;

initialization
  RegisterClasses([TCEProject]);
end.
