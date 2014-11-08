unit ce_messages;

{$I ce_defines.inc}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  lcltype, ce_widget, ActnList, Menus, clipbrd, AnchorDocking, process, asyncprocess,
  ce_common, ce_project, ce_synmemo, ce_dlangutils, ce_interfaces, ce_observer;

type

  TMessageContext = (mcUnknown, mcProject, mcEditor, mcApplication);

  PMessageItemData = ^TMessageItemData;
  TMessageItemData = record
    ctxt: TMessageContext;
    editor: TCESynMemo;
    project: TCEProject;
    position: TPoint;
  end;

  TCEMessagesWidget = class(TCEWidget, ICEMultiDocObserver, ICEProjectObserver, ICELogMessageObserver)
    imgList: TImageList;
    List: TTreeView;
    procedure ListDblClick(Sender: TObject);
    procedure ListKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    fActClearAll: TAction;
    fActClearEdi: TAction;
    fActSaveMsg: TAction;
    fActCopyMsg: TAction;
    fActSelAll: TAction;
    fMaxMessCnt: Integer;
    fProj: TCEProject;
    fDoc: TCESynMemo;
    procedure filterMessages;
    procedure clearOutOfRangeMessg;
    procedure actClearEdiExecute(Sender: TObject);
    procedure actClearAllExecute(Sender: TObject);
    procedure actSaveMsgExecute(Sender: TObject);
    procedure actCopyMsgExecute(Sender: TObject);
    procedure actSelAllExecute(Sender: TObject);
    procedure setMaxMessageCount(aValue: Integer);
    procedure listDeletion(Sender: TObject; Node: TTreeNode);
    function newMessageItemData(aCtxt: TMessageContext): PMessageItemData;
    procedure processOutput(Sender: TObject);
    procedure processTerminate(Sender: TObject);
    procedure logProcessOutput(const aProcess: TProcess);
    //
    procedure optset_MaxMessageCount(aReader: TReader);
    procedure optget_MaxMessageCount(awriter: TWriter);
  published
    property maxMessageCount: Integer read fMaxMessCnt write setMaxMessageCount default 125;
  public
    constructor create(aOwner: TComponent); override;
    destructor destroy; override;
    //
    procedure scrollToBack;
    procedure addMessage(const aMsg: string; aCtxt: TMessageContext = mcUnknown);
    procedure addMessage(const aMsg: string; const aData: PMessageItemData);
    procedure addCeBub(const aMsg: string; aCtxt: TMessageContext = mcUnknown);
    procedure addCeInf(const aMsg: string; aCtxt: TMessageContext = mcUnknown);
    procedure addCeErr(const aMsg: string; aCtxt: TMessageContext = mcUnknown);
    procedure addCeWarn(const aMsg: string; aCtxt: TMessageContext = mcUnknown);
    //
    procedure sesoptDeclareProperties(aFiler: TFiler); override;
    //
    function contextName: string; override;
    function contextActionCount: integer; override;
    function contextAction(index: integer): TAction; override;
    //
    procedure projNew(const aProject: TCEProject);
    procedure projClosing(const aProject: TCEProject);
    procedure projFocused(const aProject: TCEProject);
    procedure projChanged(const aProject: TCEProject);
    //
    procedure docNew(const aDoc: TCESynMemo);
    procedure docClosing(const aDoc: TCESynMemo);
    procedure docFocused(const aDoc: TCESynMemo);
    procedure docChanged(const aDoc: TCESynMemo);
    //
    procedure lmStandard(const aValue: string; aData: Pointer;
      aCtxt: TCEAppMessageCtxt; aKind: TCEAppMessageKind);
    procedure lmProcess(const aValue: TProcess; aData: Pointer;
      aCtxt: TCEAppMessageCtxt; aKind: TCEAppMessageKind);
    //
    procedure ClearAllMessages;
    procedure ClearMessages(aCtxt: TMessageContext);
  end;

  TMessageKind = (msgkUnknown, msgkInfo, msgkHint, msgkWarn, msgkError);

  function semanticMsgAna(const aMessg: string): TMessageKind;
  function getLineFromDmdMessage(const aMessage: string): TPoint;
  function openFileFromDmdMessage(const aMessage: string): boolean;
  function newMessageData: PMessageItemData;

