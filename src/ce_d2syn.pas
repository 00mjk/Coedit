unit ce_d2syn;

{$I ce_defines.inc}

interface

uses
  Classes, SysUtils, Graphics,
  SynEditHighlighter, SynEditHighlighterFoldBase, SynEditTypes,
  ce_dlangutils;

const

  D2Kw: array[0..106] of string =
  ( 'abstract', 'alias', 'align', 'asm', 'assert', 'auto',
    'body', 'bool', 'break', 'byte',
    'case', 'cast', 'catch', 'cdouble', 'cent', 'cfloat', 'char', 'class',
    'const', 'continue', 'creal',
    'dchar', 'debug', 'default', 'delegate', 'delete', 'deprecated', 'do', 'double', 'dstring',
    'else', 'enum', 'export', 'extern',
    'false', 'final', 'finally', 'float', 'for', 'foreach',
    'foreach_reverse', 'function',
    'goto',
    'idouble', 'if', 'ifloat', 'immutable', 'import', 'in', 'inout', 'int',
    'interface', 'invariant', 'ireal', 'is',
    'lazy', 'long',
    'macro', 'mixin', 'module',
    'new', 'nothrow', 'null',
    'out', 'override',
    'package', 'pragma', 'private', 'protected', 'ptrdiff_t', 'public', 'pure',
    'real', 'ref', 'return',
    'size_t', 'scope', 'shared', 'short', 'static', 'string', 'struct',
    'super', 'switch', 'synchronized',
    'template', 'this', 'throw', 'true', 'try', 'typedef', 'typeid', 'typeof',
    'ubyte', 'ucent', 'uint', 'ulong', 'union', 'unittest', 'ushort',
    'version', 'void', 'volatile',
    'wchar', 'while', 'with', 'wstring'
  );

  D2SpecKw: array[0..10] of string =
  (
    '__FILE__', '__MODULE__', '__LINE__', '__FUNCTION__', '__PRETTY_FUNCTION__',
    '__DATE__', '__EOF__', '__TIME__', '__TIMESTAMP__', '__VENDOR__', '__VERSION__'
  );

