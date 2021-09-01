unit TsuBiquadFilter;

interface
uses
  System.Math, TsuCSV, SysUtils, TypInfo
  ;

type
  TTseCoefficientType = (CTP_QUALITY, CTP_BAND_WIDTH, CTP_SLOPE);
  TTseFilterType      = ( FTP_LPF,
                          FTP_HPF,
                          FTP_NOTCH
                          );
//                          ,
//                          FTP_BPF,
//                          FTP_NOTCH,
//                          FTP_APF,
//                          FTP_PEAKING_EQ,
//                          FTP_LOW_SHELF,
//                          FTP_HIGH_SHELF);
  TTssFilterTypes     = set of TTseFilterType;
  TTseFilterChar      = (FTC_SELF_PARAM, FTC_BUTTERWORTH, FTC_CHEBYCHEV);
  TTseDegree          = (BiLinear, BiQuad);
//  TTsrBiQuadCoef      = record
//    private
//      Fa0,  Fa1,  Fa2,  Fb0,  Fb1,  Fb2 : Double;
//      procedure Set_a0(value:double);
//    public
//      property a0 : Double read Fa0 write Set_a0;
//  end;
  TTsdCoefProc  = procedure of object;
  TTsrButterworthCoef = record
    CascadeCoef : Double;
  end;
  TTsrFilterParams  = record
  public
    Order   : Integer;
    Degree  : TTseDegree;
  case FilterChar : TTseFilterChar of
    FTC_SELF_PARAM  : (Q  : Double);
    FTC_BUTTERWORTH : (CascadeCoef  : Double);
    FTC_CHEBYCHEV   : (A  : Double;
                       B  : Double;);
  end;

  TTscBiFilter        = class(TObject)
    private
      FOmega0       : Double;
      FsinOmega0    : Double;
      FcosOmega0    : Double;
      Fb0, Fb1, Fb2 : Double;
      Fa0, Fa1, Fa2 : Double;
      Fin1, Fin2, Fout1, Fout2  : Double;
      FFilterType   : TTseFilterType;
      FDegree       : TTseDegree;
      FCutOfFreq    : Integer;
      FSamplingFreq : Integer;
      FCascadeCoef  : Double;
      FFilterChar   : TTseFilterChar;
//      FCalcCoefFunc : Array [Low(TTseDegree)..High(TTseDegree)] of procedure;
      procedure CalcCoef;
      procedure SetCoef(a0,a1,a2,b0,b1,b2:Double);
      procedure BiLiLPF;
      procedure BiQuLPF;
      procedure BiLiHPF;
      procedure BiQuHPF;
//      procedure BiLiNotch;
      procedure BiQuNotch;

      procedure SetSamplingFreq(smp:Integer);
      procedure SetCutOfFreq(freq:Integer);
      procedure SetCascadeCoef(val:Double);
    public
      constructor Create(degree: TTseDegree; ftyp: TTseFilterType; smp: Integer; cutof: Integer; cascoef:Double);
      function Input(value:Double):Double;
      function FreqChar(freq:Integer):Double;
      procedure ResetFeedBack;
      property SamplingFreq : Integer read FSamplingFreq write SetSamplingFreq;
      property CutOfFreq    : Integer read FCutOfFreq write SetCutOfFreq;
      property CascadeCoef  : Double read FCascadeCoef write SetCascadeCoef;
  end;
  TTscCascadeBiFilter = class(TObject)
    private
      FDegree : Integer;
      FFilterType   : TTseFilterType;
      FCutOfFreq    : Integer;
      FSamplingFreq : Integer;
      FBiFilterArray  : Array of TTscBiFilter;
      procedure CalcCoef;
      function CalcCascadeCoef(k:Integer):Double;
      procedure SetDegree(val:Integer);
      procedure SetFilterType(typ:TTseFilterType);
      procedure SetCoF(cof:Integer);
      procedure SetSmp(smp:Integer);
    public
      constructor Create(degree:Integer; ftyp:TTseFilterType; smp,cutof:Integer);
      function Input(value:Double):Double;
      procedure OutputFreqChar;
      procedure ResetFeedBack;
      function FreqChar(freq:Integer):Double;
      property FilterType : TTseFilterType read FFilterType write SetFilterType;
      property CutOfFreq  : Integer read FCutOfFreq write SetCoF;
      property SampligFreq: Integer read FSamplingFreq write SetSmp;
      property Degree     : Integer read FDegree write SetDegree;
  end;

var
  EvenOrderOnlyFilter : TTssFilterTypes = [FTP_NOTCH];

implementation