implementation
{$R *.lfm}

uses
  ce_main;

{$REGION Standard Comp/Obj------------------------------------------------------}
constructor TCEMessagesWidget.create(aOwner: TComponent);
begin
  fMaxMessCnt := 125;
  //
  fActClearAll := TAction.Create(self);
  fActClearAll.OnExecute := @actClearAllExecute;
  fActClearAll.caption := 'Clear all messages';
  fActClearEdi := TAction.Create(self);
  fActClearEdi.OnExecute := @actClearEdiExecute;
  fActClearEdi.caption := 'Clear editor messages';
  fActCopyMsg := TAction.Create(self);
  fActCopyMsg.OnExecute := @actCopyMsgExecute;
  fActCopyMsg.Caption := 'Copy message(s)';
  fActSelAll := TAction.Create(self);
  fActSelAll.OnExecute := @actSelAllExecute;
  fActSelAll.Caption := 'Select all';
  fActSaveMsg := TAction.Create(self);
  fActSaveMsg.OnExecute := @actSaveMsgExecute;
  fActSaveMsg.caption := 'Save selected message(s) to...';
  //
  inherited;
  //
  List.PopupMenu := contextMenu;
  List.OnDeletion := @ListDeletion;
  //
  EntitiesConnector.addObserver(self);
end;

destructor TCEMessagesWidget.destroy;
begin
  EntitiesConnector.removeObserver(self);
  Inherited;
end;

procedure TCEMessagesWidget.listDeletion(Sender: TObject; Node: TTreeNode);
begin
  if node.Data <> nil then
    Dispose( PMessageItemData(Node.Data));
end;

procedure TCEMessagesWidget.ListKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i: NativeInt;
begin
  if Key in [VK_BACK, VK_DELETE] then
  begin
    if List.SelectionCount > 0 then
    begin
    for i := List.Items.Count-1 downto 0 do
      if List.Items[i].MultiSelected then
        List.Items.Delete(List.Items[i]);
    end
    else ClearAllMessages;
  end;
end;
{$ENDREGION}

{$REGION ICESessionOptionsObserver ------------------------------------------------------}
procedure TCEMessagesWidget.setMaxMessageCount(aValue: Integer);
begin
  if aValue < 10 then aValue := 10;
  if aValue > 1023 then aValue := 1023;
  if fMaxMessCnt = aValue then exit;
  fMaxMessCnt := aValue;
  clearOutOfRangeMessg;
end;

procedure TCEMessagesWidget.optset_MaxMessageCount(aReader: TReader);
begin
  maxMessageCount := aReader.ReadInteger;
end;

procedure TCEMessagesWidget.optget_MaxMessageCount(aWriter: TWriter);
begin
  aWriter.WriteInteger(fMaxMessCnt);
end;

procedure TCEMessagesWidget.sesoptDeclareProperties(aFiler: TFiler);
begin
  inherited;
  aFiler.DefineProperty(Name + '_MaxMessageCount', @optset_MaxMessageCount, @optget_MaxMessageCount, true);
end;
{$ENDREGION}

{$REGION ICEContextualActions---------------------------------------------------}
function TCEMessagesWidget.contextName: string;
begin
  result := 'Messages';
end;

function TCEMessagesWidget.contextActionCount: integer;
begin
  result := 5;
end;

function TCEMessagesWidget.contextAction(index: integer): TAction;
begin
  case index of
    0: result := fActClearAll;
    1: result := fActClearEdi;
    2: result := fActCopyMsg;
    3: result := fActSelAll;
    4: result := fActSaveMsg;
    else result := nil;
  end;
end;

procedure TCEMessagesWidget.actClearAllExecute(Sender: TObject);
begin
  ClearAllMessages;
end;

procedure TCEMessagesWidget.actClearEdiExecute(Sender: TObject);
begin
  ClearMessages(mcEditor);
end;

procedure TCEMessagesWidget.actCopyMsgExecute(Sender: TObject);
var
  i: NativeInt;
  str: string;