type

  TD2DictionaryEntry = record
    filled: Boolean;
    values: array of string;
  end;

  TD2Dictionary = object
  private
    fLongest, fShortest: NativeInt;
    fEntries: array[Byte] of TD2DictionaryEntry;
    function toHash(const aValue: string): Byte;  {$IFNDEF DEBUG}inline;{$ENDIF}
    procedure addEntry(const aValue: string);
  public
    constructor create(from: array of string);
    function find(const aValue: string): boolean; {$IFNDEF DEBUG}inline;{$ENDIF}
  end;

  TTokenKind = (tkCommt, tkIdent, tkKeywd, tkStrng, tkBlank, tkSymbl, tkNumbr, tkCurrI, tkDDocs, tkSpecK);

  TRangeKind = (rkString1, rkString2, rkTokString, rkBlockCom1, rkBlockCom2, rkBlockDoc1, rkBlockDoc2, rkAsm);

  // a terminal range kind, cannot be combined with another range kind.
  TPrimaryRange = (prNone, prString1, prString2, prBlockCom1, prBlockCom2, prBlockDoc1, prBlockDoc2);

  // can be combined to a primary range
  TSecondaryRange = (srNone, srTokenString, srActiveVersion, srInactiveVersion, srAssembly);

  // used by the secondary ranges to transform the standard token attributes.
  TAttributeTransform = (taFontStyle, taFontColor, taBackColor);

  TRangeKinds = set of TRangeKind;

  // defines the ranges which can be folded
  TFoldKinds = set of (fkBrackets, fkComments1, fkComments2, fkStrings, fkRegion, fkDDoc);

  // internal class used to keep trace of the useful informations of the previous line
  TSynD2SynRange = class(TSynCustomHighlighterRange)
  private
    namedRegionCount: Integer;
    nestedCommentsCount: Integer;
    tokenStringBracketsCount: Integer;
    rangeKinds: TRangeKinds;
    primaryRange: TPrimaryRange;
    secondaryRange: TSecondaryRange;
    // double quoted multi-line string prefixed with 'r':
    // => don't skip '"' following '\'
    rString: boolean;
  public
    procedure Assign(Src: TSynCustomHighlighterRange); override;
    function Compare(Range: TSynCustomHighlighterRange): integer; override;
    procedure Clear; override;
    //
    procedure copyFrom(aSource: TSynD2SynRange);
  end;

	TSynD2Syn = class (TSynCustomFoldHighlighter)
	private
    fWhiteAttrib: TSynHighlighterAttributes;
		fNumbrAttrib: TSynHighlighterAttributes;
		fSymblAttrib: TSynHighlighterAttributes;
		fIdentAttrib: TSynHighlighterAttributes;
		fCommtAttrib: TSynHighlighterAttributes;
		fStrngAttrib: TSynHighlighterAttributes;
    fKeywdAttrib: TSynHighlighterAttributes;
    fCurrIAttrib: TSynHighlighterAttributes;
    fDDocsAttrib: TSynHighlighterAttributes;
    fAsblrAttrib: TSynHighlighterAttributes;
    fSpeckAttrib: TSynHighlighterAttributes;
    fKeyWords: TD2Dictionary;
    fSpecKw: TD2Dictionary;
    fCurrIdent: string;
    fLineBuf: string;
    fTokStart, fTokStop: Integer;
    fTokKind: TTokenKind;
    fCurrRange: TSynD2SynRange;
    fFoldKinds: TFoldKinds;
    fAttribLut: array[TTokenKind] of TSynHighlighterAttributes;
    procedure setFoldKinds(aValue: TFoldKinds);
    procedure setWhiteAttrib(aValue: TSynHighlighterAttributes);
    procedure setNumbrAttrib(aValue: TSynHighlighterAttributes);
    procedure setSymblAttrib(aValue: TSynHighlighterAttributes);
    procedure setIdentAttrib(aValue: TSynHighlighterAttributes);
    procedure setCommtAttrib(aValue: TSynHighlighterAttributes);
    procedure setStrngAttrib(aValue: TSynHighlighterAttributes);
    procedure setKeywdAttrib(aValue: TSynHighlighterAttributes);
    procedure setCurrIAttrib(aValue: TSynHighlighterAttributes);
    procedure setDDocsAttrib(aValue: TSynHighlighterAttributes);
    procedure setAsblrAttrib(aValue: TSynHighlighterAttributes);
    procedure setSpeckAttrib(aValue: TSynHighlighterAttributes);
    procedure doAttribChange(sender: TObject);
    procedure setCurrIdent(const aValue: string);
    procedure doChanged;
  protected
    function GetRangeClass: TSynCustomHighlighterRangeClass; override;
	published
    property FoldKinds: TFoldKinds read fFoldKinds write setFoldKinds;
    property WhiteAttrib: TSynHighlighterAttributes read fWhiteAttrib write setWhiteAttrib;
    property NumbrAttrib: TSynHighlighterAttributes read fNumbrAttrib write setNumbrAttrib;
    property SymblAttrib: TSynHighlighterAttributes read fSymblAttrib write setSymblAttrib;
    property IdentAttrib: TSynHighlighterAttributes read fIdentAttrib write setIdentAttrib;
    property CommtAttrib: TSynHighlighterAttributes read fCommtAttrib write setCommtAttrib;
    property StrngAttrib: TSynHighlighterAttributes read fStrngAttrib write setStrngAttrib;
    property KeywdAttrib: TSynHighlighterAttributes read fKeywdAttrib write setKeywdAttrib;
    property CurrIAttrib: TSynHighlighterAttributes read fCurrIAttrib write setCurrIAttrib;
    property DDocsAttrib: TSynHighlighterAttributes read fDDocsAttrib write setDDocsAttrib;
    property AsblrAttrib: TSynHighlighterAttributes read fAsblrAttrib write setAsblrAttrib;
    property SpeckAttrib: TSynHighlighterAttributes read fSpeckAttrib write setSpeckAttrib;
	public
		constructor create(aOwner: TComponent); override;
    destructor destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure GetTokenEx(out TokenStart: PChar; out TokenLength: integer); override;
    function GetDefaultAttribute(Index: integer): TSynHighlighterAttributes; override;
    procedure setLine(const NewValue: String; LineNumber: Integer); override;
    procedure next; override;
    function  GetTokenAttribute: TSynHighlighterAttributes; override;
    function GetToken: string; override;
    function GetTokenKind: integer; override;
    function GetTokenPos: Integer; override;
    function GetEol: Boolean; override;
    procedure SetRange(Value: Pointer); override;
    procedure ResetRange; override;
    function GetRange: Pointer; override;
    property CurrentIdentifier: string read fCurrIdent write setCurrIdent;
	end;

implementation

constructor TD2Dictionary.create(from: array of string);
var
  value: string;
begin
  for value in from do
    addEntry(value);
end;

