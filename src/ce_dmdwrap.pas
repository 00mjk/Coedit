unit ce_dmdwrap;

{$I ce_defines.inc}

interface

uses
  classes, sysutils, process, asyncprocess, ce_common, ce_inspectors;

(*

procedure to add a new compiler option:
- the option must be published with a setter proc, in the setter 'doChanged' must be called.
- getOpts must be updated to generate the new option.
- Assign() must be updated to copy the new option. (used when cloning a configuration)

*)

type

  (*****************************************************************************
   * Base class designed to encapsulate some compiler options.
   * A descendant must be able to generate the related options
   * as a string representing the partial switches/arguments.
   *)
  TOptsGroup = class(TPersistent)
  private
    fOnChange: TNotifyEvent;
    procedure doChanged;
  protected
    property onChange: TNotifyEvent read fOnChange write fOnChange;
  public
    procedure getOpts(const aList: TStrings); virtual; abstract;
  end;

  (*****************************************************************************
   * Encapsulates the options/args related to the DDoc and JSON generation.
   *)
  TDocOpts = class(TOptsGroup)
  private
    fGenDoc: boolean;
    fDocDir: TCEPathname;
    fGenJson: boolean;
    fJsonFname: TCEFilename;
    procedure setGenDoc(const aValue: boolean);
    procedure setGenJSON(const aValue: boolean);
    procedure setDocDir(const aValue: TCEPathname);
    procedure setJSONFile(const aValue: TCEFilename);
  published
    property generateDocumentation: boolean read fGenDoc write setGenDoc default false;
    property generateJSON: boolean read fGenJson write setGenJSON default false;
    property DocumentationDirectory: TCEPathname read fDocDir write setDocDir;
    property JSONFilename: TCEFilename read fJsonFname write setJSONFile;
  public
    procedure assign(aValue: TPersistent); override;
    procedure getOpts(const aList: TStrings); override;
  end;


  (*****************************************************************************
   * Describes the different depreciation treatments.
   *)
  TDepHandling = (silent, warning, error);

  (*****************************************************************************
   * Encapsulates the options/args related to the compiler output messages.
   *)
  TMsgOpts = class(TOptsGroup)
  private
    fDepHandling : TDepHandling;
    fVerb: boolean;
    fWarn: boolean;
    fWarnEx: boolean;
    fVtls: boolean;
    fQuiet: boolean;
    fVgc: boolean;
    fCol: boolean;
    procedure setDepHandling(const aValue: TDepHandling);
    procedure setVerb(const aValue: boolean);
    procedure setWarn(const aValue: boolean);
    procedure setWarnEx(const aValue: boolean);
    procedure setVtls(const aValue: boolean);
    procedure setQuiet(const aValue: boolean);
    procedure setVgc(const aValue: boolean);
    procedure setCol(const aValue: boolean);
  published
    property depreciationHandling: TDepHandling read fDepHandling write setDepHandling default warning;
    property verbose: boolean read fVerb write setVerb default false;
    property warnings: boolean read fWarn write setWarn default true;
    property additionalWarnings: boolean read fWarnEx write setWarnEx default false;
    property tlsInformations: boolean read fVtls write setVtls default false;
    property quiet: boolean read fQuiet write setQuiet default false;
    property showHiddenAlloc: boolean read fVgc write setVgc default false;
    property showColumnsNumber: boolean read fCol write setCol default false;
  public
    constructor create;
    procedure assign(aValue: TPersistent); override;
    procedure getOpts(const aList: TStrings); override;
  end;

  (**
   * Describes the target registry size.
   *)
  TTargetSystem = (auto, os32bit, os64bit);

  (**
   * Describes the output kind.
   *)
  TBinaryKind = (executable, staticlib, sharedlib, obj);

  (**
   * Describes the bounds check kinds.
   *)
  TBoundCheckKind = (onAlways, safeOnly, offAlways);

  (*****************************************************************************
   * Encapsulates the options/args related to the analysis & the code gen.
   *)
  TOutputOpts = class(TOptsGroup)
  private
    fTrgKind: TTargetSystem;
    fBinKind: TBinaryKind;
    fUt: boolean;
    fVerIds: TStringList;
    fInline: boolean;
    fBoundsCheck: TBoundCheckKind;
    fNoBounds: boolean;
    fOptimz: boolean;
    fGenStack: boolean;
    fMain: boolean;
    fRelease: boolean;
    fAllInst: boolean;
    fStackStomp: boolean;
    procedure depPatch;
    procedure setAllInst(const aValue: boolean);
    procedure setUt(const aValue: boolean);
    procedure setTrgKind(const aValue: TTargetSystem);
    procedure setBinKind(const aValue: TBinaryKind);
    procedure setInline(const aValue: boolean);
    procedure setBoundsCheck(const aValue: TBoundCheckKind);
    procedure setNoBounds(const aValue: boolean);
    procedure setOptims(const aValue: boolean);
    procedure setGenStack(const aValue: boolean);
    procedure setMain(const aValue: boolean);
    procedure setRelease(const aValue: boolean);
    procedure setVerIds(const aValue: TStringList);
    procedure setStackStomp(const aValue: boolean);
  published
    property targetKind: TTargetSystem read fTrgKind write setTrgKind default auto;
    property binaryKind: TBinaryKind read fBinKind write setBinKind default executable;
    property inlining: boolean read fInline write setInline default false;
    property noBoundsCheck: boolean read fNoBounds write setNoBounds stored false default false;
    property boundsCheck: TBoundCheckKind read fBoundsCheck write setBoundsCheck default safeOnly;
    property optimizations: boolean read fOptimz write setOptims default false;
    property generateStackFrame: boolean read fGenStack write setGenStack default false;
    property addMain: boolean read fMain write setMain default false;
    property release: boolean read fRelease write setRelease default false;
    property unittest: boolean read fUt write setUt default false;
    property versionIdentifiers: TStringList read fVerIds write setVerIds;
    property generateAllTmpCode: boolean read fAllInst write setAllInst default false;
    property addStackStompCode: boolean read fStackStomp write setStackStomp default false;
  public
    constructor create;
    destructor destroy; override;
    procedure assign(aValue: TPersistent); override;
    procedure getOpts(const aList: TStrings); override;
  end;

  (*****************************************************************************
   * Encapsulates the options/args related to the debugging
   *)
  TDebugOpts = class(TOptsGroup)
  private
    fDbg: boolean;
    fDbgD: boolean;
    fDbgC: boolean;
    fMap: boolean;
    fDbgIdents: TStringList;
    fDbgLevel: Integer;
    fForceDbgBool: boolean;
    procedure updateForceDbgBool;
    procedure setDbg(const aValue: boolean);
    procedure setDbgD(const aValue: boolean);
    procedure setDbgC(const aValue: boolean);
    procedure setMap(const aValue: boolean);
    procedure setDbgLevel(const aValue: Integer);
    procedure setDbgIdents(const aValue: TStringList);
  published
    property debug: boolean read fDbg write setDbg default false;
    property debugIdentifiers: TStringList read fDbgIdents write setDbgIdents;
    property debugLevel: Integer read fDbgLevel write setDbgLevel default 0;
    property addDInformations: boolean read fDbgD write setDbgD stored false; deprecated;
    property addCInformations: boolean read fDbgC write setDbgC stored false; deprecated;
    property codeviewDexts: boolean read fDbgD write setDbgD default false;
    property codeviewCformat: boolean read fDbgC write setDbgC default false;
    property generateMapFile: boolean read fMap write setMap default false;
  public
    constructor create;
    destructor destroy; override;
    procedure assign(aValue: TPersistent); override;
    procedure getOpts(const aList: TStrings); override;
  end;

  (*****************************************************************************
   * Encapsulates the options/args related to the output and include paths
   *)
  TPathsOpts = class(TOptsGroup)
  private
    fExtraSrcs: TStringList;
    fIncl: TStringList;
    fImpt: TStringList;
    fExcl: TStringList;
    fFname: TCEFilename;
    fObjDir: TCEPathname;
    procedure setFname(const aValue: TCEFilename);
    procedure setObjDir(const aValue: TCEPathname);
    procedure setSrcs(aValue: TStringList);
    procedure setIncl(aValue: TStringList);
    procedure setImpt(aValue: TStringList);
    procedure setExcl(aValue: TStringList);
    procedure strLstChange(sender: TObject);
  published
    property outputFilename: TCEFilename read fFname write setFname;
    property objectDirectory: TCEPathname read fObjDir write setObjDir;
    property Sources: TStringList read fExtraSrcs write setSrcs stored false; deprecated;
    property exclusions: TStringList read fExcl write setExcl;
    property extraSources: TStringList read fExtraSrcs write setSrcs;
    property includes: TStringList read fIncl write setIncl; deprecated;
    property imports: TStringList read fImpt write setImpt; deprecated;
    property importModulePaths: TStringList read fIncl write setIncl;
    property importStringPaths: TStringList read fImpt write setImpt;
  public
    constructor create;
    destructor destroy; override;
    procedure assign(aValue: TPersistent); override;
    procedure getOpts(const aList: TStrings); override;
  end;

  (*****************************************************************************
   * Encapsulates the unclassified and custom options/args
   *)
  TOtherOpts = class(TOptsGroup)
  private
    fCustom: TStringList;
    procedure setCustom(const aValue: TStringList);
  published
    property customOptions: TStringList read fCustom write setCustom;
  public
    constructor create;
    destructor destroy; override;
    procedure assign(aValue: TPersistent); override;
    procedure getOpts(const aList: TStrings); override;
  end;

  (*****************************************************************************
   * Encapsulates the most common TProcess options.
   * Used to simplify pre/post-compilation and run process options.
   *)
  TCustomProcOptions = class(TOptsGroup)
  private
    fExecutable: TCEFilename;
    fWorkDir: TCEPathname;
    fOptions: TProcessOptions;
    fParameters: TStringList;
    fShowWin: TShowWindowOptions;
    procedure setExecutable(const aValue: TCEFilename);
    procedure setWorkDir(const aValue: TCEPathname);
    procedure setOptions(const aValue: TProcessOptions);
    procedure setParameters(aValue: TStringList);
    procedure setShowWin(const aValue: TShowWindowOptions);
  protected
    property executable: TCEFilename read fExecutable write setExecutable;
    property workingDirectory: TCEPathname read fWorkDir write setWorkDir;
    property options: TProcessOptions read fOptions write setOptions;
    property parameters: TStringList read fParameters write setParameters;
    property showWindow: TShowWindowOptions read fShowWin write setShowWin;
  public
    constructor create;
    destructor destroy; override;
    procedure assign(source: TPersistent); override;
    procedure getOpts(const aList: TStrings); override;
    { TAsyncProcess "Parameters" inherits from UTF8 process,
      and the property reader is not anymore "fParameters" but "fUTF8Parameters"
      without the overload aProcess does not get the Parameters if aProcess is TAsynProcess...}
    procedure setProcess(var aProcess: TProcess);
    procedure setProcess(var aProcess: TAsyncProcess);
    procedure setProcess(var aProcess: TCheckedAsyncProcess);
  end;

  (*****************************************************************************
   * Encapsulates the options for the pre/post compilation processes
   *)
  TCompileProcOptions = class(TCustomProcOptions)
  published
    property executable;
    property workingDirectory;
    property options;
    property parameters;
    property showWindow;
  end;

  (*****************************************************************************
   * Encapsulates the options for the project run process.
   * 'executable' prop is hidden since it's defined by the project.
   *)
  TProjectRunOptions = class(TCustomProcOptions)
  published
    property workingDirectory;
    property options;
    property parameters;
    property showWindow;
  end;

  (*****************************************************************************
   * Encapsulates all the contextual options/args
   *)
  TCompilerConfiguration = class(TCollectionItem)
  private
    fName: string;
    fOnChanged: TNotifyEvent;
    fDocOpts: TDocOpts;
    fDebugOpts: TDebugOpts;
    fMsgOpts: TMsgOpts;
    fOutputOpts: TOutputOpts;
    fPathsOpts: TPathsOpts;
    fOthers: TOtherOpts;
    fPreProcOpt: TCompileProcOptions;
    fPostProcOpt: TCompileProcOptions;
    fRunProjOpt: TProjectRunOptions;
    procedure doChanged;
    procedure subOptsChanged(sender: TObject);
    procedure setName(const aValue: string);
    procedure setDocOpts(const aValue: TDocOpts);
    procedure setDebugOpts(const aValue: TDebugOpts);
    procedure setMsgOpts(const aValue: TMsgOpts);
    procedure setOutputOpts(const aValue: TOutputOpts);
    procedure setPathsOpts(const aValue: TPathsOpts);
    procedure setOthers(const aValue: TOtherOpts);
    procedure setPreProcOpt(const aValue: TCompileProcOptions);
    procedure setPostProcOpt(const aValue: TCompileProcOptions);
    procedure setRunProjOpt(const aValue: TProjectRunOptions);
  protected
    function nameFromID: string;
  published
    property name: string read fName write setName;
    property documentationOptions: TDocOpts read fDocOpts write setDocOpts;
    property debugingOptions: TDebugOpts read fDebugOpts write setDebugOpts;
    property messagesOptions: TMsgOpts read fMsgOpts write setMsgOpts;
    property outputOptions: TOutputOpts read fOutputOpts write setOutputOpts;
    property pathsOptions: TPathsOpts read fPathsOpts write setPathsOpts;
    property otherOptions: TOtherOpts read fOthers write setOthers;
    property preBuildProcess: TCompileProcOptions read fPreProcOpt write setPreProcOpt;
    property postBuildProcess: TCompileProcOptions read fPostProcOpt write setPostProcOpt;
    property runOptions: TProjectRunOptions read fRunProjOpt write setRunProjOpt;
  public
    constructor create(aCollection: TCollection); override;
    destructor destroy; override;
    procedure assign(aValue: TPersistent); override;
    procedure getOpts(const aList: TStrings);
    property onChanged: TNotifyEvent read fOnChanged write fOnChanged;
  end;

