unit TsuComPort;

interface
uses
  System.SysUtils, System.Classes,
  TsuComTypes, TsuCom
  ;

const
  IXQUECOMM_VER = 1;
  RECEIVE_TIMEOUT_DEFAULT = 100;

type
  TTscComPort = class(TObject)
    private
      FBaudRate     : UInt32;
      FStopBits     : TTseStopBits;
      FParityBits   : TTseParityBits;
      FDataBits     : TTseDataBits;
      FDelimiter    : TTseDelimiter;
      FComPortState : TTseComPortState;
      FGetStrEvent    : TTsdGetStrFunction;
      procedure SetDataBits(const Value: TTseDataBits);
      procedure SetParityBits(const Value: TTseParityBits);
      procedure SetStopBits(const Value: TTseStopBits);
      procedure SetBaudRate(const Value: UInt32);
      procedure SetDelimiter(const Value: TTseDelimiter);
      function GetPortName:string;
    protected
      Com             : TTscCom;
      arr             : TBytes;
      arr_count       : integer;
      SendLines       : TStringList;
      ss              : TStringStream;
      Log             : TStreamWriter;
      DelimiterByte   : Byte;
      DelimiterStr    : string;
      buff            : string;
      rec_count       : integer;
      delimiter_rcv   : array[1..2] of Boolean;
      procedure Com1ComReceive(Sender: TObject; Size: Word);
      procedure arr_add(Value: Byte);
      procedure memo(str: String);
      function SendLinesDeque: string;
      function GetComOpened:Boolean;
      function DelimiterReceive(val:byte):Boolean;
      procedure DelimiterFlagClear;
    public
      MemoStrings     : TStrings;
      ReceiveTimeOut  : integer;
      LocalEchoCancel : boolean;
      constructor Create;
      destructor Destroy; override;
      procedure Open(port_name: string; appdata_path: string);
      procedure Close;
      procedure ReceivedLine(line: string); overload;
      procedure ReceivedLine(line: string; tm: TDateTime); overload;
      procedure SendLine(line: string);

      property OnReceived : TTsdGetStrFunction read FGetStrEvent write FGetStrEvent;
      property Opend      : Boolean read GetComOpened;
      property Port       : string read GetPortName;
      property DataBits   : TTseDataBits read FDataBits write SetDataBits default DB_8;
      property StopBits   : TTseStopBits read FStopBits write SetStopBits default SB_1;
      property ParityBits : TTseParityBits read FParityBits write SetParityBits default PB_NONE;
      property Delimiter  : TTseDelimiter read FDelimiter write SetDelimiter default DL_CRLF;
      property BaudRate   : UInt32 read FBaudRate write SetBaudRate default 9600;
  end;

implementation
uses
  TsuPathUtilsFMX, TsuComUtils;

constructor TTscComPort.Create;
begin
  ReceiveTimeOut := RECEIVE_TIMEOUT_DEFAULT;

  SetLength(arr, 4096);
  arr_count := 0;

  SendLines := TStringList.Create;

  ss := TStringStream.Create('', TEncoding.ANSI);

  Com := nil;
  Log := nil;
  MemoStrings := nil;

  LocalEchoCancel := false;
  SetDelimiter(DL_CRLF);
  DelimiterFlagClear;
end;

destructor TTscComPort.Destroy;
begin
  if Com <> nil then
  begin
    Com.Close;
    FreeAndNil(Com);
  end;

  if Log <> nil then
    FreeAndNil(Log);

  SendLines.Free;
  ss.Free;

  inherited Destroy;
end;

procedure TTscComPort.Open(port_name: string; appdata_path: string);
var
  logpath : string;
  dt      : TDateTime;
  logname : string;
