unit TsuFFTAnalyze;

interface

uses
  System.Generics.Collections, System.Math, System.Classes, System.SysUtils,
  TsuMath;

type
  TTseWindowFunc    = (WF_NONE, WF_HANNING, WF_HAMMING, WF_KAISER_BESSEL);
  TTscFFTAnalyze  = class(TObject)
    private
      procedure SetFFTSample(value: UInt32);
      procedure SetWindowFunc(value:TTseWindowFunc);
      procedure BitRevers;
      procedure WindowFuncSet;
      //procedure SetData(data:TArray<T>);
      procedure WindowFuncApply;
      procedure ButterflyCalc;
      procedure ResultOutPut;
    protected
      FFFTSample      : UInt32;
      FBitRevArray    : Array of UInt32;
      FWindowFuncArr  : Array of Double;
      FPowerN         : UInt16;
      FWindowFunc     : TTseWindowFunc;
      FAlpha          : Double;
      FAnalyzeData    : array of Single;
      FDataRe, FDataIm: array of Double;
      FResult         : array of Single;
    public
      procedure SetDataToAnalyze(data:array of Single);
      procedure GetResult(var data: array of Single);
    published
      property FFTSample  : UInt32 read FFFTSample write SetFFTSample;
      property WindowFunc : TTseWindowFunc read FWindowFunc write SetWindowFunc;
      property Alpha      : Double read FAlpha write FAlpha;
  end;

implementation

procedure TTscFFTAnalyze.SetFFTSample(value: UInt32);
begin
  FFFTSample  := value;
  FPowerN     := Floor(Ln(FFFTSample) / Ln(2));
  SetLength(FAnalyzeData, FFFTSample);
  SetLength(FDataRe, FFFTSample);
  SetLength(FDataIm, FFFTSample);
  SetLength(FResult, FFFTSample div 2);
  BitRevers;
  WindowFuncSet;
end;

procedure TTscFFTAnalyze.SetWindowFunc(value:TTseWindowFunc);
begin
  FWindowFunc := value;
  WindowFuncSet;
end;

procedure TTscFFTAnalyze.BitRevers;
var
  I, X : Integer;
  point : UInt32;
begin
  SetLength(FBitRevArray, FFFTSample);
  FBitRevArray[0] := 0;
  for I := 1 to FPowerN do
    begin
      point := Floor(Power(2,I));
      for X := (point div 2) to point -1 do
        FBitRevArray[X] := FBitRevArray[X - (point div 2)] + (FFTSample div point);
    end;
end;

procedure TTscFFTAnalyze.WindowFuncSet;
var
  I : Integer;
  strl  : TStringList;
begin
  SetLength(FWindowFuncArr, FFFTSample);
  case FWindowFunc of
    WF_NONE         : TspNoneWindow(FWindowFuncArr);
    WF_HANNING      : TspHanningWindow(FWindowFuncArr);
    WF_HAMMING      : TspHammingWindow(FWindowFuncArr);
    WF_KAISER_BESSEL: TspKaiserBesselDerivedWindow(FWindowFuncArr, FFFTSample, FAlpha);
  end;
  {$IFDEF DEBUG}
  strl  := TStringList.Create;
  for I := 0 to FFFTSample -1 do
    strl.Add(FloatToStr(FWindowFuncArr[I]));
  strl.SaveToFile('win_func.csv');
  strl.Free;
  {$ENDIF}
end;

procedure TTscFFTAnalyze.SetDataToAnalyze(data:array of Single);
var
  I: Integer;
begin
  for I := 0 to FFFTSample -1 do
    FAnalyzeData[I] := data[I];

  WindowFuncApply;
  ButterflyCalc;
  ResultOutPut;
end;

procedure TTscFFTAnalyze.WindowFuncApply;
var
  I: Integer;
begin
  for I := 0 to FFFTSample -1 do
    FAnalyzeData[I] := FAnalyzeData[I] * FWindowFuncArr[I];
end;

procedure TTscFFTAnalyze.ButterflyCalc;
var
  y,j,jp            : Integer;
  butterflyDistance : Integer;
  stage,
  numType,
  butterflySize       : integer;
  wRe, wIm, uRe, uIm  : Single;
  tempRe,tempIm       : Single;
  tempWRe,tempWIm     :Single;
  I: Integer;
begin
  for I := 0 to FFTSample -1 do
    begin
      FDataIm[I]  := 0;
      FDataRe[I]  := FAnalyzeData[FBitRevArray[I]];
    end;
  for stage := 1 to FPowerN do
    begin
      butterflyDistance := 1 shl stage;
      numType           := butterflyDistance shr 1;
      butterflySize     := butterflyDistance shr 1;

      wRe := 1.0;
      wIm := 0.0;

      uRe := Cos(Pi / butterflySize);
      uIm := -(Sin(Pi / butterflySize));

      for y := 0 to numType-1 do
        begin
          j := y;
          while j < Integer(FFFTSample) do
            begin
              jp  := j + butterflySIze;

              tempRe     := (FDataRe[jp] * wRe) - (FDataIm[jp] * wIm);
              tempIm     := (FDataRe[jp] * wIm) + (FDataIm[jp] * wRe);
              FDataRe[jp] := FDataRe[j] - tempRe;
              FDataIm[jp] := FDataIm[j] - tempIm;
              FDataRe[j]  := FDataRe[j] + tempRe;
              FDataIm[j]  := FDataIm[j] + tempIm;

              j := j + butterflyDistance;
            end;
          tempWRe := (wRe * uRe) - (wIm * uIm);
          tempWIm := (wRe * uIm) + (wIm * uRe);
          wRe := tempWRe;
          wIm := tempWIm;
        end;
    end;
end;

procedure TTscFFTAnalyze.ResultOutPut;
var
  I: Integer;
  value : Double;
begin
  for I := 0 to (FFFTSample div 2) -1 do
    begin
      try
        value := Sqrt(Sqr(FDataRe[I])+Sqr(FDataIm[I]));
        value := value / 1;
        value := value / (FFFTSample div 2);
        //if value <> 0 then
        value := 20*log10(value)
        //else
        //  value := -120;
      except
        value := 0;
      end;
      FResult[I]  := value;
    end;
end;

procedure TTscFFTAnalyze.GetResult(var data: array of Single);
var
  I: Integer;
begin
  for I := 0 to (FFFTSample div 2) -1 do
    data[I] := FResult[I];
end;

end.