implementation

uses
  ce_symstring;

procedure TOptsGroup.doChanged;
begin
  if assigned(fOnChange) then fOnChange(self);
end;

{$REGION TDocOpts --------------------------------------------------------------}
procedure TDocOpts.getOpts(const aList: TStrings);
begin
  if fGenDoc then
    aList.Add('-D');
  if fGenJson then
    aList.Add('-X');
  if fDocDir <> '' then
    aList.Add('-Dd' + symbolExpander.get(fDocDir));
  if fJsonFname <> '' then
    aList.Add('-Xf' + symbolExpander.get(fJsonFname));
end;

procedure TDocOpts.assign(aValue: TPersistent);
var
  src: TDocOpts;
begin
  if (aValue is TDocOpts) then
  begin
    src       := TDocOpts(aValue);
    fGenDoc   := src.fGenDoc;
    fGenJson  := src.fGenJson;
    fDocDir   := patchPlateformPath(src.fDocDir);
    fJsonFname:= patchPlateformPath(src.fJsonFname);
  end
  else inherited;
end;

procedure TDocOpts.setGenDoc(const aValue: boolean);
begin
  if fDocDir <> '' then
  begin
    fGenDoc := true;
    exit;
  end;
  //
  if fGenDoc = aValue then
    exit;
  fGenDoc := aValue;
  doChanged;
