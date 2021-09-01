unit TsuTYPE6238;
//  ACO TYPE6238 騒音計
interface
uses
  System.SysUtils, System.Classes, System.RegularExpressions,
  TsuComPort, TsuACONoiseMeterBase, TsuStrUtils, TsuAppData,
  TsuACOTypes
  ;

type
  TTscTYPE6238  = class(TTscACONoiseMeterBase)
    private
      procedure SetAppDataPath;override;
      procedure ReceivedCommand(str:string);override;
      procedure MeasSettings;overload;
    protected
      FSettings   : TTsrTYPE6238Settings;
      FOnMeasStop : TNotifyEvent;
      FReceivData : TTsrTYPE6238Data;
      FIVData     : TTsrTYPE6238IV;
      procedure GetEQData;virtual;abstract;
      procedure GetIVData;virtual;abstract;
    public
      procedure BackLight;
      procedure GetInstantaneousValue;
      procedure MeasSettings(params:TTsrTYPE6238Settings);overload;
      procedure GetSettings;
      procedure GetVersion;
      procedure GetWaveOut;
      procedure SetRange(range:TTseTYPE6238Range);
      procedure SetFreqChar(freq_char:TTseTYPE6238FreqChar);
      procedure StartLAtm5;
      procedure StartLAleq;
      procedure SetFilter(filter:TTseTYPE6238Filter);
      procedure OutputLB;
      procedure SetFreqSpan(freq_span:TTseTYPE6238FreqSpan);
      procedure SetFFTMeasTime(time:Byte);
      procedure SetWindowFunc(window:TTseTYPE6238WinFunc);
      procedure SetFFTMode(mode:TTseTYPE6238FFTMode);
      procedure GetFFTInstantaneousValue;
      property Settings       : TTsrTYPE6238Settings read FSettings write MeasSettings;
      property OnMeasStop     : TNotifyEvent read FOnMeasStop write FOnMeasStop;
  end;

implementation

procedure TTscTYPE6238.SetAppDataPath;
begin
  FAppData      := TTscAppData.Create('TYPE6238_Com', 'ACO');
  app_data_path := FAppData.AppDataPath;
end;

procedure TTscTYPE6238.BackLight;
begin
  Send('L');
end;

procedure TTscTYPE6238.GetInstantaneousValue;
begin
  if FCom.Opend then FCom.SendLine('P');
end;

procedure TTscTYPE6238.MeasSettings(params:TTsrTYPE6238Settings);
begin
  FSettings := params;
  MeasSettings;
end;

procedure TTscTYPE6238.MeasSettings;
var
  cmd : string;
begin
  cmd := 'F'  + IntToHex(Ord(FSettings.MeasTime),1)
              + IntToStr(Ord(FSettings.Range))
              + IntToStr(Ord(FSettings.FreqChar))
              + IntToStr(Ord(FSettings.TimeChar))
              + IntToStr(Ord(FSettings.Interval));
  if FCom.Opend then FCom.SendLine(cmd);
end;

procedure TTscTYPE6238.GetSettings;
begin
  if FCom.Opend then FCom.SendLine('I');
end;

procedure TTscTYPE6238.GetVersion;
begin
  if FCom.Opend then FCom.SendLine('V');
end;

procedure TTscTYPE6238.GetWaveOut;
begin
  if FCom.Opend then FCom.SendLine('W');
end;

procedure TTscTYPE6238.SetRange(range:TTseTYPE6238Range);
begin
  FSettings.Range  := range;
  if FCom.Opend then FCom.SendLine('R'+IntToStr(Ord(range)));
end;

procedure TTscTYPE6238.SetFreqChar(freq_char:TTseTYPE6238FreqChar);
begin
  FSettings.FreqChar := freq_char;
  if FCom.Opend then FCom.SendLine('A'+IntToStr(Ord(freq_char)));
end;

procedure TTscTYPE6238.StartLAtm5;
begin
  Send('M');
end;

procedure TTscTYPE6238.StartLAleq;
begin
  Send('Q');
end;

procedure TTscTYPE6238.SetFilter(filter:TTseTYPE6238Filter);
begin
  Send('O'+IntToStr(Ord(filter)));
end;

procedure TTscTYPE6238.OutputLB;
begin
  Send('B');
end;

procedure TTscTYPE6238.SetFreqSpan(freq_span:TTseTYPE6238FreqSpan);
begin
  Send('G'+IntToStr(Ord(freq_span)));