begin
  str := '';
  for i := 0 to List.Items.Count-1 do if List.Items[i].MultiSelected then
    str += List.Items[i].Text + LineEnding;
  Clipboard.AsText := str;
end;

procedure TCEMessagesWidget.actSelAllExecute(Sender: TObject);
var
  i: NativeInt;
begin
  for i := 0 to List.Items.Count-1 do
      List.Items[i].MultiSelected := true;
end;

procedure TCEMessagesWidget.actSaveMsgExecute(Sender: TObject);
var
  lst: TStringList;
  itm: TtreeNode;
begin
  with TSaveDialog.Create(nil) do
  try
    if execute then
    begin
      lst := TStringList.Create;
      try
        for itm in List.Items do
          lst.Add(itm.Text);
        lst.SaveToFile(filename);
      finally
        lst.Free;
      end;
    end;
  finally
    free;
  end;
end;
{$ENDREGION}

{$REGION ICEProjectObserver ----------------------------------------------------}
procedure TCEMessagesWidget.projNew(const aProject: TCEProject);
begin
  fProj := aProject;
  filterMessages;
end;

procedure TCEMessagesWidget.projClosing(const aProject: TCEProject);
begin
  if fProj = aProject then
    ClearMessages(mcProject);
  fProj := nil;
  filterMessages;
end;

procedure TCEMessagesWidget.projFocused(const aProject: TCEProject);
begin
  fProj := aProject;
  filterMessages;
end;

procedure TCEMessagesWidget.projChanged(const aProject: TCEProject);
begin
end;
{$ENDREGION}

{$REGION ICEMultiDocObserver ---------------------------------------------------}
procedure TCEMessagesWidget.docNew(const aDoc: TCESynMemo);
begin
  fDoc := aDoc;
  filterMessages;
end;

procedure TCEMessagesWidget.docClosing(const aDoc: TCESynMemo);
begin
  if aDoc <> fDoc then exit;
  ClearMessages(mcEditor);
  fDoc := nil;
  filterMessages;
end;

procedure TCEMessagesWidget.docFocused(const aDoc: TCESynMemo);
begin
  fDoc := aDoc;
  filterMessages;
end;

procedure TCEMessagesWidget.docChanged(const aDoc: TCESynMemo);
begin
  fDoc := aDoc;
end;
{$ENDREGION}

{$REGION ICELogMessageObserver ---------------------------------------------------}

procedure TCEMessagesWidget.lmStandard(const aValue: string; aData: Pointer;
  aCtxt: TCEAppMessageCtxt; aKind: TCEAppMessageKind);
begin
    case aKInd of
    amkBub: addCeBub(aValue);
    amkInf: addCeInf(aValue);
    amkWarn:addCeWarn(aValue);
    amkErr: addCeErr(aValue);
  end;
  Application.ProcessMessages;
end;

procedure TCEMessagesWidget.lmProcess(const aValue: TProcess; aData: Pointer;
  aCtxt: TCEAppMessageCtxt; aKind: TCEAppMessageKind);
begin
   if not (poUsePipes in aValue.Options) then
    exit;
   //
  if aValue is TAsyncProcess then begin
    TAsyncProcess(aValue).OnReadData := @processOutput;
    TAsyncProcess(aValue).OnTerminate := @processTerminate;
  end else
    logProcessOutput(aValue);
  Application.ProcessMessages;
end;

procedure TCEMessagesWidget.processOutput(Sender: TObject);
begin
  logProcessOutput(TProcess(Sender));
end;

procedure TCEMessagesWidget.processTerminate(Sender: TObject);
begin
  logProcessOutput(TProcess(Sender));
end;

procedure TCEMessagesWidget.logProcessOutput(const aProcess: TProcess);
var
  lst: TStringList;
  str: string;
begin
  lst := TStringList.Create;
  try
    processOutputToStrings(aProcess, lst);
    for str in lst do
      addCeBub(str);
  finally
    lst.Free;
  end;
end;
{$ENDREGION}

{$REGION Messages --------------------------------------------------------------}
procedure TCEMessagesWidget.clearOutOfRangeMessg;
begin
  while List.Items.Count > fMaxMessCnt do
    List.Items.Delete(List.Items.GetFirstNode);