{$IFDEF DEBUG}{$R-}{$ENDIF}
function TD2Dictionary.toHash(const aValue: string): Byte;
var
  i: Integer;
begin
  result := 0;
	for i := 1 to length(aValue) do
	  result += (Byte(aValue[i]) shl (4 and (1-i))) xor 25;
end;
{$IFDEF DEBUG}{$R+}{$ENDIF}

procedure TD2Dictionary.addEntry(const aValue: string);
var
  hash: Byte;
begin
  if find(aValue) then exit;
  hash := toHash(aValue);
  fEntries[hash].filled := true;
  setLength(fEntries[hash].values, length(fEntries[hash].values) + 1);
  fEntries[hash].values[high(fEntries[hash].values)] := aValue;
  if fLongest <= length(aValue) then
    fLongest := length(aValue);
  if fShortest >= length(aValue) then
    fShortest := length(aValue);
end;

function TD2Dictionary.find(const aValue: string): boolean;
var
  hash: Byte;
  i: NativeInt;
begin
  result := false;
  if length(aValue) > fLongest then exit;
  if length(aValue) < fShortest then exit;
  hash := toHash(aValue);
  if (not fEntries[hash].filled) then exit(false);
  for i:= 0 to high(fEntries[hash].values) do
    if fEntries[hash].values[i] = aValue then exit(true);
end;

procedure TSynD2SynRange.Assign(Src: TSynCustomHighlighterRange);
var
  src_t: TSynD2SynRange;
begin
  inherited;
  if Src is TSynD2SynRange then
  begin
    src_t := TSynD2SynRange(Src);
    rangeKinds := src_t.rangeKinds;
    nestedCommentsCount := src_t.nestedCommentsCount;
    tokenStringBracketsCount := src_t.tokenStringBracketsCount;
    namedRegionCount := src_t.namedRegionCount;
  end;
end;

function TSynD2SynRange.Compare(Range: TSynCustomHighlighterRange): integer;
var
  src_t: TSynD2SynRange;
const
  cmpRes: array[boolean] of integer = (-1, 1);
begin
  result := inherited Compare(Range);
  assert(Range <> nil);
  if result <> 0 then exit;
  //
  if Range is TSynD2SynRange then
  begin
    src_t := TSynD2SynRange(Range);
    if src_t.rangeKinds <> rangeKinds then exit(1);
    if src_t.rString <> rString then exit(1);
    if src_t.nestedCommentsCount <> nestedCommentsCount then
      exit(cmpRes[src_t.nestedCommentsCount > nestedCommentsCount]);
    if src_t.tokenStringBracketsCount <> tokenStringBracketsCount then
      exit(cmpRes[src_t.tokenStringBracketsCount > tokenStringBracketsCount]);
    if src_t.namedRegionCount <> namedRegionCount then
      exit(cmpRes[src_t.namedRegionCount > namedRegionCount]);
  end;
end;

procedure TSynD2SynRange.Clear;
begin
  inherited;
  nestedCommentsCount := 0;
  namedRegionCount := 0;
  tokenStringBracketsCount := 0;
  rangeKinds := [];
  rString := false;
  //
  primaryRange := prNone;
  secondaryRange := srNone;
end;

procedure TSynD2SynRange.copyFrom(aSource: TSynD2SynRange);
begin
  nestedCommentsCount := aSource.nestedCommentsCount;
  namedRegionCount := aSource.namedRegionCount;
  tokenStringBracketsCount := aSource.tokenStringBracketsCount;
  rangeKinds := aSource.rangeKinds;
  rString := aSource.rString;
  //
  primaryRange := aSource.primaryRange;
  secondaryRange := aSource.secondaryRange;
end;

