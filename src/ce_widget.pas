unit ce_widget;

{$I ce_defines.inc}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, ExtCtrls, ActnList, Menus,
  ce_interfaces;

type

  (**
   * Base type for an UI module.
   *)
  PTCEWidget = ^TCEWidget;
  TCEWidget = class(TForm, ICEContextualActions, ICESessionOptionsObserver)
    Content: TPanel;
    Back: TPanel;
    contextMenu: TPopupMenu;
  private
    fUpdating: boolean;
    fDelayDur: Integer;
    fLoopInter: Integer;
    fUpdaterAuto: TTimer;
    fUpdaterDelay: TTimer;
    fWidgUpdateCount: NativeInt;
    procedure setDelayDur(aValue: Integer);
    procedure setLoopInt(aValue: Integer);
    procedure updaterAutoProc(Sender: TObject);
    procedure updaterLatchProc(Sender: TObject);
    //
    procedure optget_LoopInterval(aWriter: TWriter);
    procedure optset_LoopInterval(aReader: TReader);
    procedure optget_UpdaterDelay(aWriter: TWriter);
    procedure optset_UpdaterDelay(aReader: TReader);
  protected
    fID: string;
    // a descendant overrides to implementi a periodic update.
    procedure UpdateByLoop; virtual;
    // a descendant overrides to implement an event driven update.
    procedure UpdateByEvent; virtual;
    // a descendant overrides to implement a delayed update event.
    procedure UpdateByDelay; virtual;
  // May be used for appplication options
  published
    property updaterByLoopInterval: Integer read fLoopInter write setLoopInt;
    property updaterByDelayDuration: Integer read fDelayDur write setDelayDur;
  public
    constructor create(aOwner: TComponent); override;
    destructor destroy; override;
    // restarts the wait period to the delayed update event.
    // if not re-called during 'updaterByDelayDuration' ms then
    // 'UpdateByDelay' is called once.
    procedure beginUpdateByDelay;
    // prevent any pending update.
    procedure stopUpdateByDelay;
    // immediate call any pending update.
    procedure endUpdatebyDelay;
    // increments the updates count.
    procedure beginUpdateByEvent;
    // decrements the update count and call 'UpdateByEvent' if the
    // counter value is null.
    procedure endUpdateByEvent;
    // immediate call 'UpdateByEvent'
    procedure forceUpdateByEvent;
    //
    function contextName: string; virtual;
    function contextActionCount: integer; virtual;
    function contextAction(index: integer): TAction; virtual;
    //
    procedure sesoptBeforeSave; virtual;
    procedure sesoptDeclareProperties(aFiler: TFiler); virtual;
    procedure sesoptAfterLoad; virtual;
    //
    // returns true if one of the three updater is processing.
    property updating: boolean read fUpdating;
  end;

  (**
   * TCEWidget list.
   *)
  TCEWidgetList = class(TFPList)
  private
    function getWidget(index: integer): TCEWidget;
  public
    procedure addWidget(aValue: PTCEWidget);
    property widget[index: integer]: TCEWidget read getWidget;
  end;

  TWidgetEnumerator = class
    fList: TCEWidgetList;
    fIndex: Integer;
    function getCurrent: TCEWidget;
    Function moveNext: boolean;
    property current: TCEWidget read getCurrent;
  end;

  operator enumerator(aWidgetList: TCEWidgetList): TWidgetEnumerator;

implementation
{$R *.lfm}

uses
  ce_observer;

{$REGION Standard Comp/Obj------------------------------------------------------}
constructor TCEWidget.create(aOwner: TComponent);
var
  i: NativeInt;
  itm: TmenuItem;
begin
  inherited;
  fUpdaterAuto := TTimer.Create(self);
  fUpdaterAuto.Interval := 70;
  fUpdaterAuto.OnTimer := @updaterAutoProc;
  fUpdaterDelay := TTimer.Create(self);

  updaterByLoopInterval := 70;
  updaterByDelayDuration := 500;

  for i := 0 to contextActionCount-1 do
  begin
    itm := TMenuItem.Create(self);
    itm.Action := contextAction(i);
    contextMenu.Items.Add(itm);
  end;
  PopupMenu := contextMenu;

  EntitiesConnector.addObserver(self);
end;

destructor TCEWidget.destroy;
begin
  EntitiesConnector.removeObserver(self);
  inherited;
end;
{$ENDREGION}

{$REGION ICESessionOptionsObserver ---------------------------------------------}
procedure TCEWidget.sesoptBeforeSave;
begin
end;