end;

function newMessageData: PMessageItemData;
begin
  result := new(PMessageItemData);
  result^.ctxt := mcUnknown;
  result^.project := nil;
  result^.editor := nil;
  result^.position := point(0,0);
end;

function TCEMessagesWidget.newMessageItemData(aCtxt: TMessageContext): PMessageItemData;
begin
  result := new(PMessageItemData);
  result^.ctxt := aCtxt;
  result^.project := fProj;
  result^.editor := fDoc;
  result^.position := point(0,0);
end;

procedure TCEMessagesWidget.scrollToBack;
begin
  if not Visible then exit;
  if List.BottomItem <> nil then
    List.BottomItem.MakeVisible;
end;

procedure TCEMessagesWidget.ListDblClick(Sender: TObject);
var
  dat: PMessageItemData;
begin
  if List.Selected = nil then exit;
  if List.Selected.Data = nil then exit;
  //
  dat := PMessageItemData(List.Selected.Data);
  if dat^.editor = nil then exit;
  CEMainForm.openFile(dat^.editor.fileName);
  dat^.editor.CaretXY := dat^.position;
  dat^.editor.SelectLine;
end;

procedure TCEMessagesWidget.filterMessages;
var
  itm: TTreeNode;
  dat: PMessageItemData;
  i: NativeInt;
begin
  if updating then exit;
  for i := 0 to List.Items.Count-1 do
  begin
    itm := List.Items[i];
    dat := PMessageItemData(itm.Data);
    case dat^.ctxt of
      mcProject: itm.Visible := fProj = dat^.project;
      mcEditor: itm.Visible := fDoc = dat^.editor;
      else itm.Visible := true;
    end;
  end;
end;

procedure TCEMessagesWidget.ClearAllMessages;
begin
  List.Items.Clear;
end;

procedure TCEMessagesWidget.ClearMessages(aCtxt: TMessageContext);
var
  i: Integer;
  dt: TMessageItemData;
begin
  for i := List.Items.Count-1 downto 0 do
  begin
    dt := PMessageItemData(List.Items[i].Data)^;
    if dt.ctxt = aCtxt then case aCtxt of
      mcEditor: if dt.editor = fDoc then List.Items.Delete(List.Items[i]);
      mcProject: if dt.project = fProj then List.Items.Delete(List.Items[i]);
      else List.Items.Delete(List.Items[i]);
    end;
  end;
end;

procedure TCEMessagesWidget.addCeBub(const aMsg: string; aCtxt: TMessageContext = mcUnknown);
var
  item: TTreeNode;
begin
  item := List.Items.Add(nil, 'Coedit message: ' + aMsg);
  item.Data := newMessageItemData(aCtxt);
  item.ImageIndex := 0;
  item.SelectedIndex := 0;
  clearOutOfRangeMessg;
  scrollToBack;
end;

procedure TCEMessagesWidget.addCeInf(const aMsg: string; aCtxt: TMessageContext = mcUnknown);
var
  item: TTreeNode;
begin
  item := List.Items.Add(nil, 'Coedit information: ' + aMsg);
  item.Data := newMessageItemData(aCtxt);
  item.ImageIndex := 1;
  item.SelectedIndex := 1;
  clearOutOfRangeMessg;
  scrollToBack;
end;

procedure TCEMessagesWidget.addCeWarn(const aMsg: string; aCtxt: TMessageContext = mcUnknown);
var
  item: TTreeNode;
begin
  item := List.Items.Add(nil, 'Coedit warning: ' + aMsg);
  item.Data := newMessageItemData(aCtxt);
  item.ImageIndex := 3;
  item.SelectedIndex := 3;
  clearOutOfRangeMessg;
  scrollToBack;
end;

procedure TCEMessagesWidget.addCeErr(const aMsg: string; aCtxt: TMessageContext = mcUnknown);
var
  item: TTreeNode;
begin
  item := List.Items.Add(nil, 'Coedit error: ' + aMsg);
  item.Data := newMessageItemData(aCtxt);
  item.ImageIndex := 4;
  item.SelectedIndex := 4;
  clearOutOfRangeMessg;
  scrollToBack;
