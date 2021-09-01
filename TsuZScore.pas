unit TsuZScore;

interface
uses
  System.Generics.Collections, System.Math,
  TsuRingBuffer
  ;

type
  TTscZScore  = class(TObject)
    private
      procedure SetLags(value:Integer);
      procedure ParamsClear;
    protected
      FLags       : Integer;
      FThreshold  : Double;
      FData       : TTscRingBuffer<Single>;
      FAverage    : Single;
      FStd        : Single;
      FDataNum    : Integer;
      FSum        : Single;
      FSumSqr     : Single;
      FInfluence  : Single;
    public
      constructor Create;
      destructor Destroy;
      procedure Clear;
      function GetScore(value:Single):Single;

      property Lags : Integer read FLags write SetLags;
      property Threshold : Double read FThreshold write FThreshold;
      property Std  : Single read FStd;
      property Average  : Single read FAverage;
      property Influence  : Single read FInfluence write FInfluence;
  end;

implementation

constructor TTscZScore.Create;
begin
  FInfluence  := 0;
  FLags       := 30;
  FThreshold  := 5;
  SetLags(10);
  ParamsClear;
end;

destructor TTscZScore.Destroy;
begin
  FData.Free;
end;

procedure TTscZScore.ParamsClear;
begin
  FSum        := 0;
  FDataNum    := 0;
  FSumSqr     := 0;
end;

procedure TTscZScore.SetLags(value:Integer);
begin
  FLags := value;
  FData.Free;
  FData := TTscRingBuffer<Single>.Create(FLags);
  ParamsClear;
end;

function TTscZScore.GetScore(value:Single):Single;
var
  buf : TArray<Single>;
  I: Integer;
  avg : Single;
  sum : Single;
  std : Single;
  scr : Single;
  old : Single;
  cash  : Single;
begin
  if FDataNum >= FLags then
    begin
      FData.ReadOld(old);
      cash  := value -FAverage;
      if cash < 0 then cash := cash *-1;
      if cash >= FThreshold * FStd then
        begin
          if value > avg then
            Result  := 1
          else
            Result  := -1;
          value := FInfluence*value + (1-FInfluence)*old;
        end
      else
        begin
          Result  := 0;
        end;
      FSum    := FSum -old +value;
      FSumSqr := FSumSqr -Power(old,2) + Power(value, 2);
      FAverage  := FSum / FLags;
      cash  := (FLags * FSumSqr - Power(FSum, 2))/ (FLags * (FLags-1));
      FStd      := Sqrt(cash);
      if IsNan(FStd) then
        FDataNum := FLags -1;
    end
  else
    begin
      Result  := 0;
    end;
  FData.Write(value);
  inc(FDataNum);

  //  データ数がLagsになった時点で平均と標準偏差を出す
  if FDataNum = FLags then
    begin
      FSum    := 0;
      FSumSqr := 0;
      FData.ReadBuffer(buf);
      for I := 0 to FLags -1 do
        begin
          FSum    := FSum + buf[I];
          FSumSqr := FSumSqr + Power(buf[I], 2);
        end;
      FAverage  := FSum / FLags;
      FStd      := Sqrt((FLags * FSumSqr - Power(FSum, 2)) / (FLags * (FLags-1)));
    end;
end;

procedure TTscZScore.Clear;
begin
  SetLags(FLags);
end;

end.
