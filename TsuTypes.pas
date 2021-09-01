unit TsuTypes;

interface
uses
  System.Generics.Collections, TsuUtils
  ;

type
  TTsdArrayOfUInt64 = array of UInt64;
  TTseFileSeparation  = ( FILE_SP_NONE,
                          FILE_SP_LENGTH,
                          FILE_SP_CHANGE_HOUR,
                          FILE_SP_CHANGE_DAY,
                          FILE_SP_CHANGE_WEEK);
  TTseDirSeparation   = ( DIR_SP_NONE,
                          DIR_SP_FILE_NUM,
                          DIR_SP_PERIOD);
  TTseDirSeparationPeriod = ( DIR_SP_PD_YEAR,
                              DIR_SP_PD_MONTH,
                              DIR_SP_PD_DAY);
  TTseTimeFormatEnum  = ( TF_YEAR, TF_MONTH,  TF_DAY,
                          TF_BLANK,
                          TF_HOUR, TF_MINUTE, TF_SECOND);
  TTseTimeDelimiter   = ( TD_NONE,  TD_SLASH,   TD_CORON, TD_UNDERBAR, TD_SPACE,
                          TD_ALP,   TD_JP);
  TTseWeek            = ( SUN,  MON,  TUE,  WED,  THU,  FRI, SAT);
  TTssTimeFormats = set of TTseTimeFormatEnum;
  TTsrTimeFormat  = record
    private
      function GetDelimiter(dlmt:TTseTimeDelimiter; time:TTseTimeFormatEnum=TF_BLANK):string;
    public
    DateDelimiter   : TTseTimeDelimiter;
    TimeDelimiter   : TTseTimeDelimiter;
    DateBetweenTime : TTseTimeDelimiter;
    Formats         : TTssTimeFormats;
    function ToString:string;
  end;
  TTssDirSeparationPeriod = set of TTseDirSeparationPeriod;
  TTsdDirSeparationPeriodList = TList<TTssDirSeparationPeriod>;
  TTscDirSeparation = class(TObject)
    private
      FPattarn    : TTseDirSeparation;
      FFileNum    : Integer;
      FPeriodType : TTsdDirSeparationPeriodList;
    public
      constructor Create;
      destructor Destroy;
      property Pattarn    : TTseDirSeparation read FPattarn write FPattarn;
      property FileNum    : Integer read FFileNum write FFileNum;
      property PeriodType : TTsdDirSeparationPeriodList read FPeriodType write FPeriodType;
  end;

implementation

constructor TTscDirSeparation.Create;
begin
  FPeriodType := TTsdDirSeparationPeriodList.Create;
end;

destructor TTscDirSeparation.Destroy;
begin
  FPeriodType.Free;
end;

function TTsrTimeFormat.GetDelimiter(dlmt:TTseTimeDelimiter; time:TTseTimeFormatEnum=TF_BLANK):string;
begin
  case dlmt of
    TD_NONE     : Result  := '';
    TD_SLASH    : Result  := '/';
    TD_CORON    : Result  := ':';
    TD_UNDERBAR : Result  := '_';
    TD_SPACE    : Result  := ' ';
    TD_ALP      :
      begin
        case time of
          TF_YEAR   : Result  := 'Y';
          TF_MONTH  : Result  := 'M';
          TF_DAY    : Result  := 'D';
          TF_BLANK  : Result  := '';
          TF_HOUR   : Result  := 'h';
          TF_MINUTE : Result  := 'm';
          TF_SECOND : Result  := 's';
        end;
      end;
    TD_JP       :
      begin
        case time of
          TF_YEAR   : Result  := '年';
          TF_MONTH  : Result  := '月';
          TF_DAY    : Result  := '日';
          TF_BLANK  : Result  := '';
          TF_HOUR   : Result  := '時';
          TF_MINUTE : Result  := '分';
          TF_SECOND : Result  := '秒';
        end;
      end;
  end;
end;

function TTsrTimeFormat.ToString:string;
var
  typ : TTseTimeFormatEnum;
  fmt_str : string;
begin
  TspVarInitString([@fmt_str]);
  for typ in Formats do
    begin
      case typ of
        TF_YEAR   : fmt_str := fmt_str+'yyyy'+GetDelimiter(DateDelimiter, typ);
        TF_MONTH  : fmt_str := fmt_str+'MM'+GetDelimiter(DateDelimiter, typ);
        TF_DAY    :
          begin
            fmt_str := fmt_str+'dd';
            if DateDelimiter = TD_JP then fmt_str := fmt_str+GetDelimiter(DateDelimiter, typ);
          end;
        TF_BLANK  : fmt_str := fmt_str+GetDelimiter(DateBetweenTime, typ);
        TF_HOUR   : fmt_str := fmt_str+'hh'+GetDelimiter(TimeDelimiter, typ);
        TF_MINUTE : fmt_str := fmt_str+'mm'+GetDelimiter(TimeDelimiter, typ);
        TF_SECOND :
          begin
            fmt_str := fmt_str+'ss';
            if TimeDelimiter = TD_JP then fmt_str := fmt_str+GetDelimiter(TimeDelimiter, typ);
          end;
      end;
    end;
  Result  := fmt_str;
end;

end.