constructor TTscBiFilter.Create(degree: TTseDegree;
                                ftyp: TTseFilterType;
                                smp: Integer;
                                cutof: Integer;
                                cascoef:Double);
begin
  FDegree       := degree;
  FFilterType   := ftyp;
  FSamplingFreq := smp;
  FCutOfFreq    := cutof;
  FCascadeCoef  := cascoef;
  CalcCoef;
end;

procedure TTscBiFilter.SetSamplingFreq(smp: Integer);
begin
  FSamplingFreq := smp;
  CalcCoef;
end;

procedure TTscBiFilter.SetCutOfFreq(freq: Integer);
begin
  FCutOfFreq  := freq;
  CalcCoef;
end;

procedure TTscBiFilter.SetCascadeCoef(val: Double);
begin
  FCascadeCoef  := val;
  CalcCoef;
end;

procedure TTscBiFilter.CalcCoef;
begin
  FOmega0       := (2*PI*FCutOfFreq)/FSamplingFreq;
  FsinOmega0    := Sin(FOmega0);
  FcosOmega0    := Cos(FOmega0);
  case FDegree of
    BiLinear:
      begin
        case FFilterType of
          FTP_LPF         : BiLiLPF;
          FTP_HPF         : BiLiHPF;
          FTP_NOTCH       : raise Exception.Create('Set the filter order to an even number');
        end;
      end;
    BiQuad  :
      begin
        case FFilterType of
          FTP_LPF         : BiQuLPF;
          FTP_HPF         : BiQuHPF;
          FTP_NOTCH       : BiQuNotch;
        end;
      end;
  end;
  ResetFeedBack;
end;

procedure TTscBiFilter.ResetFeedBack;
begin
  Fin1  := 0;
  Fin2  := 0;
  Fout1 := 0;
  Fout2 := 0;
end;

procedure TTscBiFilter.SetCoef(a0: Double; a1: Double; a2: Double; b0: Double; b1: Double; b2: Double);
begin
  Fa0 := a0;
  Fa1 := a1;
  Fa2 := a2;
  Fb0 := b0;
  Fb1 := b1;
  Fb2 := b2;
end;

procedure TTscBiFilter.BiLiLPF;
begin
  SetCoef(1 -FcosOmega0 +FsinOmega0,
          1 -FcosOmega0 -FsinOmega0,
          0,
          1 -FcosOmega0,
          1 -FcosOmega0,
          0);
end;

procedure TTscBiFilter.BiQuLPF;
begin
  SetCoef(1 +(FCascadeCoef/2)*FsinOmega0,
          -2*FcosOmega0,
          1 -(FCascadeCoef/2)*FsinOmega0,
          (1-FcosOmega0)/2,
          1-FcosOmega0,
          (1-FcosOmega0)/2);
end;

procedure TTscBiFilter.BiLiHPF;
begin
  SetCoef(1 -FcosOmega0 +FsinOmega0,
          1 -FcosOmega0 -FsinOmega0,
          0,
          FsinOmega0,
          -FsinOmega0,
          0);
end;

procedure TTscBiFilter.BiQuHPF;
begin
  SetCoef(1 +(FCascadeCoef/2)*FsinOmega0,
          -2*FcosOmega0,
          1 -(FCascadeCoef/2)*FsinOmega0,
          (1+FcosOmega0)/2,
          -1-FcosOmega0,
          (1+FcosOmega0)/2);
end;

procedure TTscBiFilter.BiQuNotch;
begin
  SetCoef(1 +(FCascadeCoef/2)*FsinOmega0,
          -2*FcosOmega0,
          1 -(FCascadeCoef/2)*FsinOmega0,
          1,
          -2*FcosOmega0,
          1);
end;

function TTscBiFilter.Input(value: Double): Double;
var
  output  : Double;
begin
  output  := ((Fb0/Fa0) * value)
             + (Fb1/Fa0) * Fin1
             + (Fb2/Fa0) * Fin2
             - (Fa1/Fa0) * Fout1
             - (Fa2/Fa0) * Fout2;
  Fin2  := Fin1;
  Fin1  := value;
  Fout2 := Fout1;
  Fout1 := output;
  Result:= output;
end;

function TTscBiFilter.FreqChar(freq: Integer): Double;
var
  fb1r, fb1j, fb2r, fb2j  : Double;
  fa1r, fa1j, fa2r, fa2j  : double;
  omega : double;
  b     : double;
  br, bj  : Double;
  a     : double;
  ar, aj: Double;