end;

procedure TDocOpts.setGenJSON(const aValue: boolean);
begin
  if fJsonFname <> '' then
  begin
    fGenJson := true;
    exit;
  end;
  //
  if fGenJson = aValue then
    exit;
  fGenJson := aValue;
  doChanged;
end;

procedure TDocOpts.setDocDir(const aValue: TCEPathname);
begin
  if fDocDir = aValue then
    exit;
  fDocDir := patchPlateformPath(aValue);
  if fDocDir <> '' then
    setGenDoc(true);
  doChanged;
end;

procedure TDocOpts.setJSONFile(const aValue: TCEFilename);
begin
  if fJsonFname = aValue then
    exit;
  fJsonFname := patchPlateformPath(aValue);
  if fJsonFname <> '' then
    setGenJSON(true);
  doChanged;
end;
{$ENDREGION}

{$REGION TMsgOpts --------------------------------------------------------------}
constructor TMsgOpts.create;
begin
  fDepHandling := TDepHandling.warning;
  fWarn := true;
end;

procedure TMsgOpts.getOpts(const aList: TStrings);
var
  opt : string;
const
  DepStr : array[TDepHandling] of string = ('-d', '', '-de');
begin
  opt := DepStr[fDepHandling];
  if opt <> '' then aList.Add(opt);
  if fVerb then aList.Add('-v');
  if fWarn then aList.Add('-w');
  if fWarnEx then aList.Add('-wi');
  if fVtls then aList.Add('-vtls');
  if fQuiet then aList.Add('-quiet');
  if fVgc then aList.Add('-vgc');
  if fCol then aList.Add('-vcolumns');
