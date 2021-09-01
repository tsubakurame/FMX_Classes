unit TsuCSVAppend;

interface
uses
  System.IOUtils, System.SysUtils, System.DateUtils, System.Classes,
  TsuLoggerBase
  ;

type
  TTscCSVAppend = class(TTscLoggerBase)
    protected
      FNowData    : string;
      FHeaderList : TStringList;
      FHeaderData : string;
      procedure HeaderWrite;
    public
      procedure AddData(str:string);
      procedure AddLine;overload;
      procedure AddLine(str:string);overload;
      procedure HeaderAdd(str:string);
      procedure HeaderAddLine;overload;
      procedure HeaderAddLine(str:string);overload;
      procedure HeaderClear;

      property NowData  : string read FNowData write FNowData;
      property Path     : string read FPath write FPath;
      property SaveDit  : string read FSaveDir;
  end;

implementation

procedure TTscCSVAppend.AddData(str: string);
var
  dt  : TDateTime;
begin
  if FNowData = '' then
    begin
      if FAddTimeStamp then
        begin
          dt  := Now;
          DateTimeToString(FNowData, 'yyyy/MM/dd HH:mm:ss', dt);
          FNowData  := FNowData + ',' + str;
        end
      else
        FNowData  := str;
    end
  else
    FNowData  := FNowData + ',' + str;
end;

procedure TTscCSVAppend.AddLine;
var
  path  : string;
begin
  CheckDirectory;
  CheckNewFile;
  path  := IncludeTrailingPathDelimiter(FNowDir)+FNowPathTime+'_'+FPath;
  if not FileExists(path) then HeaderWrite;
  TFile.AppendAllText(path , FNowData + #13#10);
  //FPath := '';
  FNowData  := '';
end;

procedure TTscCSVAppend.AddLine(str: string);
begin
  AddData(str);
  AddLine;
end;

procedure TTscCSVAppend.HeaderAdd(str: string);
begin
  if FHeaderData = '' then FHeaderData  := str
  else FHeaderData  := FHeaderData +','+ str;
end;

procedure TTscCSVAppend.HeaderAddLine;
begin
  if FHeaderList = nil then
    FHeaderList := TStringList.Create;
  FHeaderList.Add(FHeaderData);
end;

procedure TTscCSVAppend.HeaderAddLine(str:string);
begin
  HeaderAdd(str);
  HeaderAddLine;
end;

procedure TTscCSVAppend.HeaderWrite;
var
  path  : string;
  I     : Integer;
begin
  path  := IncludeTrailingPathDelimiter(FNowDir)+FNowPathTime+'_'+FPath;
  if FHeaderList <> nil then
    for I := 0 to FHeaderList.Count -1 do
      TFile.AppendAllText(path, FHeaderList[I]+#13#10);
end;

procedure TTscCSVAppend.HeaderClear;
begin
  if FHeaderList <> nil then
    FHeaderList.Clear;
  FHeaderData := '';
end;

end.