constructor TSynD2Syn.create(aOwner: TComponent);
begin
	inherited create(aOwner);
  SetSubComponent(true);

  DefaultFilter:= 'D source|*.d|D interface|*.di';

  fKeyWords.create(D2Kw);
  fSpecKw.create(D2SpecKw);

  fFoldKinds := [fkBrackets];

  WordBreakChars := WordBreakChars - ['@'];

  fWhiteAttrib := TSynHighlighterAttributes.Create('White','White');
	fNumbrAttrib := TSynHighlighterAttributes.Create('Number','Number');
	fSymblAttrib := TSynHighlighterAttributes.Create('Symbol','Symbol');
	fIdentAttrib := TSynHighlighterAttributes.Create('Identifier','Identifier');
	fCommtAttrib := TSynHighlighterAttributes.Create('Comment','Comment');
	fStrngAttrib := TSynHighlighterAttributes.Create('String','String');
  fKeywdAttrib := TSynHighlighterAttributes.Create('Keyword','Keyword');
  fCurrIAttrib := TSynHighlighterAttributes.Create('CurrentIdentifier','CurrentIdentifier');
  fDDocsAttrib := TSynHighlighterAttributes.Create('DDoc','DDoc');
  fAsblrAttrib := TSynHighlighterAttributes.Create('Asm','Asm');
  fSpeckAttrib := TSynHighlighterAttributes.Create('SpecialKeywords','SpecialKeywords');

  fNumbrAttrib.Foreground := $000079F2;
  fSymblAttrib.Foreground := clMaroon;
  fIdentAttrib.Foreground := clBlack;
  fCommtAttrib.Foreground := clGreen;
  fStrngAttrib.Foreground := clBlue;
  fKeywdAttrib.Foreground := clNavy;
  fAsblrAttrib.Foreground := clGray;
  fSpeckAttrib.Foreground := clNavy;

  fCurrIAttrib.Foreground := clBlack;
  fCurrIAttrib.FrameEdges := sfeAround;
  fCurrIAttrib.FrameColor := $D4D4D4;
  fCurrIAttrib.Background := $F0F0F0;

  fDDocsAttrib.Foreground := clTeal;

  fCommtAttrib.Style := [fsItalic];
  fKeywdAttrib.Style := [fsBold];
  fAsblrAttrib.Style := [fsBold];
  fSpeckAttrib.Style := [fsBold];

  AddAttribute(fWhiteAttrib);
  AddAttribute(fNumbrAttrib);
  AddAttribute(fSymblAttrib);
  AddAttribute(fIdentAttrib);
  AddAttribute(fCommtAttrib);
  AddAttribute(fStrngAttrib);
  AddAttribute(fKeywdAttrib);
  AddAttribute(fCurrIAttrib);
  AddAttribute(fDDocsAttrib);
  AddAttribute(fAsblrAttrib);
  AddAttribute(fSpeckAttrib);

  fAttribLut[TTokenKind.tkident] := fIdentAttrib;
  fAttribLut[TTokenKind.tkBlank] := fWhiteAttrib;
  fAttribLut[TTokenKind.tkCommt] := fCommtAttrib;
  fAttribLut[TTokenKind.tkKeywd] := fKeywdAttrib;
  fAttribLut[TTokenKind.tkNumbr] := fNumbrAttrib;
  fAttribLut[TTokenKind.tkStrng] := fStrngAttrib;
  fAttribLut[TTokenKind.tksymbl] := fSymblAttrib;
  fAttribLut[TTokenKind.tkCurrI] := fCurrIAttrib;
  fAttribLut[TTokenKind.tkDDocs] := fDDocsAttrib;
  fAttribLut[TTokenKind.tkSpecK] := fSpeckAttrib;

  SetAttributesOnChange(@doAttribChange);
  fTokStop := 1;
  next;
end;

destructor TSynD2Syn.destroy;
begin
  fCurrRange.Free;
  inherited;
end;

procedure TSynD2Syn.Assign(Source: TPersistent);
var
  srcsyn: TSynD2Syn;
begin
  inherited;
  if Source is TSynD2Syn then
  begin
    srcsyn := TSynD2Syn(Source);
    FoldKinds := srcsyn.FoldKinds;
  end;
end;

function TSynD2Syn.GetRangeClass: TSynCustomHighlighterRangeClass;
begin
  result := TSynD2SynRange;
end;

procedure TSynD2Syn.doChanged;
begin
  BeginUpdate;
    fUpdateChange := true;
  EndUpdate;
end;

{$HINTS OFF}
procedure TSynD2Syn.doAttribChange(sender: TObject);
begin
  doChanged;
end;
{$HINTS ON}

procedure TSynD2Syn.setFoldKinds(aValue: TFoldKinds);
begin
  fFoldKinds := aValue;
  DoFoldConfigChanged(Self);
  doChanged;
end;

procedure TSynD2Syn.setWhiteAttrib(aValue: TSynHighlighterAttributes);
begin
  fWhiteAttrib.Assign(aValue);
end;

procedure TSynD2Syn.setNumbrAttrib(aValue: TSynHighlighterAttributes);
begin
  fNumbrAttrib.Assign(aValue);
end;

procedure TSynD2Syn.setSymblAttrib(aValue: TSynHighlighterAttributes);
begin
  fSymblAttrib.Assign(aValue);
end;