end;

procedure TMsgOpts.assign(aValue: TPersistent);
var
  src: TMsgOpts;
begin
  if (aValue is TMsgOpts) then
  begin
    src := TMsgOpts(aValue);
    fDepHandling := src.fDepHandling;
    fVerb   := src.fVerb;
    fWarn   := src.fWarn;
    fWarnEx := src.fWarnEx;
    fVtls   := src.fVtls;
    fQuiet  := src.fQuiet;
    fVgc    := src.fVgc;
    fCOl    := src.fCol;
  end
  else inherited;
end;

procedure TMsgOpts.setDepHandling(const aValue: TDepHandling);
begin
  if fDepHandling = aValue then exit;
  fDepHandling := aValue;
  doChanged;
end;

procedure TMsgOpts.setVerb(const aValue: boolean);
begin
  if fVerb = aValue then exit;
  fVerb := aValue;
  doChanged;
end;

procedure TMsgOpts.setWarn(const aValue: boolean);
begin
  if fWarn = aValue then exit;
  fWarn := aValue;
  doChanged;
end;

procedure TMsgOpts.setWarnEx(const aValue: boolean);
begin
  if fWarnEx = aValue then exit;
  fWarnEx := aValue;
  doChanged;
end;

procedure TMsgOpts.setVtls(const aValue: boolean);
begin
  if fVtls = aValue then exit;
  fVtls := aValue;
  doChanged;
end;

procedure TMsgOpts.setQuiet(const aValue: boolean);
begin
  if fQuiet = aValue then exit;
  fQuiet := aValue;
  doChanged;
end;

procedure TMsgOpts.setVgc(const aValue: boolean);
begin
  if fVgc = aValue then exit;
  fVgc := aValue;
  doChanged;
end;

procedure TMsgOpts.setCol(const aValue: boolean);
begin
  if fCol = aValue then exit;
  fCol := aValue;
  doChanged;
end;
{$ENDREGION}

{$REGION TOutputOpts -----------------------------------------------------------}
constructor TOutputOpts.create;
begin
  fVerIds := TStringList.Create;
  fBoundsCheck := safeOnly;
end;

destructor TOutputOpts.destroy;
begin
  fVerIds.Free;
  inherited;
end;

procedure TOutputOpts.depPatch;
begin
  // patch deprecated fields
  if fNoBounds then setBoundsCheck(offAlways)
  else setBoundsCheck(onAlways);
  fNoBounds := false;
end;

procedure TOutputOpts.getOpts(const aList: TStrings);
var
  opt: string;
