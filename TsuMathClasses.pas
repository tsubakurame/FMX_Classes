unit TsuMathClasses;

interface
uses
  System.Math, System.Classes, System.SysUtils,
  TsuUtils
  ;

type
  //  ループを使用しない加算平均値算出クラス
  TTscAverage = class(TObject)
    private
      FAverage    : Double;
      FCount      : UInt32;
      function GetAverageData:Double;
    public
      constructor Create;virtual;
      procedure Clear;

      procedure SetData(data:Double);overload;virtual;
      procedure SetData(data:Array of Double);overload;virtual;

      procedure GetAverage(data:Double ; var avg : Double);overload;
      function GetAverage(data:Double):Double;overload;
      property TotalCount : UInt32 read FCount;
      property Average    : Double read GetAverageData;
  end;

  //  ループを使用しない移動平均値算出クラス
  TTscMovingAverage = class(TTscAverage)
    private
      FBuffer : Array of Double;
      FSamples: UInt16;
      procedure SetSamples(samples:UInt16);
    public
      constructor Create(samples : UInt16);reintroduce;
      procedure SetData(data : Double);override;
      property Samples  : UInt16 read FSamples write SetSamples;
  end;

  //  最小二乗法
  TTscLeastSquaresMethod = class(TObject)
    private
      sum_xy  : double;
      sum_x   : double;
      sum_y   : double;
      sum_x2  : double;
      N       : Integer;
      Fa, Fb  : Double;
    public
      constructor Create;
      destructor Destroy;override;
      procedure Clear;
      procedure AddData(data_x, data_y:double);
      procedure Calc;

      property ValueA : Double read Fa;
      property ValueB : Double read Fb;
  end;

implementation

{$region'    TTscAverage    '}
constructor TTscAverage.Create;
begin
  Clear;
end;

procedure TTscAverage.Clear;
begin
  TspVarInitDouble([@FAverage]);
  TspVarInitUInt16([@FCount]);
end;

procedure TTscAverage.SetData(data:Double);
begin
  FAverage  := ((Faverage * FCount) + data) / (FCount +1);
  Inc(FCount);
end;

procedure TTscAverage.SetData(data:array of Double);
var
  I: Integer;
begin
  for I := 0 to Length(data) -1 do SetData(data[I]);
end;

procedure TTscAverage.GetAverage(data:Double; var avg:Double);
begin
  avg := GetAverage(data);
end;

function TTscAverage.GetAverage(data:Double):Double;
begin
  SetData(data);
  Result    := FAverage;
end;

function TTscAverage.GetAverageData:Double;
begin
  Result  := FAverage;
end;
{$endregion}

{$region'    TTscLeastSquaresMethod    '}
constructor TTscLeastSquaresMethod.Create;
begin
  Clear;
  inherited Create;
end;

destructor TTscLeastSquaresMethod.Destroy;
begin
  inherited Destroy;
end;

procedure TTscLeastSquaresMethod.Clear;
begin
  sum_xy  := 0;
  sum_x   := 0;
  sum_y   := 0;
  sum_x2  := 0;
  N       := 0;
  Fa      := 0;
  Fb      := 0;
end;

procedure TTscLeastSquaresMethod.AddData(data_x: Double; data_y: Double);
begin
  sum_xy  := sum_xy + (data_x * data_y);
  sum_x   := sum_x + data_x;
  sum_y   := sum_y + data_y;
  sum_x2  := sum_x2 + Power(data_x, 2);
  Inc(N);
end;

procedure TTscLeastSquaresMethod.Calc;
begin
  Fa  := (N * sum_xy - (sum_x * sum_y)) / (N * sum_x2 - Power(sum_x, 2));
  Fb  := (sum_x2 * sum_y - sum_xy * sum_x) / (N * sum_x2 - Power(sum_x, 2));
end;
{$endregion}

{$region'    TTscMovingAverage    '}
constructor TTscMovingAverage.Create(samples:UInt16);
begin
  SetSamples(samples);
  inherited Create;
end;

procedure TTscMovingAverage.SetData(data:Double);
begin
  if FCount >= FSamples then
    begin
      FAverage  := ((FAverage * FSamples) +data -FBuffer[FCount mod FSamples]) / FSamples;
    end
  else
    begin
      FAverage  := ((FAverage * FCount) +data) / (FCount+1);
    end;
  FBuffer[FCount mod FSamples]  := data;
  Inc(FCount);
end;

procedure TTscMovingAverage.SetSamples(samples:UInt16);
begin
  SetLength(FBuffer, samples);
  FSamples  := samples;
  Clear;
end;
{$endregion}

end.