procedure TSynD2Syn.setIdentAttrib(aValue: TSynHighlighterAttributes);
begin
  fIdentAttrib.Assign(aValue);
end;

procedure TSynD2Syn.setCommtAttrib(aValue: TSynHighlighterAttributes);
begin
  fCommtAttrib.Assign(aValue);
end;

procedure TSynD2Syn.setStrngAttrib(aValue: TSynHighlighterAttributes);
begin
  fStrngAttrib.Assign(aValue);
end;

procedure TSynD2Syn.setKeywdAttrib(aValue: TSynHighlighterAttributes);
begin
  fKeywdAttrib.Assign(aValue);
end;

procedure TSynD2Syn.setCurrIAttrib(aValue: TSynHighlighterAttributes);
begin
  fCurrIAttrib.Assign(aValue);
end;

procedure TSynD2Syn.setDDocsAttrib(aValue: TSynHighlighterAttributes);
begin
  fDDocsAttrib.Assign(aValue);
end;

procedure TSynD2Syn.setAsblrAttrib(aValue: TSynHighlighterAttributes);
begin
  fAsblrAttrib.Assign(aValue);
end;

procedure TSynD2Syn.setSpeckAttrib(aValue: TSynHighlighterAttributes);
begin
  fSpeckAttrib.Assign(aValue);
end;

procedure TSynD2Syn.setCurrIdent(const aValue: string);
begin
  if fCurrIdent = aValue then Exit;
  fCurrIdent := aValue;
  doChanged;
end;

procedure TSynD2Syn.setLine(const NewValue: String; LineNumber: Integer);
begin
  inherited;
  // note: the end of line is marked with a #10
  // usually a TSynCustomFoldHighlighter rather tests 'length(line)' in 'Next()'
  // but since the scanner works line by line, #10 is guaranteed not to
  // appear at all excepted when added implictly, like here.
  fLineBuf := NewValue + #10;
  fTokStop := 1;
  next;
end;

//TODO-cD2Syn: nested comments with multiple nesting on the same line.
procedure TSynD2Syn.next;
var
  reader: PChar;

label
  _postString1;

procedure readerReset;
begin
  fTokStop := fTokStart;
  reader := @fLineBuf[fTokStop];
end;

function readerNext: PChar;
begin
  Inc(reader);
  Inc(fTokStop);
  exit(reader);
end;

function readerPrev: PChar;
begin
  Dec(reader);
  Dec(fTokStop);
  exit(reader);
end;