const
  trgKindStr: array[TTargetSystem] of string = ('', '-m32','-m64');
  binKindStr: array[TBinaryKind] of string = ('', '-lib', '-shared', '-c');
  bchKindStr: array[TBoundCheckKind] of string = ('on', 'safeonly', 'off');
begin
  opt := binKindStr[fBinKind];
  if opt <> '' then aList.Add(opt);
  opt := trgKindStr[fTrgKind];
  if opt <> '' then aList.Add(opt);
  if fUt then aList.Add('-unittest');
  if fInline then aList.Add('-inline');
  if fOptimz then aList.Add('-O');
  if fGenStack then aList.Add('-gs');
  if fStackStomp then aList.Add('-gx');
  if fAllInst then aList.Add('-allinst');
  if fMain then aList.Add('-main');
  if fRelease then aList.Add('-release');
  for opt in fVerIds do begin
    if opt[1] = ';' then
      continue;
    if length(opt) > 1 then
      if opt[1..2] = '//' then
        continue;
    aList.Add('-version=' + opt );
  end;
  //
  if fRelease then
    begin
      if fBoundsCheck <> safeOnly then
        aList.Add('-boundscheck=' + bchKindStr[fBoundsCheck] );
    end
  else
    if fBoundsCheck <> onAlways then
      aList.Add('-boundscheck=' + bchKindStr[fBoundsCheck] );

end;

procedure TOutputOpts.assign(aValue: TPersistent);
var
  src: TOutputOpts;
begin
  if (aValue is TOutputOpts) then
  begin
    src := TOutputOpts(aValue);
    fBinKind := src.fBinKind;
    fTrgKind := src.fTrgKind;
    fUt := src.fUt;
    fVerIds.Assign(src.fVerIds);
    fInline := src.fInline;
    fNoBounds := src.fNoBounds;
    fBoundsCheck:= src.fBoundsCheck;
    fOptimz := src.fOptimz;
    fGenStack := src.fGenStack;
    fMain := src.fMain;
    fRelease := src.fRelease;
    fAllinst := src.fAllInst;
    fStackStomp := src.fStackStomp;
    //
    depPatch;
  end
  else inherited;
end;

procedure TOutputOpts.setUt(const aValue: boolean);
begin
  if fUt = aValue then exit;
  fUt := aValue;
  doChanged;
end;

procedure TOutputOpts.setAllInst(const aValue: boolean);
begin
  if fAllinst = aValue then exit;
  fAllinst := aValue;
  doChanged;
end;

procedure TOutputOpts.setVerIds(const aValue: TStringList);
begin
  fVerIds.Assign(aValue);
  doChanged;
end;

procedure TOutputOpts.setTrgKind(const aValue: TTargetSystem);
begin
  if fTrgKind = aValue then exit;
  fTrgKind := aValue;
  doChanged;
end;

procedure TOutputOpts.setBinKind(const aValue: TBinaryKind);
begin
  if fBinKind = aValue then exit;
  fBinKind := aValue;
  doChanged;
end;

procedure TOutputOpts.setInline(const aValue: boolean);
begin
  if fInline = aValue then exit;
  fInline := aValue;
  doChanged;
end;

procedure TOutputOpts.setBoundsCheck(const aValue: TBoundCheckKind);
begin
  if fBoundsCheck = aValue then exit;
  fBoundsCheck := aValue;
  doChanged;
end;

procedure TOutputOpts.setNoBounds(const aValue: boolean);
begin
  if fNoBounds = aValue then exit;
  fNoBounds := aValue;
  depPatch;
  doChanged;
end;

procedure TOutputOpts.setOptims(const aValue: boolean);
begin
  if fOptimz = aValue then exit;
  fOptimz := aValue;
  doChanged;
end;

procedure TOutputOpts.setGenStack(const aValue: boolean);
begin
  if fGenStack = aValue then exit;
  fGenStack := aValue;
  doChanged;
end;

procedure TOutputOpts.setMain(const aValue: boolean);
begin
  if fMain = aValue then exit;
  fMain := aValue;
  doChanged;
end;

procedure TOutputOpts.setRelease(const aValue: boolean);
begin
  if fRelease = aValue then exit;
  fRelease := aValue;
  doChanged;
end;

procedure TOutputOpts.setStackStomp(const aValue: boolean);
begin
  if fStackStomp = aValue then exit;
  fStackStomp := aValue;
  doChanged;
end;
{$ENDREGION}

{$REGION TDebugOpts ------------------------------------------------------------}
constructor TDebugOpts.create;
begin
  fDbgIdents := TStringList.Create;
end;

destructor TDebugOpts.destroy;
begin
  fDbgIdents.Free;
  inherited;
end;

procedure TDebugOpts.getOpts(const aList: TStrings);
var
  idt: string;
