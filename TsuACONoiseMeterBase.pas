unit TsuACONoiseMeterBase;

interface
uses
  //Winapi.Windows,
  System.SysUtils, System.StrUtils, System.Classes,
  TsuComPort, TsuComTypes, TsuAppData, TsuACOTypes
  ;

type
  TTscACONoiseMeterBase  = class(TObject)
    protected
      FCom  : TTscComPort;
      FPort : string;
      app_data_path : string;
      FState  : TTseMeterState;
      FOnReceive  : TTsdGetStrFunction;
      FAppData  : TTscAppData;
      FOnMeasStop : TNotifyEvent;
      FOnDataSetDone  : TNotifyEvent;
      FOnGetData  : TTsdACOMeterGetDataEvent;
      FOnGetIV    : TTsdACOMeterGetDataEvent;
      procedure Send(str:string);
      procedure ReceivedCommand(str:string);virtual;abstract;
      procedure GetSettings;virtual;abstract;
      procedure SetAppDataPath;virtual;abstract;
    private
      procedure OnComReceive(Sender:TObject; str:string);
    public
      constructor Create(port:string);
      procedure Open;
      procedure Close;
      procedure TimeSet;overload;
      procedure TimeSet(time:TDateTime);overload;
      procedure MeasStart;
      procedure MeasStop;
      procedure GetData;virtual;
      procedure CAL;
      property OnMeasStop     : TNotifyEvent read FOnMeasStop write FOnMeasStop;
      property OnDataSetDone  : TNotifyEvent read FOnDataSetDone write FOnDataSetDone;
      property OnGetData      : TTsdACOMeterGetDataEvent read FOnGetData write FOnGetData;
      property OnGetIV        : TTsdACOMeterGetDataEvent read FOnGetIV write FOnGetIV;
  end;

implementation

constructor TTscACONoiseMeterBase.Create(port:string);
begin
  FPort := port;
  FCom  := TTscComPort.Create;
  FCom.Delimiter  := DL_CRLF_ONE_SIDE;
  FCom.OnReceived := OnComReceive;
  FState  := STT_IDLE;
  SetAppDataPath;
end;

procedure TTscACONoiseMeterBase.Open;
begin
  FCom.Open(FPort, app_data_path);
end;

procedure TTscACONoiseMeterBase.Close;
begin
  FCom.Close;
end;

procedure TTscACONoiseMeterBase.TimeSet;
begin
  TimeSet(now);
end;

procedure TTscACONoiseMeterBase.TimeSet(time:TDateTime);
var
  str :string;
begin
  DateTimeToString(str, 'yyyyMMddHHmmss', time);
  str := RightStr(str, 12);
  Send('T'+str);
end;

procedure TTscACONoiseMeterBase.MeasStart;
begin
  Send('S');
end;

procedure TTscACONoiseMeterBase.MeasStop;
begin
  Send('E');
end;

procedure TTscACONoiseMeterBase.GetData;
begin
  Send('D');
end;

procedure TTscACONoiseMeterBase.CAL;
begin
  Send('C');
end;

procedure TTscACONoiseMeterBase.OnComReceive(Sender:TObject; str:string);
begin
  //OutputDebugString(PChar(str));
  if str = 'e' then
    begin
      if Assigned(FOnMeasStop) then
        FOnMeasStop(Self);
    end
  else if str = 'r' then
    begin
      if Assigned(FOnDataSetDone) then
        FOnDataSetDone(Self)
    end
  else if str <> '' then
    begin
      if str = 's' then FState  := STT_MEAS
      else ReceivedCommand(str);
    end;
end;

procedure TTscACONoiseMeterBase.Send(str:string);
begin
  if FCom.Opend then FCom.SendLine(str);  
end;

end.
