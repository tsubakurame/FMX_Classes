unit TsuFrameRateTimer;

interface
uses
  System.Math, System.SyncObjs, System.SysUtils,
  FMX.Platform, FMX.Types,
  TsuMath,
  TsuThreadEx
  ;

type
  TTsrIntervalTime  = record
    private
      FRate     : UInt32;
      FScale    : UInt32;
      FInterval : Array of UInt32;
      FIndex    : Integer;
      procedure SetRate(rate:UInt32);
      procedure SetScale(scale:UInt32);
      procedure CalcInterval;
      function ReadCount:Integer;
      function ReadInterval(x:Integer):UInt32;
    public
      constructor Create(rate,scale:Uint32);
      function GetInterval:UInt32;
      property Rate   : UInt32 read FRate write SetRate;
      property Scale  : UInt32 read FScale write SetScale;
      property Count  : Integer read ReadCount;
      property Interval[x:Integer] : UInt32 read ReadInterval;
  end;
  TTsrFrameRateTimerParams  = record
    Interval  : TTsrIntervalTime;
    EventGUID : String;
  end;
  TTscFrameRateTimerThread  = class(TTscThreadEx)
    private
      FInterval   : TTsrIntervalTime;
      FTimer      : IFMXTimerService;
      FStartTime  : Extended;
      FGUID       : string;
      FEvent      : TEvent;
      procedure ThreadMain;override;
      procedure Initialize;override;
      procedure DeInitialize;override;
    public
      constructor Create(params:TTsrFrameRateTimerParams);
  end;

  TTscFrameRateTimer  = class(TObject)
    private
      FTimerThread  : TTscFrameRateTimerThread;
      FEventGUID    : String;
      FInterval     : TTsrIntervalTime;
      FEvent        : TEvent;
      procedure SetRate(rate:UInt32);
      procedure SetScale(scale:UInt32);
      function GetRate:UInt32;
      function GetScale:UInt32;
    public
      constructor Create;
      procedure Start;
      procedure Stop;
      property Rate   : UInt32 read GetRate write SetRate;
      property Scale  : UInt32 read GetScale write SetScale;
      property EventGUID  : string read FEventGUID;
      property Event  : TEvent read FEvent write FEvent;
  end;

implementation
//uses
//  Winapi.Windows;

{$region'    TTscIntervalTime    '}
constructor TTsrIntervalTime.Create(rate,scale:Uint32);
begin
  FRate   := rate;
  FScale  := scale;
  CalcInterval;
end;

procedure TTsrIntervalTime.SetRate(rate:UInt32);
begin
  FRate := rate;
  CalcInterval;
end;

procedure TTsrIntervalTime.SetScale(scale:UInt32);
begin
  FScale  := scale;
  CalcInterval;
end;

procedure TTsrIntervalTime.CalcInterval;
var
  scale : UInt32;
  msec_per_frame  : UInt32;
  msec_per_frame_inc  : UInt32;
  mps_count, mps_inc_count  : UInt32;
  nGCD  : Integer;
  nCeil : Integer;
  I: Integer;
begin
//  OutputDebugString(PChar(IntToStr(FScale)+'/'+IntToStr(FRate)));
  try
    FIndex              := 0;
    scale               := FScale *1000;
    msec_per_frame      := Floor(scale / FRate);
    msec_per_frame_inc  := msec_per_frame +1;
    mps_inc_count       := scale - (msec_per_frame * FRate);
    nGCD                := TsfGCD(mps_count, mps_inc_count);
    mps_count           := mps_count div UInt32(nGCD);
    mps_inc_count       := mps_inc_count div UInt32(nGCD);
    SetLength(FInterval, mps_count +mps_inc_count);
    nCeil               := Ceil(mps_count / mps_inc_count);
    for I := 0 to Length(FInterval) -1 do
      begin
        if mps_count > mps_inc_count then
          begin
            if I mod (nCeil+1) = nCeil then
              begin
                FInterval[I]  := msec_per_frame_inc;
                Dec(mps_inc_count);
              end
            else
              begin
                FInterval[I]  := msec_per_frame;
                Dec(mps_count);
              end;
          end
        else
          begin
            if I mod 2 = 1 then
              begin
                FInterval[I]  := msec_per_frame_inc;
                Dec(mps_inc_count);
              end
            else
              begin
                FInterval[I]  := msec_per_frame;
                Dec(mps_count);
              end;
          end;
      end;
  except

  end;
end;

function TTsrIntervalTime.ReadCount:Integer;
begin
  Result  := Length(FInterval);
end;

function TTsrIntervalTime.ReadInterval(x:Integer):UInt32;
begin
  Result  := FInterval[x];
end;

function TTsrIntervalTime.GetInterval:UInt32;
begin
  Result  := FInterval[FIndex mod Count];
  Inc(FIndex);
end;
{$endregion}

{$region'    TTscFrameRateTimerThread    '}
constructor TTscFrameRateTimerThread.Create(params:TTsrFrameRateTimerParams);
var
  callbacks : TTsrThreadCallBacks;
begin
  FInterval := params.Interval;
  FGUID     := params.EventGUID;
  callbacks.Clear;
  inherited Create(callbacks);
end;

procedure TTscFrameRateTimerThread.ThreadMain;
var
  cashtime  : Extended;
begin
  try
    cashtime  := FTimer.GetTick;
    if cashtime >= FStartTime then
      begin
        FEvent.SetEvent;
        FStartTime  := FStartTime + (FInterval.GetInterval / 1000);
      end;
  except
    raise Exception.Create('timer error');
  end;
end;

procedure TTscFrameRateTimerThread.Initialize;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXTimerService, IInterface(FTimer)) then
    begin
      FStartTime  := FTimer.GetTick;
      FStartTime  := FStartTime + (FInterval.GetInterval / 1000);
      FEvent      := TEvent.Create(nil, False, False, FGUID);
    end;
end;

procedure TTscFrameRateTimerThread.DeInitialize;
begin
  FEvent.Free;
end;
{$endregion}

{$region'    TTscFrameRateTimer    '}
constructor TTscFrameRateTimer.Create;
var
  guid  : TGUID;
begin
  FTimerThread  := nil;
  CreateGUID(guid);
  FEventGUID  := guid.ToString;
  FEvent      := TEvent.Create(nil, False, False, FEventGUID);
end;

procedure TTscFrameRateTimer.Start;
var
  params  : TTsrFrameRateTimerParams;
begin
  params.Interval   := FInterval;
  params.EventGUID  := FEventGUID;
  if not Assigned(FTimerThread) then
    begin
      FTimerThread  := TTscFrameRateTimerThread.Create(params);
      FTimerThread.Start;
    end;
end;

procedure TTscFrameRateTimer.Stop;
begin
  FTimerThread.Terminate;
  FTimerThread  := nil;
//  FTimerThread.WaitFor;
//  FreeAndNil(FTimerThread);
end;

procedure TTscFrameRateTimer.SetRate(rate:UInt32);
begin
  FInterval.Rate  := rate;
end;

procedure TTscFrameRateTimer.SetScale(scale:UInt32);
begin
  FInterval.Scale := scale;
end;

function TTscFrameRateTimer.GetRate:UInt32;
begin
  Result  := FInterval.Rate;
end;

function TTscFrameRateTimer.GetScale:UInt32;
begin
  Result  := FInterval.Scale;
end;
{$endregion}

end.
