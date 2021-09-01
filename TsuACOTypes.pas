unit TsuACOTypes;

interface

type
  TTseMeterState  = (STT_IDLE, STT_MEAS);
  TTseTYPE3233Ch  = (T3233_CH_ALL,  T3233_CH_X, T3233_CH_Y, T3233_CH_Z);
  TTseTYPE3233MeasTime  = ( T3233_MT_NONE,  T3233_MT_1S,  T3233_MT_3S,
                            T3233_MT_5S,    T3233_MT_10S, T3233_MT_1M,
                            T3233_MT_5M,    T3233_MT_10M, T3233_MT_15M,
                            T3233_MT_30M,   T3233_MT_1H,  T3233_MT_8H,
                            T3233_MT_24H);
  TTseTYPE3233Range = ( T3233_RG_ERROR  = -1,
                        T3233_RG_110DB  = 2,
                        T3233_RG_90DB   = 4);
  TTseTYPE3233Filter  = ( T3233_FT_ERROR = -1,
                          T3233_FT_Lv,
                          T3233_FT_Lva);
  TTseTYPE3233CSVTypeEQ = ( T3233_CT_EQ_Date,   T3233_CT_EQ_RANGE,  T3233_CT_EQ_FILTER,
                            T3233_CT_EQ_MEASTIME,
                            T3233_CT_EQ_Leq,    T3233_CT_EQ_LMIN,   T3233_CT_EQ_LMAX,
                            T3233_CT_EQ_L05,    T3233_CT_EQ_L10,    T3233_CT_EQ_L50,
                            T3233_CT_EQ_L90,    T3233_CT_EQ_L95);
  TTseTYPE3233CSVTypeIV = ( T3233_CT_IV_Date,   T3233_CT_IV_RANGE,  T3233_CT_IV_FILTER,
                            T3233_CT_IV_X,      T3233_CT_IV_Y,      T3233_CT_IV_Z);
  TTseTYPE3233Interval  = (T3233_IT_SINGLE, T3233_IT_REPEAT);
  TTseTYPE6238MeasTime  = ( T6238_MT_NONE,T6238_MT_1S,  T6238_MT_3S,
                            T6238_MT_5S,  T6238_MT_10S, T6238_MT_1M,
                            T6238_MT_5M,  T6238_MT_10M, T6238_MT_15M,
                            T6238_MT_30M, T6238_MT_1H,  T6238_MT_8H,
                            T6238_MT_12H, T6238_MT_24H);
  TTseTYPE6238Range     = ( T6238_RG_130DB, T6238_RG_120DB, T6238_RG_110DB,
                            T6238_RG_100DB, T6238_RG_90DB,  T6238_RG_80DB);
  TTseTYPE6238FreqChar  = ( T6238_FC_A, T6238_FC_C, T6238_FC_Z);
  TTseTYPE6238TimeChar  = ( T6238_TC_FAST,  T6238_TC_SLOW,  T6238_TC_IMP);
  TTseTYPE6238Interval  = ( T6238_IT_SINGLE,  T6238_IT_REPEAT);
  TTseTYPE6238Filter    = ( T6238_FT_1_1, T6238_FT_1_3);
  TTseTYPE6238FreqSpan  = ( T6238_FS_20K, T6238_FS_10K, T6238_FS_5K,  T6238_FS_2K);
  TTseTYPE6238WinFunc   = ( T6238_WF_HANNING, T6238_WF_RECT);
  TTseTYPE6238FFTMode   = ( T6238_FM_LIN, T6238_FM_MAX);
  TTseTYPE6238CSVTypeIV = ( T6238_CT_IV_DATE, T6238_CT_IV_RANGE,
                            T6238_CT_IV_FREQCHAR, T6238_CT_IV_TIMECHAR,
                            T6238_CT_IV_IV);
  TTseTYPE6238CSVTypeEQ = ( T6238_CT_EQ_DATE, T6238_CT_EQ_RANGE,
                            T6238_CT_EQ_FREQCHAR, T6238_CT_EQ_TIMECHAR,
                            T6238_CT_EQ_MEASTIME,
                            T6238_CT_EQ_Leq,  T6238_CT_EQ_Le, T6238_CT_EQ_Lpeak,
                            T6238_CT_EQ_Lmin, T6238_CT_EQ_Lmax,
                            T6238_CT_EQ_L05,  T6238_CT_EQ_L10,  T6238_CT_EQ_L50,
                            T6238_CT_EQ_L90,  T6238_CT_EQ_L95);

  TTssTYPE3233CSVTypesEQ= set of TTseTYPE3233CSVTypeEQ;
  TTssTYPE3233CSVTypesIV= set of TTseTYPE3233CSVTypeIV;
  TTssTYPE6238CSVTypesEQ= set of TTseTYPE6238CSVTypeEQ;
  TTssTYPE6238CSVTypesIV= set of TTseTYPE6238CSVTypeIV;

  TTsdACOMeterGetDataEvent  = procedure(Sender:TObject; data:Pointer) of object;
  TTsdTYPE3233RangeChs  = Array[1..3] of TTseTYPE3233Range;
  TTsdTYPE3233FilterChs = Array[1..3] of TTseTYPE3233Filter;

  TTsrACOMeterIV  = record
    ValueS  : string;
    ValueD  : Double;
  end;
  TTsrTYPE3233MeasTime  = record
    Hour, Minute, Second  : string;
    function ToString:string;
  end;
  TTsrTYPE3233Data      = record
    Ch    : TTseTYPE3233Ch;
    Range : TTseTYPE3233Range;
    Filter: TTseTYPE3233Filter;
    Date  : string;
    MeasTime  : TTsrTYPE3233MeasTime;
    L05, L10, L50, L90, L95 : string;
    Lmin, Lmax              : string;
    Leq                     : string;
  end;
  TTsrTYPE3233Settings  = record
    private
      FMeasTime : TTseTYPE3233MeasTime;
      FRange    : TTsdTYPE3233RangeChs;
      FFilter   : TTsdTYPE3233FilterChs;
      FInterval : TTseTYPE3233Interval;
      function GetRange(ch:TTseTYPE3233Ch):TTseTYPE3233Range;
      procedure SetRange(ch:TTseTYPE3233Ch; value:TTseTYPE3233Range);
      function GetFilter(ch:TTseTYPE3233Ch):TTseTYPE3233Filter;
      procedure SetFilter(ch:TTseTYPE3233Ch; value:TTseTYPE3233Filter);
    public
      property MeasTime : TTseTYPE3233MeasTime  read FMeasTime  write FMeasTime;
      property Ranges   : TTsdTYPE3233RangeChs  read FRange     write FRange;
      property Range[ch:TTseTYPE3233Ch] : TTseTYPE3233Range read GetRange write SetRange;
      property Filters  : TTsdTYPE3233FilterChs read FFilter    write FFilter;
      property Filter[ch:TTseTYPE3233Ch]: TTseTYPE3233Filter read GetFilter write SetFilter;
      property Interval : TTseTYPE3233Interval  read FInterval  write FInterval;
  end;
  TTsrTYPE3233IV  = record
    Ch    : TTseTYPE3233Ch;
    Data  : TTsrACOMeterIV;
  end;
  TTsrTYPE6238MeasTime  = record
    Hour, Minute, Second  : string;
    function ToString:string;
  end;
  TTsrTYPE6238Data      = record
    Range     : TTseTYPE6238Range;
    FreqChar  : TTseTYPE6238FreqChar;
    TimeChar  : TTseTYPE6238TimeChar;
    Date      : string;
    MeasTime  : TTsrTYPE6238MeasTime;
    LA05, LA10, LA50, LA90, LA95  : string;
    Lmin, Lmax                    : string;
    Leq,  Le,   Lpeak             : string;
  end;
  TTsrTYPE6238Settings  = record
    private
      FMeasTime : TTseTYPE6238MeasTime;
      FRange    : TTseTYPE6238Range;
      FFreqChar : TTseTYPE6238FreqChar;
      FTimeChar : TTseTYPE6238TimeChar;
      FInterval : TTseTYPE6238Interval;
    public
      property MeasTime : TTseTYPE6238MeasTime  read FMeasTime  write FMeasTime;
      property Range    : TTseTYPE6238Range     read FRange     write FRange;
      property FreqChar : TTseTYPE6238FreqChar  read FFreqChar  write FFreqChar;
      property TimeChar : TTseTYPE6238TimeChar  read FTimeChar  write FTimeChar;
      property Interval : TTseTYPE6238Interval  read FInterval  write FInterval;
  end;
  TTsrTYPE6238IV        = TTsrACOMeterIV;

  function TsfGetTYPE3233RangeEnumName(range:TTseTYPE3233Range):string;
  function TsfGetTYPE3233FilterEnumName(filter:TTseTYPE3233Filter):string;
  function TsfGetTYPE6238RangeEnumName(range:TTseTYPE6238Range):string;
  function TsfGetTYPE6238FreqCharEnumName(freqchar:TTseTYPE6238FreqChar):string;
  function TsfGetTYPE6238TimeCharEnumName(timechar:TTseTYPE6238TimeChar):string;

