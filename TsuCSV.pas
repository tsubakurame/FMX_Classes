unit TsuCSV;

interface
uses
  System.Classes, System.SysUtils,
  TsuUtils
  ;

type
  TTscCSV = class(TObject)
    private
      FCSV      : TStringList;
      FNowData  : string;
      procedure ClearData;
    public
      constructor Create;
      destructor Destroy;override;

      procedure NewLine;
      procedure InsertLine(index:Integer);
      procedure AddData(data:string);overload;
      procedure AddData(data:Double);overload;

      procedure AddData(data:Array of string);overload;
      procedure AddData(data:Array of PDouble);overload;

      procedure AddNewLine(data:string);overload;
      procedure AddNewLine(data:Double);overload;

      procedure AddNewLine(data:array of string);overload;
      procedure AddNewLine(data:array of PDouble);overload;

      procedure InsertNewLine(index:Integer;data:string);overload;
      procedure InsertNewLine(index:Integer;data:Double);overload;
      procedure InsertNewLine(index:Integer;data:array of string);overload;
      procedure InsertNewLine(index:Integer;data:array of PDouble);overload;

      procedure SaveToFile(path:string);virtual;
      procedure Clear;
  end;

  TTscDebugCSV  = class(TTscCSV)
    public
      procedure SaveToFile(path:string);override;
  end;

implementation

{$region'    TTscCSV    '}
constructor TTscCSV.Create;
begin
  FCSV  := TStringList.Create;
  ClearData;
end;

destructor TTscCSV.Destroy;
begin
  FCSV.Free;
end;

procedure TTscCSV.NewLine;
begin
  FCSV.Add(FNowData);
  ClearData;
end;

procedure TTscCSV.InsertLine(index:Integer);
begin
  FCSV.Insert(index, FNowData);
  ClearData;
end;


procedure TTscCSV.AddData(data:string);
begin
  if FNowData <> '' then
    FNowData  := FNowData + ',' + data
  else
    FNowData  := data;
end;

procedure TTscCSV.AddData(data:Double);
begin
  AddData(FloatToStr(data));
end;


procedure TTscCSV.AddData(data:Array of String);
var
  I: Integer;
begin
  for I := 0 to Length(data) -1 do AddData(data[I]);
end;

procedure TTscCSV.AddData(data:array of PDouble);
var
  I: Integer;
begin
  for I := 0 to Length(data) -1 do AddData(data[I]^);
end;


procedure TTscCSV.AddNewLine(data:string);
begin
  AddData(data);
  NewLine;
end;

procedure TTscCSV.AddNewLine(data:Double);
begin
  AddData(data);
  NewLine;
end;


procedure TTscCSV.AddNewLine(data:array of string);
begin
  AddData(data);
  NewLine;
end;

procedure TTscCSV.AddNewLine(data:array of PDouble);
begin
  AddData(data);
  NewLine;
end;


procedure TTscCSV.InsertNewLine(index:Integer;data:string);
begin
  AddData(data);
  InsertLine(index);
end;

procedure TTscCSV.InsertNewLine(index:Integer;data:Double);
begin
  AddData(data);
  InsertLine(index);
end;

procedure TTscCSV.InsertNewLine(index:Integer;data:array of string);
begin
  AddData(data);
  InsertLine(index);
end;

procedure TTscCSV.InsertNewLine(index:Integer;data:array of PDouble);
begin
  AddData(data);
  InsertLine(index);
end;


procedure TTscCSV.ClearData;
begin
  TspVarInitString([@FNowData]);
end;

procedure TTscCSV.Clear;
begin
  ClearData;
  FCSV.Clear;
end;

procedure TTscCSV.SaveToFile(path:string);
begin
  if ExtractFileExt(path) <> '.csv' then
    path  := path + '.csv';
  FCSV.SaveToFile(path);
end;
{$endregion}

procedure TTscDebugCSV.SaveToFile(path:string);
begin
  {$IFDEF DEBUG}
  inherited SaveToFile(path);
  {$ENDIF}
end;

end.