begin
  if Com <> nil then
    begin
      Com.Close;
      FreeAndNil(Com);
    end;

  port_name := TsfComPortListNameToComPortNumber(port_name);

  if Pos('COM', port_name) = 1 then
    begin
      Com                     := TTscCom.Create(nil);
      Com.BaudRateUserDefined := FBaudRate;
      Com.DataBits            := FDataBits;
      Com.ParityBits          := FParityBits;
      Com.StopBits            := FStopBits;
      Com.FlowControls        := [];
      Com.OnComReceive        := Com1ComReceive;

      Com.Port := port_name;
      Com.Open;

      if Log <> nil then
        Log.Free;
      logpath := IncludeTrailingPathDelimiter(appdata_path)+'ComLog';
      TspDirectoryExistsForce(logpath);
      dt  := Now;
      DateTimeToString(logname, 'yyyyMMdd_HHmmss', dt);
      logname := logname +'_'+ port_name + '.log';
      logpath := IncludeTrailingPathDelimiter(logpath) + logname;
      Log := TStreamWriter.Create(logpath, true);
    end
  else
    raise TTsxComOpenError(1);
end;

procedure TTscComPort.Close;
begin
  if Com <> nil then
  begin
    Com.Close;
    FreeAndNil(Com);
  end;

  if Log <> nil then
    FreeAndNil(Log);
end;

procedure TTscComPort.SetDelimiter(const Value: TTseDelimiter);
begin
  FDelimiter := Value;

  case FDelimiter of
    DL_CR:
      begin
        DelimiterByte := 13;
        DelimiterStr  := #$D;
      end;
    DL_LF:
      begin
        DelimiterByte := 10;
        DelimiterStr  := #$A;
      end;
    DL_CRLF:
      begin
        DelimiterByte := $DA;
        DelimiterStr  := #$D#$A;
      end;
    DL_CRLF_ONE_SIDE:
      begin
        DelimiterByte := $DA;
        DelimiterStr  := #$D#$A;
      end
  else
    DelimiterByte := 0;
  end;
end;

procedure TTscComPort.Com1ComReceive(Sender: TObject; Size: Word);
var
  read_buf: PByte;
  i: integer;
  val: Byte;
  ptr: PByte;
  str: string;
begin
  read_buf := GetMemory(Size);
  try
    Com.Read(read_buf, Size);

    ptr := read_buf;
    for i := 0 to Size - 1 do
      begin
        val := ptr^;
        inc(ptr);

        if val = 0 then
          begin
            // USB-RS485-WEだと、なぜか1バイト余計なゼロがくる挙動があるので、その対策。
            // COM,D2XX共に同じ症状
            continue;
          end
        else
          begin
            arr_add(val);
          end;
        //else if (val = 13) or (val = 10) then
        if DelimiterReceive(val) then
          begin
            ss.Clear;
            ss.WriteData(arr, arr_count);
            arr_count := 0;

            str := ss.DataString;
            str := Trim(str);
            //str := buff;
            ReceivedLine(str, arr_count); // 1行の処理を呼び出す
            SetLength(arr, 256);
            if Assigned(FGetStrEvent) then
              FGetStrEvent(Self, str);
            //DelimiterFlagClear;
          end
      end;
  finally
    FreeMemory(read_buf);
  end;
end;

procedure TTscComPort.ReceivedLine(line: string; tm: TDateTime);
var
  str: string;
begin
  memo(line);
  if Assigned(Log) then
    Log.WriteLine('[Recv] ' +line);

  inc(rec_count);
  if (rec_count >= 2) or (not LocalEchoCancel) then
  begin
    rec_count := 0;
    if SendLines.Count > 0 then
    begin
      str := SendLinesDeque;
      SendLine(str);
    end;
  end;
end;

procedure TTscComPort.ReceivedLine(line: string);
var
  str : pByte;
begin
  ReceivedLine(line, now);
  if Assigned(Com) then
    Com.Read(str, 8);
end;

procedure TTscComPort.arr_add(Value: Byte);
var
  utf_code : string;
