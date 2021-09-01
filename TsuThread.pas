unit TsuThread;

interface
uses
  System.Classes, System.Generics.Collections, System.SysUtils,
  {$IF FMX.Types.FireMonkeyVersion >= 0}
  FMX.Forms,
  {$ELSE}
  Vcl.Forms,
  {$IFEND}
  ExceptionLog7, EBase
  ;

type
  TTscThread = class(TThread)
  private
    { Private 宣言 }
    FTerminatedComp : Boolean;
//    FOnExecute      : TNotifyEvent;
    FOnTerminating  : TNotifyEvent;
    FOnThreadLoop   : TNotifyEvent;
    FLoopBreak      : Boolean;
    FExcpt          : TObject;
  protected
    procedure Execute; override;
    procedure Initialize;virtual;abstract;
    procedure Deinitialize;virtual;abstract;
    procedure ThreadMain;virtual;abstract;
    procedure ThrowException;
  public
    constructor Create;
    property TerminatedComp : Boolean read FTerminatedComp;
    property OnTerminate;
//    property OnExecute      : TNotifyEvent read FOnExecute write FOnExecute;
    property OnTerminating  : TNotifyEvent read FOnTerminating write FOnTerminating;
    property OnThreadLoop   : TNotifyEvent read FOnThreadLoop write FOnThreadLoop;
    property LoopBreak      : Boolean read FLoopBreak write FLoopBreak Default False;
    property Terminated;
  end;
  TTscThreadCtrl  = class(TObject)
    protected
      FThread : TTscThread;
      FOnTerminate  : TNotifyEvent;
      FActive       : Boolean;
      procedure ExecuteThread;virtual;abstract;
    public
      constructor Create;
      destructor  Destroy;override;
      procedure SetUp(par:Pointer);virtual;abstract;
      procedure Execute;
      procedure Terminate;
      procedure ThreadFree;
      property OnTerminate  : TNotifyEvent read FOnTerminate write FOnTerminate;
      property Active       : Boolean read FActive;
  end;

implementation

constructor TTscThread.Create;
begin
  FTerminatedComp := False;
  FLoopBreak  := False;
  inherited Create;
end;

procedure TTscThread.Execute;
begin
  try
    NameThread(ClassName);
    SetEurekaLogStateInThread(0, True);
//    if Assigned(FOnExecute) then
//      FOnExecute(Self);

    Initialize;

    while not Terminated do
      begin
        try
          if Assigned(FOnThreadLoop) then
            FOnThreadLoop(Self);
          ThreadMain;
          if LoopBreak then Break;
        except
          FExcpt  := FatalException;
          Break;
        end;
      end;

    if Assigned(FOnTerminating) then
      FOnTerminating(Self);

    Deinitialize;
    FTerminatedComp := True;
    //ThrowException;
    if Assigned(OnTerminate) then
      OnTerminate(Self);
  finally
  end;
end;

procedure TTscThread.ThrowException;
var
  E : TObject;
begin
  E := Self.FatalException;
  PPointer(@Self.FatalException)^ := nil;
  if Assigned(FExcpt) then
    raise FExcpt;
//  if Assigned(FOnException) then
//    begin
//      FOnException(Self, Exception(E));
//    end;
end;

constructor TTscThreadCtrl.Create;
begin
  FThread := nil;
  inherited Create;
end;

destructor TTscThreadCtrl.Destroy;
begin
  if FThread <> nil then
    FreeAndNil(FThread);
  inherited Destroy;
end;

procedure TTscThreadCtrl.Execute;
begin
  if not Assigned(FThread) then
    begin
      ExecuteThread;
      FActive := True;
    end;
end;

procedure TTscThreadCtrl.Terminate;
begin
  FThread.Terminate;
end;

procedure TTscThreadCtrl.ThreadFree;
begin
  FActive := False;
  FreeAndNil(FThread);
end;

end.