begin
  if fDbg then aList.Add('-debug');
  if fDbgLevel <> 0 then
    aList.Add('-debug=' + intToStr(fDbgLevel));
  for idt in fDbgIdents do
    aList.Add('-debug=' + idt);
  if fDbgD then aList.Add('-g');
  if fDbgC then aList.Add('-gc');
  if fMap then aList.Add('-map');
end;

procedure TDebugOpts.assign(aValue: TPersistent);
var
  src: TDebugOpts;
begin
  if (aValue is TDebugOpts) then
  begin
    src := TDebugOpts(aValue);
    fDbg := src.fDbg;
    fDbgIdents.Assign(src.fDbgIdents);
    fDbgLevel := src.fDbgLevel;
    fDbgD := src.fDbgD;
    fDbgC := src.fDbgC;
    fMap := src.fMap;
  end
  else inherited;
end;

procedure TDebugOpts.updateForceDbgBool;
begin
  fForceDbgBool := (fDbgLevel > 0) or (fDbgIdents.Count > 0);
  if fForceDbgBool then setDbg(true);
end;

procedure TDebugOpts.setDbg(const aValue: boolean);
begin
  if fForceDbgBool then
  begin
    fDbg := true;
    exit;
  end;
  if fDbg = aValue then exit;
  fDbg := aValue;
  doChanged;
end;

procedure TDebugOpts.setDbgD(const aValue: boolean);
begin
  if fDbgD = aValue then exit;
  fDbgD := aValue;
  doChanged;
end;

procedure TDebugOpts.setDbgC(const aValue: boolean);
begin
  if fDbgC = aValue then exit;
  fDbgC := aValue;
  doChanged;
end;

procedure TDebugOpts.setMap(const aValue: boolean);
begin
  if fMap = aValue then exit;
  fMap := aValue;
  doChanged;
end;

procedure TDebugOpts.setDbgLevel(const aValue: Integer);
begin
  if fDbgLevel = aValue then exit;
  fDbgLevel := aValue;
  if fDbgLevel < 0 then fDbgLevel := 0;
  updateForceDbgBool;
  doChanged;
end;

procedure TDebugOpts.setDbgIdents(const aValue: TStringList);
begin
  fDbgIdents.Assign(aValue);
  updateForceDbgBool;
  doChanged;
end;
{$ENDREGION}

{$REGION TPathsOpts ------------------------------------------------------------}
constructor TPathsOpts.create;
begin
  fExtraSrcs := TStringList.Create;
  fIncl := TStringList.Create;
  fImpt := TStringList.Create;
  fExcl := TStringList.Create;
  // setSrcs(), setIncl(), etc are not called when reloading from
  // a stream but rather the TSgringList.Assign()
  fExtraSrcs.OnChange := @strLstChange;
  fIncl.OnChange := @strLstChange;
  fImpt.OnChange := @strLstChange;
  fExcl.OnChange := @strLstChange;
end;

procedure TPathsOpts.strLstChange(sender: TObject);
begin
  TStringList(sender).BeginUpdate; // onChange not called anymore
  patchPlateformPaths(TStringList(sender));
  // EndUpdate is not called to avoid an infinite loop
end;

procedure TPathsOpts.getOpts(const aList: TStrings);
var
  str: string;
begin
  for str in fExtraSrcs do
  begin
    str := symbolExpander.get(str);
    if not listAsteriskPath(str, aList, dExtList) then
      aList.Add(str);
  end;
  for str in fIncl do
    aList.Add('-I'+ symbolExpander.get(str));
  for str in fImpt do
    aList.Add('-J'+ symbolExpander.get(str));
  if fFname <> '' then
    aList.Add('-of' + symbolExpander.get(fFname));
  if fObjDir <> '' then
    aList.Add('-od' + symbolExpander.get(fObjDir));
end;

procedure TPathsOpts.assign(aValue: TPersistent);
var
  src: TPathsOpts;
begin
  if (aValue is TPathsOpts) then
  begin
    src := TPathsOpts(aValue);
    fExtraSrcs.Assign(src.fExtraSrcs);
    fIncl.Assign(src.fIncl);
    fImpt.Assign(src.fImpt);
    fFName := patchPlateformPath(src.fFname);
    fObjDir := patchPlateformPath(src.fObjDir);
  end
  else inherited;
end;

destructor TPathsOpts.destroy;
begin
  fExtraSrcs.free;
  fIncl.free;
  fImpt.free;
  fExcl.free;
  inherited;
end;

procedure TPathsOpts.setFname(const aValue: TCEFilename);
begin
  if fFname = aValue then exit;
  fFname := patchPlateformPath(aValue);
  fFname := patchPlateformExt(fFname);
  doChanged;
end;

procedure TPathsOpts.setObjDir(const aValue: TCEPathname);
begin
  if fObjDir = aValue then exit;
  fObjDir := patchPlateformPath(aValue);
  doChanged;
end;

procedure TPathsOpts.setSrcs(aValue: TStringList);
begin
  fExtraSrcs.Assign(aValue);
  patchPlateformPaths(fExtraSrcs);
  doChanged;
