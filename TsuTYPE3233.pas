unit TsuTYPE3233;
//  ACO TYPE3233 振動計
interface
uses
  System.SysUtils, System.RegularExpressions,
  TsuComPort, TsuACONoiseMeterBase, TsuStrUtils, TsuACOTypes, TsuAppData,
  TsuTypes
  ;

type



  TTscTYPE3233  = class(TTscACONoiseMeterBase)
    private
      procedure ReceivedCommand(str:string);override;
      procedure SetAppDataPath;override;
    protected
      FSettings : TTsrTYPE3233Settings;
      FReceivData : TTsrTYPE3233Data;
      FIVData   : TTsrTYPE3233IV;
      procedure GetEQData;virtual;abstract;
      procedure GetIVData;virtual;abstract;
    public
      procedure MeasSettings;overload;
      procedure MeasSettings(params:TTsrTYPE3233Settings);overload;
      procedure SetRange(ch:TTseTYPE3233Ch; range:TTseTYPE3233Range);
      procedure SetFilter(ch:TTseTYPE3233Ch; filter:TTseTYPE3233Filter);
      procedure GetSettings;overload;
      procedure GetSettings(ch:TTseTYPE3233Ch);overload;
      procedure BackLight(enable:Boolean);
      procedure GetInstantaneousValue;overload;
      procedure GetInstantaneousValue(ch:TTseTYPE3233Ch);overload;
      procedure GetData;overload;override;
      procedure GetData(ch:TTseTYPE3233Ch);overload;
  end;


implementation

procedure TTscTYPE3233.MeasSettings;
var
  cmd : string;
  I: Integer;
begin
  with FSettings do
    begin
      cmd := 'F0' + IntToHex(Ord(MeasTime),1) +
                    IntToStr(Ord(Range[T3233_CH_X])) +
                    IntToStr(Ord(Filter[T3233_CH_X])) +
                    IntToStr(Ord(Interval));
      if FCom.Opend then FCom.SendLine(cmd);
      for I := 2 to 3 do
        begin
          if Range[T3233_CH_X] <> Range[TTseTYPE3233Ch(I)] then
            SetRange(TTseTYPE3233Ch(I), Range[TTseTYPE3233Ch(I)]);
          if Filter[T3233_CH_X] <> Filter[TTseTYPE3233Ch(I)] then
            SetFilter(TTseTYPE3233Ch(I), Filter[TTseTYPE3233Ch(I)]);
        end;
    end;
end;

procedure TTscTYPE3233.SetRange(ch:TTseTYPE3233Ch; range:TTseTYPE3233Range);
var
  cmd : string;
begin
  cmd := 'R'  + IntToStr(Ord(ch))
              + IntToStr(Ord(range));
  if FCom.Opend then FCom.SendLine(cmd);
end;

procedure TTscTYPE3233.SetFilter(ch:TTseTYPE3233Ch; filter:TTseTYPE3233Filter);
var
  cmd : string;
begin
  cmd := 'A'  + IntToStr(Ord(ch))
              + IntToStr(Ord(filter));
  if FCom.Opend then FCom.SendLine(cmd);
end;

procedure TTscTYPE3233.MeasSettings(params:TTsrTYPE3233Settings);
begin
  FSettings := params;
  MeasSettings;
end;

procedure TTscTYPE3233.SetAppDataPath;
begin
  FAppData      := TTscAppData.Create('TYPE3233_Com', 'ACO');
  app_data_path := FAppData.AppDataPath;
end;

procedure TTscTYPE3233.BackLight(enable:Boolean);
var
  cmd : string;
begin
  if FCom.opend then
    begin
      if enable then  cmd := 'L1'
      else            cmd := 'L0';
      FCom.SendLine(cmd);
    end;
end;

procedure TTscTYPE3233.GetInstantaneousValue;
begin
  GetInstantaneousValue(T3233_CH_ALL);
end;

procedure TTscTYPE3233.GetInstantaneousValue(ch:TTseTYPE3233Ch);
begin
  if FCom.Opend then FCom.SendLine('P'+IntToStr(Ord(ch)));
end;

procedure TTscTYPE3233.GetSettings;
begin
  GetSettings(T3233_CH_ALL);
end;

procedure TTscTYPE3233.GetSettings(ch:TTseTYPE3233Ch);
begin
  if FCom.Opend then FCom.SendLine('F'+IntToStr(Ord(ch)));
end;

procedure TTscTYPE3233.ReceivedCommand(str:string);
var
  matches : TMatchCollection;
  matches_ch  : TMatchCollection;
  ch      : Integer;
  I: Integer;
  //iv_data : TTsrTYPE3233IV;
