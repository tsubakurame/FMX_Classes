unit TsuThreadEx;

interface
uses
  System.Classes, System.Generics.Collections, System.SysUtils,
  ExceptionLog7, EBase, EInject, EException, EEvents
  ;

type
  TTsrThreadCallBacks = object
    OnExecute     : TNotifyEvent;
    OnTerminate   : TNotifyEvent;
    OnTerminating : TNotifyEvent;
    OnThreadLoop  : TNotifyEvent;
    procedure Clear;
  end;
  TTscThreadEx  = class(TThreadEx)
    private
      FLoopBreak      : Boolean;
      FOnExecute      : TNotifyEvent;
      FOnTerminating  : TNotifyEvent;
      FOnThreadLoop   : TNotifyEvent;
    protected
      procedure Execute;override;
      procedure Initialize;virtual;abstract;
      procedure ThreadMain;virtual;abstract;
      procedure DeInitialize;virtual;abstract;
    public
      constructor Create(callbacks:TTsrThreadCallBacks);

      property OnTerminate;
      property OnExecute      : TNotifyEvent  read FOnExecute     write FOnExecute;
      property OnTerminating  : TNotifyEvent  read FOnTerminating write FOnTerminating;
      property LoopBreak      : Boolean       read FLoopBreak     write FloopBreak;
      property OnThreadLoop   : TNotifyEvent  read FOnThreadLoop  write FOnThreadLoop;
      property Terminated;
  end;
  TTscThreadExCtrl  = class(TObject)
    private
      function GetFinished:Boolean;
      procedure ExceptProcEvent(AExceptionInfo: TEurekaExceptionInfo;
                                var AHandle: Boolean;
                                var ACallNextHandler: Boolean);
    protected
      FThread       : TTscThreadEx;
      FOnTerminate  : TNotifyEvent;
      FActive       : Boolean;
      FCallBacks    : TTsrThreadCallBacks;
      procedure Terminate;
      procedure ThreadFree;
      procedure ExecuteThread;virtual;abstract;
      procedure ThreadOnTerminate(Sender:TObject);
    public
      constructor Create;
      destructor  Destroy;override;
      procedure SetUp(callbacks:TTsrThreadCallBacks; params:Pointer);virtual;
      procedure Execute;
      procedure TerminateAndNil;
      property OnTerminate  : TNotifyEvent read FOnTerminate write FOnTerminate;
      property Active       : Boolean read FActive;
      property Finished     : Boolean read GetFinished;
  end;

implementation

procedure TTsrThreadCallBacks.Clear;
begin
  OnExecute := nil;
  OnTerminate := nil;
  OnTerminating := nil;
  OnThreadLoop  := nil;
end;

{$region'    TTscThreadEx    '}
constructor TTscThreadEx.Create(callbacks:TTsrThreadCallBacks);
begin
  FLoopBreak          := False;
  AutoHandleException := True;
  FreeOnTerminate     := True;
  OnTerminate         := callbacks.OnTerminate;
  FOnExecute          := callbacks.OnExecute;
  FOnTerminating      := callbacks.OnTerminating;
  FOnThreadLoop       := callbacks.OnThreadLoop;
  inherited Create(True, ClassName);
end;

procedure TTscThreadEx.Execute;
begin
  if Assigned(OnExecute) then OnExecute(Self);
  try
    Initialize;
  except
  end;

  while not Terminated do
    begin
      if Assigned(OnThreadLoop) then OnThreadLoop(Self);
      ThreadMain;
      if LoopBreak then Break;
    end;

  if Assigned(OnTerminating) then OnTerminating(Self);
  try
    DeInitialize;
  except
  end;
  if Assigned(OnTerminate) then OnTerminate(Self);
end;
{$endregion}

{$region'    TTscThreadExCtrl    '}
constructor TTscThreadExCtrl.Create;
begin
  FThread := nil;
  RegisterEventExceptionNotify(ExceptProcEvent, False);
  inherited Create;
end;

destructor TTscThreadExCtrl.Destroy;
begin
  if FThread <> nil then
    FreeAndNil(FThread);
  inherited Destroy;
end;

procedure TTscThreadExCtrl.Execute;
begin
  if not Assigned(FThread) then
    begin
      ExecuteThread;
      FThread.Start;
      FActive := True;
    end;
end;

procedure TTscThreadExCtrl.Terminate;
begin
  if Assigned(FThread) then
    if not FThread.Finished then
      FThread.Terminate;
  if Assigned(FOnTerminate) then FOnTerminate(Self);  
  FActive := False;
end;

procedure TTscThreadExCtrl.ThreadFree;
begin
  FThread := nil;
end;

procedure TTscThreadExCtrl.SetUp(callbacks:TTsrThreadCallBacks; params:Pointer);
begin
  FCallBacks  := callbacks;
  FOnTerminate  := callbacks.OnTerminate;
  FCallBacks.OnTerminate  := ThreadOnTerminate;
end;

procedure TTscThreadExCtrl.ThreadOnTerminate(Sender: TObject);
begin
  TerminateAndNil;
end;

function TTscThreadExCtrl.GetFinished: Boolean;
begin
  if Assigned(FThread) then
    Result  := FThread.Finished
  else
    Result  := True;
end;

procedure TTscThreadExCtrl.TerminateAndNil;
begin
  Terminate;
  ThreadFree;
end;

procedure TTscThreadExCtrl.ExceptProcEvent(AExceptionInfo: TEurekaExceptionInfo;
                                          var AHandle: Boolean;
                                          var ACallNextHandler: Boolean);
begin
  if Assigned(FThread) then
    begin
      if AExceptionInfo.ThreadID = FThread.ThreadID then TerminateAndNil;
    end;
end;
{$endregion}

end.
