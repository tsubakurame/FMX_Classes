unit TsuLoggerBase;

interface
uses
  System.SysUtils, System.Generics.Collections, System.DateUtils,
  TsuTypes, TsuPathUtilsFMX, TsuAppData, TsuStrUtils
  ;

type
  TTscLoggerBase  = class(TObject)
    protected
      FSaveDir        : string;
      FNowDir         : string;
      FPath           : string;
      FLogSeparation  : TTseFileSeparation;
      FDirSeparation  : TTscDirSeparation;
      FAppData        : TTscAppData;
      FBeforeFileDate : TDateTime;
      FNowTimeStamp   : string;
      FNowPathTime    : string;
      FAddTimeStamp   : Boolean;
      FFileNameTimeFormat : TTsrTimeFormat;
      FTimeStampFormat    : TTsrTimeFormat;
      procedure CheckNewFile;
      procedure CheckDirectory;
      procedure SetLogSeparation(value:TTseFileSeparation);
    public
      constructor Create( SaveDir:string='';
                          MakerName:string='';
                          AppName:string ='');
      property LogSeparation  : TTseFileSeparation read FLogSeparation write SetLogSeparation;
      property DirSeparation  : TTscDirSeparation read FDirSeparation write FDirSeparation;
      property AddTimeStamp   : Boolean read FAddTimeStamp write FAddTimeStamp;
      property FileNameTimeFormat : TTsrTimeFormat read FFileNameTimeFormat write FFileNameTimeFormat;
      property TimeStampFormat    : TTsrTimeFormat read FTimeStampFormat write FTimeStampFormat;
  end;

implementation

constructor TTscLoggerBase.Create(SaveDir:string='';
                                  MakerName:string='';
                                  AppName:string ='');
begin
  FAppData  := TTscAppData.Create(AppName, MakerName);
  if SaveDir = '' then
    FSaveDir  := FAppData.DefaultSavePath
  else
    FSaveDir  := SaveDir;
  FDirSeparation  := TTscDirSeparation.Create;
end;

procedure TTscLoggerBase.CheckNewFile;
var
  dt    : TDateTime;
  flag  : Boolean;
begin
  dt  := Now;
  flag:= False;
  case FLogSeparation of
    FILE_SP_NONE          : ;
    FILE_SP_LENGTH        : ;
    FILE_SP_CHANGE_HOUR   :
      begin
        if HourOf(FBeforeFileDate) <> HourOf(dt) then flag  := True;
      end;
    FILE_SP_CHANGE_DAY    :
      begin
        if DayOf(FBeforeFileDate) <> DayOf(dt) then flag  := True;
      end;
  end;

  if flag then
    begin
      DateTimeToString(FNowTimeStamp, FTimeStampFormat.ToString, dt);
      DateTimeToString(FNowPathTime, FFileNameTimeFormat.ToString, dt);
      FBeforeFileDate := dt;
    end;
end;

procedure TTscLoggerBase.CheckDirectory;
var
  I: Integer;
  pd  : TTseDirSeparationPeriod;
  dir : string;
  n_dir : string;
  cash: string;
  dt  : TDateTime;
begin
  dt    := Now;
  n_dir := FSaveDir;
  case FDirSeparation.Pattarn of
    DIR_SP_FILE_NUM :
      begin
      end;
    DIR_SP_PERIOD   :
      begin
        for I := 0 to FDirSeparation.PeriodType.Count -1 do
          begin
            dir := '';
            for pd in FDirSeparation.PeriodType.Items[I] do
              begin
                case pd of
                  DIR_SP_PD_YEAR  :
                    begin
                      DateTimeToString(cash, 'yyyy', dt);
                      dir := dir + cash;
                    end;
                  DIR_SP_PD_MONTH :
                    begin
                      DateTimeToString(cash, 'MM', dt);
                      dir := dir + cash;
                    end;
                  DIR_SP_PD_DAY   :
                    begin
                      DateTimeToString(cash, 'dd', dt);
                      dir := dir + cash;
                    end;
                end;
              end;
            n_dir := IncludeTrailingPathDelimiter(n_dir) + dir;
            TspDirectoryExistsForce(n_dir);
          end;
        FNowDir := n_dir;
      end;
  end;
end;

procedure TTscLoggerBase.SetLogSeparation(value:TTseFileSeparation);
begin
  FLogSeparation  := value;
end;

end.