end;

procedure TCEMessagesWidget.addMessage(const aMsg: string; const aData: PMessageItemData);
var
  item: TTreeNode;
  imgIx: Integer;
begin
  item := List.Items.Add(nil, aMsg);
  item.Data := aData;
  imgIx := Integer(semanticMsgAna(aMsg));
  item.ImageIndex := imgIx;
  item.SelectedIndex := imgIx;
  clearOutOfRangeMessg;
end;

procedure TCEMessagesWidget.addMessage(const aMsg: string; aCtxt: TMessageContext = mcUnknown);
var
  item: TTreeNode;
  imgIx: Integer;
begin
  item := List.Items.Add(nil, aMsg);
  item.Data := newMessageItemData(aCtxt);
  imgIx := Integer(semanticMsgAna(aMsg));
  item.ImageIndex := imgIx;
  item.SelectedIndex := imgIx;
  clearOutOfRangeMessg;
end;

function semanticMsgAna(const aMessg: string): TMessageKind;
var
  pos: Nativeint;
  idt: string;
function checkIdent: TMessageKind;
begin
  case idt of
    'ERROR', 'error', 'Error', 'Invalid', 'invalid',
    'exception', 'Exception', 'illegal', 'Illegal',
    'fatal', 'Fatal', 'Critical', 'critical':
      exit(msgkError);
    'Warning', 'warning', 'caution', 'Caution':
      exit(msgkWarn);
    'Hint', 'hint', 'Tip', 'tip', 'advice', 'Advice',
    'suggestion', 'Suggestion':
      exit(msgkHint);
    'Information', 'information':
      exit(msgkInfo);
    else
      exit(msgkUnknown);
  end;
end;
begin
  idt := '';
  pos := 1;
  result := msgkUnknown;
  while(true) do
  begin
    if pos > length(aMessg) then exit;
    if aMessg[pos] in [#0..#32] then
    begin
      Inc(pos);
      result := checkIdent;
      if result <> msgkUnknown then exit;
      idt := '';
      continue;
    end;
    if not (aMessg[pos] in ['a'..'z', 'A'..'Z']) then
    begin
      Inc(pos);
      result := checkIdent;
      if result <> msgkUnknown then exit;
      idt := '';
      continue;
    end;
    idt += aMessg[pos];
    Inc(pos);
  end;
end;

function getLineFromDmdMessage(const aMessage: string): TPoint;
var
  i, j: NativeInt;
  ident: string;
begin
  result.x := 0;
  result.y := 0;
  ident := '';
  i := 1;
  while (true) do
  begin
    if i > length(aMessage) then exit;
    if aMessage[i] = '.' then
    begin
      inc(i);
      if i > length(aMessage) then exit;
      if aMessage[i] = 'd' then
      begin
        inc(i);
        if i > length(aMessage) then exit;
        if aMessage[i] = '(' then
        begin
          inc(i);
          if i > length(aMessage) then exit;
          while( isNumber(aMessage[i]) or (aMessage[i] = ',')) do
          begin
            ident += aMessage[i];
            inc(i);
            if i > length(aMessage) then exit;
          end;
          if aMessage[i] = ')' then
          begin
            j := Pos(',', ident);
            if j = 0 then
              result.y := strToIntDef(ident, -1)
            else
            begin
              result.y := strToIntDef(ident[1..j-1], -1);
              result.x := strToIntDef(ident[j+1..length(ident)], -1);
            end;
            exit;
          end;
        end;
      end;
    end;
    inc(i);
  end;
end;

function openFileFromDmdMessage(const aMessage: string): boolean;
var
  i: NativeInt;
  ident: string;
  ext: string;
begin
  ident := '';
  i := 0;
  result := false;
  while(true) do
  begin
    inc(i);
    if i > length(aMessage) then exit;
    if aMessage[i] = '(' then
    begin
      if not fileExists(ident) then exit;
      ext := extractFileExt(ident);
      if not (ext = '.d') or (ext = '.di') then exit;
      CEMainForm.openFile(ident);
      result := true;
    end;
    ident += aMessage[i];
  end;
end;
{$ENDREGION}

end.