end;

procedure TPathsOpts.setIncl(aValue: TStringList);
begin
  fIncl.Assign(aValue);
  patchPlateformPaths(fIncl);
  doChanged;
end;

procedure TPathsOpts.setImpt(aValue: TStringList);
begin
  fImpt.Assign(aValue);
  patchPlateformPaths(fImpt);
  doChanged;
end;

procedure TPathsOpts.setExcl(aValue: TStringList);
begin
  fExcl.Assign(aValue);
  patchPlateformPaths(fExcl);
  doChanged;
end;
{$ENDREGION}

{$REGION TOtherOpts ------------------------------------------------------------}
constructor TOtherOpts.create;
begin
  fCustom := TStringList.Create;
end;

procedure TOtherOpts.assign(aValue: TPersistent);
var
  src: TOtherOpts;
begin
  if (aValue is TOtherOpts) then
  begin
    src := TOtherOpts(aValue);
    fCustom.Assign(src.fCustom);
  end
  else inherited;
end;

destructor TOtherOpts.destroy;
begin
  fCustom.Destroy;
  inherited;
end;

procedure TOtherOpts.getOpts(const aList: TStrings);
var
  str1, str2: string;
begin
  for str1 in fCustom do if str1 <> '' then
  begin
    if str1[1] = ';' then
        continue;
    if length(str1) > 1 then
      if str1[1..2] = '//' then
        continue;
    if str1[1] <> '-' then
      str2 := '-' + str1
    else
      str2 := str1;
    aList.AddText(symbolExpander.get(str2));
  end;
end;

procedure TOtherOpts.setCustom(const aValue: TStringList);
begin
  fCustom.Assign(aValue);
  doChanged;
end;
{$ENDREGION}

{$REGION TCustomProcOptions ----------------------------------------------------}
constructor TCustomProcOptions.create;
begin
  fParameters := TStringList.Create;
end;

destructor TCustomProcOptions.destroy;
begin
  fParameters.Free;
  inherited;
end;

procedure TCustomProcOptions.assign(source: TPersistent);
var
  src: TCustomProcOptions;
begin
  if source is TCustomProcOptions then
  begin
    src := TCustomProcOptions(source);
    Parameters.Assign(src.Parameters);
    fOptions := src.fOptions;
    fExecutable := src.fExecutable;
    fShowWin := src.fShowWin;
  end
  else inherited;
end;

procedure TCustomProcOptions.getOpts(const aList: TStrings);
begin
end;

procedure TCustomProcOptions.setProcess(var aProcess: TProcess);
begin
  aProcess.Parameters.Clear;
  aProcess.Parameters.AddText(symbolExpander.get(Parameters.Text));
  aProcess.Executable := fExecutable;
  aProcess.ShowWindow := fShowWin;
  aProcess.Options    := fOptions;
  aProcess.CurrentDirectory := fWorkDir;
  aProcess.StartupOptions := aProcess.StartupOptions + [suoUseShowWindow];
end;

procedure TCustomProcOptions.setProcess(var aProcess: TAsyncProcess);
begin
  aProcess.Parameters.Clear;
  aProcess.Parameters.AddText(symbolExpander.get(Parameters.Text));
  aProcess.Executable := fExecutable;
  aProcess.ShowWindow := fShowWin;
  aProcess.Options    := fOptions;
  aProcess.CurrentDirectory := fWorkDir;
  aProcess.StartupOptions := aProcess.StartupOptions + [suoUseShowWindow];
end;

procedure TCustomProcOptions.setProcess(var aProcess: TCheckedAsyncProcess);
begin
  aProcess.Parameters.Clear;
  aProcess.Parameters.AddText(symbolExpander.get(Parameters.Text));
  aProcess.Executable := fExecutable;
  aProcess.ShowWindow := fShowWin;
  aProcess.Options    := fOptions;
  aProcess.CurrentDirectory := fWorkDir;
  aProcess.StartupOptions := aProcess.StartupOptions + [suoUseShowWindow];
end;

procedure TCustomProcOptions.setExecutable(const aValue: TCEFilename);
begin
  if fExecutable = aValue then exit;
  fExecutable := aValue;
  doChanged;
end;

procedure TCustomProcOptions.setWorkDir(const aValue: TCEPathname);
begin
  if fWorkDir = aValue then exit;
  fWorkDir := aValue;
  doChanged;
end;

procedure TCustomProcOptions.setOptions(const aValue: TProcessOptions);
begin
  if fOptions = aValue then exit;
  fOptions := aValue;
  doChanged;
end;

procedure TCustomProcOptions.setParameters(aValue: TStringList);
begin
  fParameters.Assign(aValue);
  doChanged;
end;

procedure TCustomProcOptions.setShowWin(const aValue: TShowWindowOptions);
begin
  if fShowWin = aValue then exit;
  fShowWin := aValue;
  doChanged;
end;
{$ENDREGION}

