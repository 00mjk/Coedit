unit ce_dcd;

{$I ce_defines.inc}

interface

uses
  Classes, SysUtils, process, forms, strutils, ce_common;


(**
 * frees the server: e.g: to remove some bugy imports from the libman.
 *)
procedure freeServer;

(**
 * recreates the server.
 *)
procedure createServer;

(**
 * Adds a folder of d sources for DCD.
 *)
procedure addDcdImport(const aFilename: string);

(**
 * gets a list of propositions for the identifier at aPosition in aFilename.
 *)
procedure getCompletion(const aFilename: string; aPosition: Integer; const list: TStrings);

(**
 * tries to get the DDoc comment for the identifier at aPosition in aFilename.
 *)
procedure getHint(const aFilename: string; aPosition: Integer; const list: TStrings);

(**
 * tries to get the symbol location of the identifier at aPosition in aFilename.
 * after the call aFilename and aPosition contains the location filename and position.
 *)
procedure getSymbolLoc(var aFilename: string; var aPosition: Integer);

var
  DCD_server: TProcess = nil;
  DCD_client: TProcess = nil;
  lines: TStringList;
  dcdOn: boolean;

implementation

procedure lazyServerStart;
begin
  if not DCD_server.Running then
    DCD_server.Execute;
end;

procedure freeServer;
begin
  while DCD_client.Running do;
  DCD_client.Parameters.Clear;
  DCD_client.Parameters.Add('--shutdown');
  DCD_client.Execute;
  if DCD_server <> nil then
    FreeAndNil(DCD_server);
end;

procedure createServer;
begin
  if DCD_server <> nil then
    FreeAndNil(DCD_server);
  DCD_server := TProcess.Create(nil);
  DCD_server.Executable := 'dcd-server' + exeExt;
  DCD_server.Options := [poUsePipes{$IFDEF WINDOWS}, poNewConsole{$ENDIF}];
  DCD_server.ShowWindow := swoHIDE;
end;

procedure addDcdImport(const aFilename: string);
begin
  if not dcdOn then exit;
  //
  if not DCD_server.Running then
    DCD_server.Parameters.Add('-I'+ aFilename)
  else if DCD_client <> nil then begin
    DCD_client.Parameters.Clear;
    DCD_client.Parameters.Add('-I'+ aFilename);
    DCD_client.Execute;
  end;
end;

procedure getCompletion(const aFilename: string; aPosition: Integer; const list: TStrings);
var
  i, j: NativeInt;
  kind: Char;
  item: string;
  asComp, asTips: boolean;
begin
  if not dcdOn then exit;
  lazyServerStart;
  //
  DCD_client.Parameters.Clear;
  DCD_client.Parameters.Add('-c');
  DCD_client.Parameters.Add(intToStr(aPosition));
  DCD_client.Parameters.Add(aFilename);
  DCD_client.Execute;
  //
  lines.LoadFromStream(DCD_client.Output);
  if lines.Count = 0 then
    exit;
  asComp := lines.Strings[0] = 'identifiers';
  asTips := lines.Strings[0] = 'calltips';
  if asTips then
    exit;
  if asComp then j := 1 else j := 0;
  list.Clear;
  for i := j to lines.Count-1 do
  begin
    item := lines.Strings[i];
    kind := item[length(item)];
    setLength(item, length(item)-2);
    case kind of
      'c': item += ' (class)            ';
      'i': item += ' (interface)        ';
      's': item += ' (struct)           ';
      'u': item += ' (union)            ';
      'v': item += ' (variable)         ';
      'm': item += ' (member)           ';
      'k': item += ' (reserved word)    ';
      'f': item += ' (function)         ';
      'g': item += ' (enum)             ';
      'e': item += ' (enum member)      ';
      'P': item += ' (package)          ';
      'M': item += ' (module)           ';
      'a': item += ' (array)            ';
      'A': item += ' (associative array)';
      'l': item += ' (alias)            ';
      't': item += ' (template)         ';
      'T': item += ' (mixin)            ';
    end;
    list.Add(item);
  end;
end;

procedure getHint(const aFilename: string; aPosition: Integer; const list: TStrings);
var
  i: Integer;
  str: string;
begin
  if not dcdOn then exit;
  lazyServerStart;
  //
  if DCD_client.Running then exit;
  //
  DCD_client.Parameters.Clear;
  DCD_client.Parameters.Add('-c');
  DCD_client.Parameters.Add(intToStr(aPosition));
  DCD_client.Parameters.Add('-d');
  DCD_client.Parameters.Add(aFilename);
  DCD_client.Execute;
  //
  list.LoadFromStream(DCD_client.Output);
  for i := 0 to list.Count-1 do
  begin
    str := list.Strings[i];
    list.Strings[i] := ReplaceStr(str, '\n', '');
  end;
end;

procedure getSymbolLoc(var aFilename: string; var aPosition: Integer);
var
  i: Integer;
  str, loc: string;
begin
  if not dcdOn then exit;
  lazyServerStart;
  //
  if DCD_client.Running then exit;
  //
  DCD_client.Parameters.Clear;
  DCD_client.Parameters.Add('-l');
  DCD_client.Parameters.Add('-c');
  DCD_client.Parameters.Add(intToStr(aPosition));
  DCD_client.Parameters.Add(aFilename);
  DCD_client.Execute;
  //
  str := 'a';
  setlength(str, 256);
  i := DCD_client.Output.Read(str[1], 256);
  setLength(str, i);
  if str <> '' then
  begin
    i := Pos(#9, str);
    if i = -1 then exit;
    loc := str[i+1..length(str)];
    str := str[1..i-1];
    aFilename := str;
    loc := ReplaceStr(loc, LineEnding, '');
    aPosition := strToIntDef(loc, -1);
  end;
end;

initialization
  createServer;
  DCD_client := TProcess.Create(nil);
  DCD_client.Executable := 'dcd-client' + exeExt;
  DCD_client.Options := [poUsePipes{$IFDEF WINDOWS}, poNewConsole{$ENDIF}];
  DCD_client.ShowWindow := swoHIDE;
  dcdOn := exeInSysPath(DCD_server.Executable) and exeInSysPath(DCD_client.Executable);
  lines := TStringList.Create;
finalization
  DCD_server.Active := false;
  DCD_client.Active := false;
  DCD_server.Free;
  DCD_client.Free;
  lines.Free;
end.