begin
  if TRegEx.IsMatch(str, 'f[0-9|A-C]{5}') then
    {$region'    Read Settings    '}
    begin
      matches := TRegEx.Matches(str, '[0-9|A-C]{5}');
      for I := 0 to matches.Count -1 do
        begin
          matches_ch          := TRegEx.Matches(matches.Item[I].Value, '[0-9|A-C]');
          ch                  := StrToInt(matches_ch.Item[0].Value);
          FSettings.MeasTime  := TTseTYPE3233MeasTime(TsfHexToInt(matches_ch.Item[1].Value));
          FSettings.Range[TTseTYPE3233Ch(ch)] := TTseTYPE3233Range(StrToInt(matches_ch.Item[2].Value));
          FSettings.Filter[TTseTYPE3233Ch(ch)]:= TTseTYPE3233Filter(StrToInt(matches_ch.Item[3].Value));
          FSettings.Interval  := TTseTYPE3233Interval(StrToInt(matches_ch.Item[4].Value));
        end;
    end{$endregion}
  else if TRegEx.IsMatch(str, '[X-Z]\d+\.\d+') then
    {$region'    Read IV    '}
    begin
      matches := TRegEx.Matches(str, '([X-Z]|\d+\.\d+)');
      if matches.Item[0].Value = 'X' then       FIVData.Ch  := T3233_CH_X
      else if matches.Item[0].Value = 'Y' then  FIVData.Ch  := T3233_CH_Y
      else if matches.Item[0].Value = 'Z' then  FIVData.Ch  := T3233_CH_Z;
      FIVData.Data.ValueS := matches.Item[1].Value;
      FIVData.Data.ValueD := StrToFloat(FIVData.Data.ValueS);
      if Assigned(FOnGetIV) then FOnGetIV(self, @FIVData);
      GetIVData;
    end{$endregion}
  else if TRegEx.IsMatch(str, '[0-9]{2}\/[0-9]{2}\/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}') then
    {$region'    Read Data of Date   '}
    begin
      matches := TRegEx.Matches(str, '[0-9]{2}\/[0-9]{2}\/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}');
      FReceivData.Date  := '20'+matches.Item[0].Value;

      matches := TRegEx.Matches(str, '[X-Z]');
      if matches.Item[0].Value = 'X' then
        FReceivData.Ch  := T3233_CH_X
      else if matches.Item[0].Value = 'Y' then
        FReceivData.Ch  := T3233_CH_Y
      else if matches.Item[0].Value = 'Z' then
        FReceivData.Ch  := T3233_CH_Z;

      matches := TRegEx.Matches(str, '\d+dB');
      if matches.Item[0].Value = '110dB' then
        FReceivData.Range := T3233_RG_110DB
      else if matches.Item[0].Value = '90dB' then
        FReceivData.Range := T3233_RG_90DB;

      FReceivData.Filter  := FSettings.Filter[FReceivData.Ch];
    end{$endregion}
  else if TRegEx.IsMatch(str, '[0-9]{3}h[0-9]{2}m[0-9]{2}s') then
    {$region'    Read MeasTime    '}
    begin
      matches := TRegEx.Matches(str, '\d+');
      FReceivData.MeasTime.Hour   := matches.Item[0].Value;
      FReceivData.MeasTime.Minute := matches.Item[1].Value;
      FReceivData.MeasTime.Second := matches.Item[2].Value;
    end{$endregion}
  else if TRegEx.IsMatch(str, 'L(v|a)[0-9]{2}') then
    begin
      matches := TRegEx.Matches(str, '\d+\.\d+');
      if      TRegEx.IsMatch(str, 'L(a|v)05') then
        begin
          FReceivData.Leq := matches.Item[0].Value;
          FReceivData.L05 := matches.Item[1].Value;
        end
      else if TRegEx.IsMatch(str, 'L(a|v)10') then
        begin
          FReceivData.L10 := matches.Item[0].Value;
        end
      else if TRegEx.IsMatch(str, 'L(a|v)50') then
        begin
          FReceivData.L50 := matches.Item[0].Value;
        end
      else if TRegEx.IsMatch(str, 'L(a|v)90') then
        begin
          FReceivData.Lmin:= matches.Item[0].Value;
          FReceivData.L90 := matches.Item[1].Value;
        end
      else if TRegEx.IsMatch(str, 'L(a|v)95') then
        begin
          FReceivData.Lmax:= matches.Item[0].Value;
          FReceivData.L95 := matches.Item[1].Value;
          GetEQData;
          if Assigned(FOnGetData) then
            FOnGetData(Self, @FReceivData);
        end;
    end;
end;

procedure TTscTYPE3233.GetData;
begin
  GetData(T3233_CH_ALL);
end;

procedure TTscTYPE3233.GetData(ch:TTseTYPE3233Ch);
var
  cmd : string;
begin
  cmd := 'D'+IntToStr(Ord(ch));
  if FCom.Opend then FCom.SendLine(cmd);
  
end;

end.