begin
  omega := 2*pi*freq*(1/FSamplingFreq);
  fb1r    := Fb1*cos(omega);
  fb1j    := Fb1*-sin(omega);
  fb2r    := Fb2*cos(2*omega);
  fb2j    := Fb2*-sin(2*omega);
  br      := Fb0 +fb1r +fb2r;
  bj      := fb1j +fb2j;
  b       := sqrt(power(br,2)+power(bj,2));
  fa1r    := Fa1*cos(omega);
  fa1j    := Fa1*-sin(omega);
  fa2r    := fa2*Cos(2*omega);
  fa2j    := Fa2*-sin(2*omega);
  ar      := Fa0 +fa1r +fa2r;
  aj      := fa1j +fa2j;
  a       := Sqrt(power(ar,2)+power(aj,2));
  Result  := 20*log10(b/a);
end;

constructor TTscCascadeBiFilter.Create(degree: Integer; ftyp: TTseFilterType; smp: Integer; cutof: Integer);
begin
  FDegree := degree;
  FSamplingFreq := smp;
  FCutOfFreq    := cutof;
  FFilterType   := ftyp;
  CalcCoef;
end;

procedure TTscCascadeBiFilter.CalcCoef;
var
  I: Integer;
begin
  //  フィルタ次数が偶数でしか対応できないフィルターの場合、次数を偶数に変更する。
  if (FDegree mod 2 = 1) and (FFilterType in EvenOrderOnlyFilter) then
    FDegree := FDegree + 1;

  for I := 0 to Length(FBiFilterArray) -1 do
    begin
      if FBiFilterArray[I] <> nil then
        FreeAndNil(FBiFilterArray[I]);
    end;
  SetLength(FBiFilterArray, Ceil(FDegree/2));
  for I := 0 to Length(FBiFilterArray) -1 do
    begin
      if FDegree mod 2 = 0 then
        begin
          FBiFilterArray[I] := TTscBiFilter.Create(BiQuad, FFilterType, FSamplingFreq, FCutOfFreq, CalcCascadeCoef(I+1));
        end
      else
        begin
          if I = 0 then
            begin
              FBiFilterArray[I] := TTscBiFilter.Create(BiLinear, FFilterType, FSamplingFreq, FCutOfFreq, 1);
            end
          else
            begin
              FBiFilterArray[I] := TTscBiFilter.Create(BiQuad, FFilterType, FSamplingFreq, FCutOfFreq, CalcCascadeCoef(I));
            end;
        end;
    end;
end;

function TTscCascadeBiFilter.CalcCascadeCoef(k: Integer): Double;
begin
  Result  := -2*cos(((2*k + FDegree -1)/(2*FDegree))*Pi);
end;

function TTscCascadeBiFilter.Input(value: Double): Double;
var
  I: Integer;
begin
  for I := 0 to Length(FBiFilterArray) -1 do
    begin
      value := FBiFilterArray[I].Input(value);
    end;
  Result  := value;
end;

procedure TTscCascadeBiFilter.OutputFreqChar;
var
  csv : TTscCSV;
  I: Integer;
begin
  csv := TTscCSV.Create;
  for I := 0 to (FSamplingFreq div 2) -1 do
    begin
      csv.AddData(I);
      csv.AddData(FreqChar(I));
      csv.NewLine;
    end;
  csv.SaveToFile( 'FreqChar_'+
                  GetEnumName(typeinfo(TTseFilterType),Ord(FFilterType))+'_'+
                  'N='+IntToStr(FDegree)+'_'+
                  'Cut='+IntToStr(FCutOfFreq)+'_'+
                  'Smp='+IntToStr(FSamplingFreq)+
                  '.csv');
  csv.Free;
end;

function TTscCascadeBiFilter.FreqChar(freq: Integer): Double;
var
  cash  : Double;
  I: Integer;
begin
  cash  := 0;
  for I := 0 to Length(FBiFilterArray)-1 do
    begin
      cash  := cash +FBiFilterArray[I].FreqChar(freq);
    end;
  Result  := cash;
end;

procedure TTscCascadeBiFilter.SetDegree(val: Integer);
begin
  FDegree := val;
  CalcCoef;
end;

procedure TTscCascadeBiFilter.SetFilterType(typ: TTseFilterType);
begin
  FFilterType := typ;
  CalcCoef;
end;

procedure TTscCascadeBiFilter.SetCoF(cof: Integer);
begin
  FCutOfFreq  := cof;
  CalcCoef;
end;

procedure TTscCascadeBiFilter.SetSmp(smp: Integer);
begin
  FSamplingFreq := smp;
  CalcCoef;
end;

procedure TTscCascadeBiFilter.ResetFeedBack;
var
  I: Integer;
begin
  for I := 0 to Length(FBiFilterArray)-1 do
    FBiFilterArray[I].ResetFeedBack;
end;

end.