procedure TCEWidget.sesoptDeclareProperties(aFiler: TFiler);
begin
  // override rules: inherited must be called. No dots in the property name, property name prefixed with the widget Name
  aFiler.DefineProperty(Name + '_updaterByLoopInterval', @optset_LoopInterval, @optget_LoopInterval, true);
  aFiler.DefineProperty(Name + '_updaterByDelayDuration', @optset_UpdaterDelay, @optget_UpdaterDelay, true);
end;

procedure TCEWidget.sesoptAfterLoad;
begin
end;

procedure TCEWidget.optget_LoopInterval(aWriter: TWriter);
begin
  aWriter.WriteInteger(fLoopInter);
end;

procedure TCEWidget.optset_LoopInterval(aReader: TReader);
begin
  updaterByLoopInterval := aReader.ReadInteger;
end;

procedure TCEWidget.optget_UpdaterDelay(aWriter: TWriter);
begin
  aWriter.WriteInteger(fDelayDur);
end;

procedure TCEWidget.optset_UpdaterDelay(aReader: TReader);
begin
  updaterByDelayDuration := aReader.ReadInteger;
end;
{$ENDREGION}

{$REGION ICEContextualActions---------------------------------------------------}
function TCEWidget.contextName: string;
begin
  result := '';
end;

function TCEWidget.contextActionCount: integer;
begin
  result := 0;
end;

function TCEWidget.contextAction(index: integer): TAction;
begin
  result := nil;
end;
{$ENDREGION}

{$REGION Updaters---------------------------------------------------------------}
procedure TCEWidget.setDelayDur(aValue: Integer);
begin
  if aValue < 100 then aValue := 100;
  if fDelayDur = aValue then exit;
  fDelayDur := aValue;
  fUpdaterDelay.Interval := fDelayDur;
end;

procedure TCEWidget.setLoopInt(aValue: Integer);
begin
  if aValue < 30 then aValue := 30;
  if fLoopInter = aValue then exit;
  fLoopInter := aValue;
  fUpdaterAuto.Interval := fLoopInter;
end;

procedure TCEWidget.beginUpdateByEvent;
begin
  Inc(fWidgUpdateCount);
end;

procedure TCEWidget.endUpdateByEvent;
begin
  Dec(fWidgUpdateCount);
  if fWidgUpdateCount > 0 then exit;
  fUpdating := true;
  UpdateByEvent;
  fUpdating := false;
  fWidgUpdateCount := 0;
end;

procedure TCEWidget.forceUpdateByEvent;
begin
  fUpdating := true;
  UpdateByEvent;
  fUpdating := false;
  fWidgUpdateCount := 0;
end;

procedure TCEWidget.beginUpdateByDelay;
begin
  fUpdaterDelay.Enabled := false;
  fUpdaterDelay.Enabled := true;
  fUpdaterDelay.OnTimer := @updaterLatchProc;
end;

procedure TCEWidget.stopUpdateByDelay;
begin
  fUpdaterDelay.OnTimer := nil;
end;

procedure TCEWidget.endUpdateByDelay;
begin
  updaterLatchProc(nil);
end;

procedure TCEWidget.updaterAutoProc(Sender: TObject);
begin
  fUpdating := true;
  UpdateByLoop;
  fUpdating := false;
end;

procedure TCEWidget.updaterLatchProc(Sender: TObject);
begin
  fUpdating := true;
  UpdateByDelay;
  fUpdating := false;
  fUpdaterDelay.OnTimer := nil;
end;

procedure TCEWidget.UpdateByLoop;
begin
end;

procedure TCEWidget.UpdateByEvent;
begin
end;

procedure TCEWidget.UpdateByDelay;
begin
end;
{$ENDREGION}

{$REGION TCEWidgetList----------------------------------------------------------}
function TCEWidgetList.getWidget(index: integer): TCEWidget;
begin
  result := PTCEWidget(Items[index])^;
end;

procedure TCEWidgetList.addWidget(aValue: PTCEWidget);
begin
  add(Pointer(aValue));
end;

function TWidgetEnumerator.getCurrent:TCEWidget;
begin
  result := fList.widget[fIndex];
end;

function TWidgetEnumerator.moveNext: boolean;
begin
  Inc(fIndex);
  result := fIndex < fList.Count;
end;

operator enumerator(aWidgetList: TCEWidgetList): TWidgetEnumerator;
begin
  result := TWidgetEnumerator.Create;
  result.fList := aWidgetList;
  result.fIndex := -1;
end;
{$ENDREGION}

end.