const
  TYPE3233_EQCSV_ALL_TYPES  = [ T3233_CT_EQ_Date,   T3233_CT_EQ_RANGE,
                                T3233_CT_EQ_FILTER, T3233_CT_EQ_MEASTIME,
                                T3233_CT_EQ_Leq,    T3233_CT_EQ_LMIN,     T3233_CT_EQ_LMAX,
                                T3233_CT_EQ_L05,    T3233_CT_EQ_L10,      T3233_CT_EQ_L50,
                                T3233_CT_EQ_L90,    T3233_CT_EQ_L95];
  TYPE3233_IVCSV_ALL_TYPES  = [ T3233_CT_IV_Date,   T3233_CT_IV_RANGE,    T3233_CT_IV_FILTER,
                                T3233_CT_IV_X,      T3233_CT_IV_Y,        T3233_CT_IV_Z];
  TYPE6238_EQCSV_ALL_TYPES  = [ T6238_CT_EQ_DATE,   T6238_CT_EQ_RANGE,    T6238_CT_EQ_FREQCHAR,
                                T6238_CT_EQ_TIMECHAR, T6238_CT_EQ_MEASTIME,
                                T6238_CT_EQ_Leq,      T6238_CT_EQ_Le,
                                T6238_CT_EQ_Lpeak,    T6238_CT_EQ_Lmin,   T6238_CT_EQ_Lmax,
                                T6238_CT_EQ_L05,      T6238_CT_EQ_L10,    T6238_CT_EQ_L50,
                                T6238_CT_EQ_L90,      T6238_CT_EQ_L95];
  TYPE6238_IVCSV_ALL_TYPES  = [ T6238_CT_IV_DATE,   T6238_CT_IV_RANGE,
                                T6238_CT_IV_FREQCHAR, T6238_CT_IV_TIMECHAR,
                                T6238_CT_IV_IV];