end;

procedure TTscTYPE6238.SetFFTMeasTime(time:Byte);
begin
  Send('H'+TsfIntToStrAddZero(time,3));
end;

procedure TTscTYPE6238.SetWindowFunc(window:TTseTYPE6238WinFunc);
begin
  Send('J'+IntToStr(Ord(window)));
end;

procedure TTscTYPE6238.SetFFTMode(mode:TTseTYPE6238FFTMode);
begin
  Send('K'+IntToStr(Ord(mode)));
end;

procedure TTscTYPE6238.GetFFTInstantaneousValue;
begin
  Send('N');
end;

procedure TTscTYPE6238.ReceivedCommand(str:string);
var
  matches : TMatchCollection;
  FmtStngs: TFormatSettings;
  iv_data : TTsrTYPE6238IV;
begin
  if TRegEx.IsMatch(str, 'i[0-9|A-D]{5}') then
    {$region'    Read Settings    '}
    begin
      matches   := TRegEx.Matches(str, '[0-9|A-D]');
      FSettings.MeasTime  := TTseTYPE6238MeasTime(TsfHexToInt(matches.Item[0].Value));
      FSettings.Range     := TTseTYPE6238Range(StrToInt(matches.Item[1].Value));
      FSettings.FreqChar  := TTseTYPE6238FreqChar(StrToInt(matches.Item[2].Value));
      FSettings.TimeChar  := TTseTYPE6238TimeChar(StrToInt(matches.Item[3].Value));
      FSettings.Interval  := TTseTYPE6238Interval(StrToInt(matches.Item[4].Value));
    end{$endregion}
  else if TRegEx.IsMatch(str, '[0-9]{3}h[0-9]{2}m[0-9]{2}s') then
    {$region'    Read MeasTime    '}
    begin
      matches := TRegEx.Matches(str, '\d+');
      FReceivData.MeasTime.Hour   := matches.Item[0].Value;
      FReceivData.MeasTime.Minute := matches.Item[1].Value;
      FReceivData.MeasTime.Second := matches.Item[2].Value;
    end{$endregion}
  else if TRegEx.IsMatch(str, '[0-9]{2}\/[0-9]{2}\/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}') then
    {$region'    Read Data of Date   '}
    begin
      matches := TRegEx.Matches(str, '[0-9]{2}\/[0-9]{2}\/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}');
      FReceivData.Date  := '20'+matches.Item[0].Value;
    end{$endregion}
  else if TRegEx.IsMatch(str, 'LA[0-9]{2}') then
    {$region'    Read EqDatas    '}
    begin
      matches   := TRegEx.Matches(str, '(\d+\.\d+)');
      if      TRegEx.IsMatch(str, 'LA05') then
        begin
          FReceivData.Leq   := matches.Item[0].Value;
          FReceivData.LA05  := matches.Item[1].Value;
        end
      else if TRegEx.IsMatch(str, 'LA10') then
        begin
          FReceivData.Le    := matches.Item[0].Value;
          FReceivData.LA10  := matches.Item[1].Value;
        end
      else if TRegEx.IsMatch(str, 'LA50') then
        begin
          if matches.Count = 1 then
            begin
              FReceivData.Lpeak := '';
              FReceivData.LA50  := matches.Item[0].Value;
            end
          else
            begin
              FReceivData.Lpeak := matches.Item[0].Value;
              FReceivData.LA50  := matches.Item[1].Value;
            end;
        end
      else if TRegEx.IsMatch(str, 'LA90') then
        begin
          FReceivData.Lmin  := matches.Item[0].Value;
          FReceivData.LA90  := matches.Item[1].Value;
        end
      else if TRegEx.IsMatch(str, 'LA95') then
        begin
          FReceivData.Lmax  := matches.Item[0].Value;
          FReceivData.LA95  := matches.Item[1].Value;
          GetEQData;
          if Assigned(FOnGetData) then
            FOnGetData(Self, @FReceivData);
        end;
    end{$endregion}
  else if TRegEx.IsMatch(str, '(\d+\.\d+)') then
    {$region'    Read IV    '}
    begin
      matches := TRegEx.Matches(str, '(\d+\.\d+)');
      FIVData.ValueS  := matches.item[0].Value;
      FIVData.ValueD  := StrToFloat(FIVData.ValueS);
      GetIVData;
      if Assigned(FOnGetIV) then FOnGetIV(Self, @FIVData);
    end;{$endregion}
end;

end.