begin

  fTokStart := fTokStop;
  fTokStop  := fTokStart;

  // EOL
  if fTokStop > length(fLineBuf) then exit;
  readerReset;

  // script line
  if LineIndex = 0 then if fTokStart = 1 then
    if readDelim(reader, fTokStop, '#!') then
    begin
      fTokKind := tkCommt;
      readLine(reader, fTokStop);
      exit;
    end else readerReset;

  // spaces
  if (isWhite(reader^)) then
  begin
    fTokKind := tkBlank;
    while(true) do
    begin
      if isWhite(reader^) then
        readerNext;
      exit;
    end;
  end;

  // line comment / region beg-end
  if (fCurrRange.rangeKinds = []) or (fCurrRange.rangeKinds = [rkTokString]) or
    (fCurrRange.rangeKinds = [rkAsm])
      then if readDelim(reader, fTokStop, '//') then
  begin
    fTokKind := tkCommt;
    if readDelim(reader, fTokStop, '/') then
      fTokKind := tkDDocs;
    readLine(reader, fTokStop);
    if (fkRegion in fFoldKinds) and (fTokStop - fTokStart > 4) then
    begin
      while isWhite(reader^) do
      begin
        Dec(reader);
        Dec(fTokStop);
      end;
      Dec(reader, 3);
      Dec(fTokStop, 3);
      if reader[0..3] = '---+' then
      begin
        fCurrRange.namedRegionCount += 1;
        StartCodeFoldBlock(nil);
      end
      else if (reader[0..3] = '----') and (fCurrRange.namedRegionCount > 0) then
      begin
        EndCodeFoldBlock();
        fCurrRange.namedRegionCount -= 1;
      end;
      readLine(reader, fTokStop);
    end;
    exit;
  end else readerReset;

  // block comments 1
  if (fCurrRange.rangeKinds = []) or (fCurrRange.rangeKinds = [rkTokString]) or
    (fCurrRange.rangeKinds = [rkAsm]) then if readDelim(reader, fTokStop, '/*') then
  begin
    fTokKind := tkCommt;
    if readDelim(reader, fTokStop, '*') then
      if readDelim(reader, fTokStop, '/') then exit
        else fTokKind := tkDDocs;
    if readUntil(reader, fTokStop, '*/') then
      exit;
    if fTokKind = tkDDocs then
      fCurrRange.rangeKinds += [rkBlockDoc1]
    else
      fCurrRange.rangeKinds += [rkBlockCom1];
    readLine(reader, fTokStop);
    if (fTokKind = tkCommt) then
      StartCodeFoldBlock(nil, fkComments1 in fFoldKinds)
    else if (fTokKind = tkDDocs) then
      StartCodeFoldBlock(nil, fkDDoc in fFoldKinds);
    exit;
  end else readerReset;
  if (rkBlockCom1 in fCurrRange.rangeKinds) or (rkBlockDoc1 in fCurrRange.rangeKinds) then
  begin
    if (rkBlockDoc1 in fCurrRange.rangeKinds) then fTokKind := tkDDocs
      else fTokKind := tkCommt;
    if readUntil(reader, fTokStop, '*/') then
    begin
      if (fTokKind = tkCommt) then
        EndCodeFoldBlock(fkComments1 in fFoldKinds)
      else if (fTokKind = tkDDocs) then
        EndCodeFoldBlock(fkDDoc in fFoldKinds);
      fCurrRange.rangeKinds -= [rkBlockDoc1, rkBlockCom1];
      exit;
    end;
    readLine(reader, fTokStop);
    exit;
  end;

  // block comments 2
  if (fCurrRange.rangeKinds = []) or (fCurrRange.rangeKinds = [rkTokString]) or
    (fCurrRange.rangeKinds = [rkAsm]) then if readDelim(reader, fTokStop, '/+') then
  begin
    fTokKind := tkCommt;
    if readDelim(reader, fTokStop, '+') then
      if readDelim(reader, fTokStop, '/') then exit
        else fTokKind := tkDDocs;
    if readUntil(reader, fTokStop, '+/') then exit;
    inc(fCurrRange.nestedCommentsCount);
    if fTokKind = tkDDocs then
      fCurrRange.rangeKinds += [rkBlockDoc2]
    else
      fCurrRange.rangeKinds += [rkBlockCom2];
    readLine(reader, fTokStop);
    if (fTokKind = tkCommt) then
      StartCodeFoldBlock(nil, fkComments2 in fFoldKinds)
    else if (fTokKind = tkDDocs) then
      StartCodeFoldBlock(nil, fkDDoc in fFoldKinds);
    exit;
  end else readerReset;
  if (rkBlockCom2 in fCurrRange.rangeKinds) or (rkBlockDoc2 in fCurrRange.rangeKinds) then
  begin
    if (rkBlockDoc2 in fCurrRange.rangeKinds) then fTokKind := tkDDocs
      else fTokKind := tkCommt;
    if readUntil(reader, fTokStop, '/+') then
      inc(fCurrRange.nestedCommentsCount)
    else readerReset;
    if readUntil(reader, fTokStop, '+/') then
    begin
      dec(fCurrRange.nestedCommentsCount);
      if fCurrRange.nestedCommentsCount <> 0 then
        exit;
      if (fTokKind = tkCommt) then
        EndCodeFoldBlock(fkComments2 in fFoldKinds)
      else if (fTokKind = tkDDocs) then
        EndCodeFoldBlock(fkDDoc in fFoldKinds);
      fCurrRange.rangeKinds -= [rkBlockDoc2, rkBlockCom2];
      exit;
    end;
    readLine(reader, fTokStop);
    exit;
  end;

  // string 1
  if (fCurrRange.rangeKinds = []) or (fCurrRange.rangeKinds = [rkTokString])
    then if readDelim(reader, fTokStop, stringPrefixes) then
  begin
    if readerPrev^ in ['r','x','q'] then
    begin
      fCurrRange.rString := reader^ = 'r';
      if not (readerNext^ = '"') then
      begin
        fCurrRange.rString := false;
        readerPrev;
        goto _postString1;
      end;
    end;
    readerNext;
    fTokKind := tkStrng;
    while(true) do
    begin
      if not readUntilAmong(reader, fTokStop, stringStopChecks) then break;
      if (reader^ = '\') then
      begin
        readerNext;
        if reader^ <> #10 then
        begin
          if fCurrRange.rString then continue;
          readerNext;
        end;
      end
      else if reader^ = '"' then
      begin
        readerNext;
        readDelim(reader, fTokStop, stringPostfixes);
        fCurrRange.rString := false;
        exit;
      end;
    end;
    fCurrRange.rangeKinds += [rkString1];
    StartCodeFoldBlock(nil, fkStrings in fFoldKinds);
    exit;
  end else _postString1: readerReset;
  if rkString1 in fCurrRange.rangeKinds then
  begin
    fTokKind := tkStrng;
    while(true) do
    begin
      if not readUntilAmong(reader, fTokStop, stringStopChecks) then break;
      if reader^ = '\' then
      begin
        readerNext;
        if reader^ <> #10 then
        begin
          if fCurrRange.rString then continue;
          readerNext;
        end;
      end
      else if reader^ = '"' then
      begin
        readerNext;
        fCurrRange.rangeKinds -= [rkString1];
        readDelim(reader, fTokStop, stringPostfixes);
        fCurrRange.rString := false;
        EndCodeFoldBlock(fkStrings in fFoldKinds);
        exit;
      end
      else break;
    end;
    readLine(reader, fTokStop);
    exit;
  end;

  // string 2
  if (fCurrRange.rangeKinds = []) or (fCurrRange.rangeKinds = [rkTokString]) then
    if readDelim(reader, fTokStop, '`') then
  begin
    fTokKind := tkStrng;
    if readUntil(reader, fTokStop, '`') then
    begin
      readDelim(reader, fTokStop, stringPostfixes);
      exit;
    end;
    fCurrRange.rangeKinds += [rkString2];
    readLine(reader, fTokStop);
    StartCodeFoldBlock(nil, fkStrings in fFoldKinds);
    exit;
  end else readerReset;
  if rkString2 in fCurrRange.rangeKinds then
  begin
    fTokKind := tkStrng;
    if readUntil(reader, fTokStop, '`') then
    begin
      fCurrRange.rangeKinds -= [rkString2];
      EndCodeFoldBlock(fkStrings in fFoldKinds);
      readDelim(reader, fTokStop, stringPostfixes);
      exit;
    end;
    readLine(reader, fTokStop);
    exit;
  end;

  //token string
  if readDelim(reader, fTokStop, 'q{') then
  begin
    fTokKind := tkSymbl;
    inc(fCurrRange.tokenStringBracketsCount);
    fCurrRange.rangeKinds += [rkTokString];
    StartCodeFoldBlock(nil, fkBrackets in fFoldKinds);
    exit;
  end else readerReset;

  // char literals
  if (fCurrRange.rangeKinds = []) or (fCurrRange.rangeKinds = [rkTokString])
    then if readDelim(reader, fTokStop, #39) then
  begin
    fTokKind := tkStrng;
    while true do
    begin
      if reader^ = '\' then
      begin
        readerNext;
        if reader^ = #10 then
          exit;
        readerNext;
      end;
      if reader^ = #10 then
        exit;
      if reader^ = #39 then
        break;
      readerNext;
    end;
    readerNext;
    exit;
  end else readerReset;

  // numbers 1
  if (isNumber(reader^)) then
  begin
    while isAlNum(readerNext^) or (reader^ = '_') or (reader^ = '.') do (*!*);
    fTokKind := tkNumbr;
    exit;
  end;

  // symbols 1
  if isSymbol(reader^) then
  begin
    fTokKind := tkSymbl;
    case reader^ of
      '{': StartCodeFoldBlock(nil, fkBrackets in fFoldKinds);
      '}':
      begin
        EndCodeFoldBlock(fkBrackets in fFoldKinds);
        if (reader^ = '}') and (rkAsm in fCurrRange.rangeKinds) then
          fCurrRange.rangeKinds -= [rkAsm]; ;
        if (rkTokString in fCurrRange.rangeKinds) then
        begin
          Dec(fCurrRange.tokenStringBracketsCount);
          if (fCurrRange.tokenStringBracketsCount = 0) then
            fCurrRange.rangeKinds -= [rkTokString];
        end;
      end;
    end;
    readerNext;
    exit;
  end;

  // symbChars 2: operators
  if isOperator1(reader^) then
  begin
    fTokKind := tkSymbl;
    while isOperator1(readerNext^) do (*!*);
    case fTokStop - fTokStart of
      4:begin
          if (not isOperator1(reader^)) and
            isOperator4(fLineBuf[fTokStart..fTokStop-1])
          then exit;
        end;
      3:begin
          if (not isOperator1(reader^)) and
            isOperator3(fLineBuf[fTokStart..fTokStop-1])
          then exit;
        end;
      2:begin
          if (not isOperator1(reader^)) and
            isOperator2(fLineBuf[fTokStart..fTokStop-1])
          then exit;
        end;
      1:begin
          if not isOperator1(reader^) then exit;
        end;
    end;
    fTokKind := tkIdent; // invalid op not colorized.
  end;

  // Keyword - Identifier
  if not isWhite(reader^) then
  begin
    fTokKind := tkIdent;
    while(true) do
    begin
      if isWhite(readerNext^) then break;
      if isSymbol(reader^) then break;
      if isOperator1(reader^) then break;
    end;
    if fKeyWords.find(fLineBuf[FTokStart..fTokStop-1]) then
      fTokKind := tkKeywd
    else if fSpecKw.find(fLineBuf[FTokStart..fTokStop-1]) then
      fTokKind := tkSpecK
    else if fLineBuf[FTokStart..fTokStop-1]  = fCurrIdent then
      fTokKind := tkCurrI;
    //check asm range
    if fTokKind = tkKeywd then
      if fLineBuf[FTokStart..fTokStop-1] = 'asm' then
        fCurrRange.rangeKinds += [rkAsm];
    exit;
  end;

  if fLineBuf[fTokStop] = #10 then exit;

  // Should not happend
  assert(false);
end;

function TSynD2Syn.GetEol: Boolean;
begin
  result := fTokStop > length(fLineBuf);
end;

function TSynD2Syn.GetTokenAttribute: TSynHighlighterAttributes;
begin
  result := fAttribLut[fTokKind];
  if (rkAsm in fCurrRange.rangeKinds) then
    if (fTokKind <> tkSymbl) then
      if (fTokKind <> tkKeywd) then
        if (fTokKind <> tkCommt) then
          if (fTokKind <> tkDDocs) then
            result := fAsblrAttrib;
end;

procedure TSynD2Syn.SetRange(Value: Pointer);
var
  stored: TSynD2SynRange;
begin
  inherited SetRange(Value);
  stored := TSynD2SynRange(CodeFoldRange.RangeType);
  fCurrRange.copyFrom(stored);
end;

function TSynD2Syn.GetRange: Pointer;
var
  stored: TSynD2SynRange;
begin
  stored := TSynD2SynRange(inherited GetRange);
  if (stored = nil) then stored := TSynD2SynRange.Create(nil);
  stored.copyFrom(fCurrRange);
  //
  CodeFoldRange.RangeType := Pointer(stored);
  Result := inherited GetRange;
end;

procedure TSynD2Syn.ResetRange;
begin
  if fCurrRange = nil then
    fCurrRange := TSynD2SynRange.Create(nil)
  else
    fCurrRange.Clear;
end;

function TSynD2Syn.GetTokenPos: Integer;
begin
  result := fTokStart - 1;
end;

function TSynD2Syn.GetToken: string;
begin
  result := copy(fLineBuf, FTokStart, fTokStop - FTokStart);
end;

procedure TSynD2Syn.GetTokenEx(out TokenStart: PChar; out TokenLength: integer);
begin
  TokenStart  := @fLineBuf[FTokStart];
  TokenLength := fTokStop - FTokStart;
end;

function TSynD2Syn.GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_COMMENT: Result    := fCommtAttrib;
    SYN_ATTR_IDENTIFIER: Result := fIdentAttrib;
    SYN_ATTR_KEYWORD: Result    := fKeywdAttrib;
    SYN_ATTR_STRING: Result     := fStrngAttrib;
    SYN_ATTR_WHITESPACE: Result := fWhiteAttrib;
    SYN_ATTR_SYMBOL: Result     := fSymblAttrib;
    else Result := fIdentAttrib;
  end;
end;

function TSynD2Syn.GetTokenKind: integer;
var
  a: TSynHighlighterAttributes;
begin
  Result := SYN_ATTR_IDENTIFIER;
  a := GetTokenAttribute;
  if a = fIdentAttrib then Result := SYN_ATTR_IDENTIFIER  else
  if a = fWhiteAttrib then Result := SYN_ATTR_WHITESPACE  else
  if a = fCommtAttrib then Result := SYN_ATTR_COMMENT     else
  if a = fKeywdAttrib then Result := SYN_ATTR_KEYWORD     else
  if a = fStrngAttrib then Result := SYN_ATTR_STRING      else
  if a = fSymblAttrib then Result := SYN_ATTR_SYMBOL      else
  if a = fNumbrAttrib then Result := Ord(TTokenKind.tkNumbr);
end;

initialization
  registerClasses([TSynD2Syn]);
end.