begin
  utf_code  := AnsiToUtf8(Char(Value));
  //if (utf_code = '#$D') or (utf_code = '#$A') then
  //if (Value = 13) or (Value = 10) then
  //  sleep(1);

  arr[arr_count] := Value;
  //arr[arr_count]  := utf_code;
  inc(arr_count);
  //buff  := buff + Char(Value);
  buff  := buff + utf_code;

  {
  if Pos(DelimiterStr, buff) > 0 then
    begin
      //Form1.Memo1.Lines.Add(buff);
      //CommPort.Close;
      Com.OnComReceive  := nil;
      if @FGetStrEvent <> nil then
        FGetStrEvent(Self, StringReplace(buff,DelimiterStr,'',[rfReplaceAll]));

      if Com <> nil then
        Com.OnComReceive  := Com1ComReceive;
      buff  := '';
    end;
  }

  if arr_count >= Length(arr) then
    arr_count := 0;
end;

procedure TTscComPort.memo(str: String);
begin
  if MemoStrings <> nil then
  begin
    MemoStrings.Add(str);
  end;
end;

function TTscComPort.SendLinesDeque: string;
begin
  if SendLines.Count <= 0 then
  begin
    Result := '';
    Exit;
  end;

  Result := SendLines.Strings[0];
  SendLines.Delete(0);;
end;

procedure TTscComPort.SendLine(line: string);
var
  ss: TStringStream;
begin
  if line = '' then
    Exit;

  // LocalEchoしている場合は、受信でログに保存する。
  if not LocalEchoCancel then
  begin
    memo(line);
    Log.WriteLine('[Send] ' + line);
  end;

  case FDelimiter of
    DL_CR:
      line := line + AnsiChar(#13);
    DL_LF:
      line := line + AnsiChar(#10);
    DL_CRLF:
      line := line + AnsiChar(#13) + AnsiChar(#10);
    DL_CRLF_ONE_SIDE:
      line := line + AnsiChar(#13) + AnsiChar(#10);
  end;

  ss := TStringStream.Create(line, TEncoding.ANSI);
  try
    Com.Write(ss.Memory, ss.Size);
    rec_count := 0;
  finally
    ss.Free;
  end;
end;

function TTscComPort.GetComOpened:Boolean;
begin
  if Com <> nil then
    Result  := True
  else
    Result  := False;
end;

function TTscComPort.DelimiterReceive(val:Byte):Boolean;
begin
  Result  := False;
  if val = 13 then
    delimiter_rcv[Ord(DL_CR)] := True
  else if val = 10 then
    delimiter_rcv[Ord(DL_LF)] := True;

  case FDelimiter of
    DL_CR :
      if delimiter_rcv[Ord(DL_CR)] then Result  := True;
    DL_LF :
      if delimiter_rcv[Ord(DL_LF)] then Result  := True;
    DL_CRLF :
      if Delimiter_rcv[Ord(DL_CR)] and delimiter_rcv[Ord(DL_LF)] then
        Result  := True;
    DL_CRLF_ONE_SIDE :
      if Delimiter_rcv[Ord(DL_CR)] or delimiter_rcv[Ord(DL_LF)] then
        Result  := True;
    else
      Result  := False;
  end;
  if Result then
    DelimiterFlagClear;
end;

procedure TTscComPort.DelimiterFlagClear;
begin
  delimiter_rcv[1]  := False;
  delimiter_rcv[2]  := False;
end;

procedure TTscComPort.SetDataBits(const Value: TTseDataBits);
begin
  FDataBits     := Value;
  Com.DataBits  := Value;
end;

procedure TTscComPort.SetParityBits(const Value: TTseParityBits);
begin
  FParityBits   := Value;
  Com.ParityBits:= Value;
end;

procedure TTscComPort.SetStopBits(const Value: TTseStopBits);
begin
  FStopBits     := Value;
  Com.StopBits  := Value;
end;

procedure TTscComPort.SetBaudRate(const Value: UInt32);
begin
  FBaudRate     := Value;
  Com.BaudRateUserDefined := Value;
end;

function TTscComPort.GetPortName:string;
begin
  Result  := Com.Port;
end;

end.