implementation

{$region    '    TTsrTYPE3233Settings    '}
function TTsrTYPE3233Settings.GetRange(ch:TTSeTYPE3233Ch):TTseTYPE3233Range;
begin
  case ch of
    T3233_CH_ALL: Result  := T3233_RG_ERROR;
    T3233_CH_X,
    T3233_CH_Y,
    T3233_CH_Z  : Result  := FRange[Ord(ch)];
  end;
end;

procedure TTsrTYPE3233Settings.SetRange(ch:TTseTYPE3233Ch; value:TTseTYPE3233Range);
var
  I: Integer;
begin
  case ch of
    T3233_CH_ALL:
      begin
        for I := 1 to 3 do
          FRange[I] := value;
      end;
    T3233_CH_X,
    T3233_CH_Y,
    T3233_CH_Z  : FRange[Ord(ch)] := value;
  end;
end;

function TTsrTYPE3233Settings.GetFilter(ch:TTSeTYPE3233Ch):TTseTYPE3233Filter;
begin
  case ch of
    T3233_CH_ALL: Result  := T3233_FT_ERROR;
    T3233_CH_X,
    T3233_CH_Y,
    T3233_CH_Z  : Result  := FFilter[Ord(ch)];
  end;
end;

procedure TTsrTYPE3233Settings.SetFilter(ch:TTseTYPE3233Ch; value:TTseTYPE3233Filter);
var
  I: Integer;
begin
  case ch of
    T3233_CH_ALL:
      begin
        for I := 1 to 3 do
          FFilter[I] := value;
      end;
    T3233_CH_X,
    T3233_CH_Y,
    T3233_CH_Z  : FFilter[Ord(ch)] := value;
  end;
end;
{$endregion}

function TTsrTYPE3233MeasTime.ToString:string;
begin
  Result  := Hour+'h'+Minute+'m'+Second+'s';
end;

function TTsrTYPE6238MeasTime.ToString:string;
begin
  Result  := Hour+'h'+Minute+'m'+Second+'s';
end;

function TsfGetTYPE3233RangeEnumName(range:TTseTYPE3233Range):string;
begin
  case range of
    T3233_RG_ERROR  : Result  := 'Error';
    T3233_RG_110DB  : Result  := '110dB';
    T3233_RG_90DB   : Result  := '90dB';
  end;
end;

function TsfGetTYPE3233FilterEnumName(filter:TTseTYPE3233Filter):string;
begin
  case filter of
    T3233_FT_ERROR  : Result  := 'Error';
    T3233_FT_Lv     : Result  := 'Lv';
    T3233_FT_Lva    : Result  := 'Lva';
  end;
end;

function TsfGetTYPE6238RangeEnumName(range:TTseTYPE6238Range):string;
begin
  case range of
    T6238_RG_130DB: Result  := '130dB';
    T6238_RG_120DB: Result  := '120dB';
    T6238_RG_110DB: Result  := '110dB';
    T6238_RG_100DB: Result  := '100dB';
    T6238_RG_90DB : Result  := '90dB';
    T6238_RG_80DB : Result  := '80dB';
  end;
end;

function TsfGetTYPE6238FreqCharEnumName(freqchar:TTseTYPE6238FreqChar):string;
begin
  case freqchar of
    T6238_FC_A: Result  := 'A';
    T6238_FC_C: Result  := 'C';
    T6238_FC_Z: Result  := 'Z';
  end;
end;

function TsfGetTYPE6238TimeCharEnumName(timechar:TTseTYPE6238TimeChar):string;
begin
  case timechar of
    T6238_TC_FAST: Result := 'Fast';
    T6238_TC_SLOW: Result := 'Slow';
    T6238_TC_IMP : Result := 'Imp';
  end;
end;

end.