{$REGION TCompilerConfiguration ------------------------------------------------}
constructor TCompilerConfiguration.create(aCollection: TCollection);
begin
  inherited create(aCollection);

  fDocOpts    := TDocOpts.create;
  fDebugOpts  := TDebugOpts.create;
  fMsgOpts    := TMsgOpts.create;
  fOutputOpts := TOutputOpts.create;
  fPathsOpts  := TPathsOpts.create;
  fOthers     := TOtherOpts.create;
  fPreProcOpt := TCompileProcOptions.create;
  fPostProcOpt:= TCompileProcOptions.create;
  fRunProjOpt := TProjectRunOptions.create;

  fDocOpts.onChange     := @subOptsChanged;
  fDebugOpts.onChange   := @subOptsChanged;
  fMsgOpts.onChange     := @subOptsChanged;
  fOutputOpts.onChange  := @subOptsChanged;
  fPathsOpts.onChange   := @subOptsChanged;
  fOthers.onChange      := @subOptsChanged;
  fPreProcOpt.onChange  := @subOptsChanged;
  fPostProcOpt.onChange := @subOptsChanged;
  fRunProjOpt.onChange  := @subOptsChanged;

  fName := nameFromID;
end;

destructor TCompilerConfiguration.destroy;
begin
  fOnChanged := nil;
  fDocOpts.free;
  fDebugOpts.free;
  fMsgOpts.free;
  fOutputOpts.free;
  fPathsOpts.free;
  fOthers.free;
  fPreProcOpt.free;
  fPostProcOpt.free;
  fRunProjOpt.Free;
  inherited;
end;

procedure TCompilerConfiguration.assign(aValue: TPersistent);
var
  src: TCompilerConfiguration;
begin
  if (aValue is TCompilerConfiguration) then
  begin
    src := TCompilerConfiguration(aValue);
    fDocOpts.assign(src.fDocOpts);
    fDebugOpts.assign(src.fDebugOpts);
    fMsgOpts.assign(src.fMsgOpts);
    fOutputOpts.assign(src.fOutputOpts);
    fPathsOpts.assign(src.fPathsOpts);
    fOthers.assign(src.fOthers);
    fPreProcOpt.assign(src.fPreProcOpt);
    fPostProcOpt.assign(src.fPostProcOpt);
    fRunProjOpt.assign(src.fRunProjOpt);
  end
  else inherited;
end;

function TCompilerConfiguration.nameFromID: string;
begin
  result := format('<configuration %d>',[ID]);
end;

procedure TCompilerConfiguration.getOpts(const aList: TStrings);
begin
  fDocOpts.getOpts(aList);
  fDebugOpts.getOpts(aList);
  fMsgOpts.getOpts(aList);
  fOutputOpts.getOpts(aList);
  fPathsOpts.getOpts(aList);
  fOthers.getOpts(aList);
end;

procedure TCompilerConfiguration.setName(const aValue: string);
begin
  if fName = aValue then
    exit;
  fName := aValue;
  if fName = '' then
    fName := nameFromID;
  Changed(true);
  doChanged;
end;

procedure TCompilerConfiguration.subOptsChanged(sender: TObject);
begin
  Changed(true);
  doChanged;
end;

procedure TCompilerConfiguration.doChanged;
begin
  if assigned(fOnChanged) then fOnChanged(self);
end;

procedure TCompilerConfiguration.setDocOpts(const aValue: TDocOpts);
begin
  fDocOpts.assign(aValue);
end;

procedure TCompilerConfiguration.setDebugOpts(const aValue: TDebugOpts);
begin
  fDebugOpts.assign(aValue);
end;

procedure TCompilerConfiguration.setMsgOpts(const aValue: TMsgOpts);
begin
  fMsgOpts.assign(aValue);
end;

procedure TCompilerConfiguration.setOutputOpts(const aValue: TOutputOpts);
begin
  fOutputOpts.assign(aValue);
end;

procedure TCompilerConfiguration.setPathsOpts(const aValue: TPathsOpts);
begin
  fPathsOpts.assign(aValue);
end;

procedure TCompilerConfiguration.setOthers(const aValue: TOtherOpts);
begin
  fOthers.Assign(aValue);
end;

procedure TCompilerConfiguration.setPreProcOpt(const aValue: TCompileProcOptions);
begin
  fPreProcOpt.assign(aValue);
end;

procedure TCompilerConfiguration.setPostProcOpt(const aValue: TCompileProcOptions);
begin
  fPostProcOpt.assign(aValue);
end;

procedure TCompilerConfiguration.setRunProjOpt(const aValue: TProjectRunOptions);
begin
  fRunProjOpt.assign(aValue);
end;
{$ENDREGION}

initialization
  RegisterClasses([TOtherOpts, TPathsOpts, TDebugOpts, TOutputOpts, TMsgOpts,
    TDocOpts, TCompileProcOptions, TProjectRunOptions, TCompilerConfiguration]);
end.
