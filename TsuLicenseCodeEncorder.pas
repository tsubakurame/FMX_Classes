unit TsuLicenseCodeEncorder;

interface
uses
  System.Math, System.SysUtils, System.StrUtils, System.Classes,
  TsuMath
  ;

const
  SERIAL_BASE_NUM = 34;
  ALLAY_BASE_24 : array[0..23] of string  = ( 'A',  'B',  'C',  'D',  'E',
                                              'F',  'G',  'H',  'J',  'K',
                                              'L',  'M',  'N',  'P',  'Q',
                                              'R',  'S',  'T',  'U',  'V',
                                              'W',  'X',  'Y',  'Z');
  ALLAY_BASE_34 : array[0..33] of string  = ( '0',  '1',  '2',  '3',  '4',
                                              '5',  '6',  '7',  '8',  '9',
                                              'A',  'B',  'C',  'D',  'E',
                                              'F',  'G',  'H',  'J',  'K',
                                              'L',  'M',  'N',  'P',  'Q',
                                              'R',  'S',  'T',  'U',  'V',
                                              'W',  'X',  'Y',  'Z');
type
  TTsdIndexArray  = array[0..2] of Integer;
  TTsdIndexEnableArray  = array[0..8] of Boolean;
  TTscLicenseCodeEncorder = class(TObject)
    private
      FBaseRandomValue  : Integer;
      FHEX_Inc          : string;
      FHEX_Dec          : string;
      FAlp_Dec          : string;
      FHEX_Inc_Digit    : string;
      FHEX_Dec_Digit    : string;
      FAlp_Dec_Digit    : string;
      FRand_Code        : string;
      FDate             : string;
      FRand_Bit         : array[0..8] of Integer;
      FLicenseCode      : string;
      FIndexEnable      : TTsdIndexEnableArray;
      procedure BaseRandomize;
      function IntToBase24(value:Integer):string;
      function IntToBase34(value:Integer):string;
      function Base34ToInt(value:string):Integer;
      function Base24ToInt(value:string):Integer;
      procedure RondomBit;
      procedure BitSort;
      function CheckSum:Boolean;
      function CheckRandomValue:Boolean;
      procedure CheckDigit(dig_code:string; var index:TTsdIndexArray);
      function CheckValue(dig_code:string):string;
      function CheckValueHex(dig_code:string):Integer;
      function CheckValueAlp(dig_code:string):Integer;
      procedure DigitEncord(var dig_code:string; value:Integer);
    public
      constructor Create;
      function CodeCreate:string;
      function Decode:Boolean;
    published
      property LicenseCode  : string read FLicenseCode write FLicenseCode;
  end;

implementation

constructor TTscLicenseCodeEncorder.Create;
begin
  inherited Create;
end;

function TTscLicenseCodeEncorder.CodeCreate:string;
var
  alp_max : Integer;
  I: Integer;
  checksum  : Integer;
  X: Integer;
begin
  BaseRandomize;
  FHEX_Inc          := IntToHex(FBaseRandomValue,3);
  FHEX_Dec          := IntToHex(4095-FBaseRandomValue,3);
  alp_max := Floor(Power(24, 3) -1);
  FAlp_Dec  := IntToBase24(alp_max -FBaseRandomValue);
  FRand_Code  := FHEX_Inc + FHEX_Dec + FAlp_Dec;
  RondomBit;
  FLicenseCode  := '';
  for I := 0 to 8 do
    begin
      for X := 0 to 8 do
        begin
          if FRand_Bit[X] = I then
            begin
              FLicenseCode  := FLicenseCode +FRand_Code[X+1];
              break;
            end;
        end;
      //FLicenseCode  := FLicenseCode + FRand_Code[FRand_Bit[I]+1];
    end;
  FLicenseCode  := FLicenseCode + FHEX_Inc_Digit + FHEX_Dec_Digit + FAlp_Dec_Digit;
  checksum  := 0;
  for I := 1 to Length(FLicenseCode) do
    begin
      checksum  := checksum xor Base34ToInt(FLicenseCode[I]);
    end;
  FLicenseCode  := FLicenseCode + IntToBase34(checksum mod 34);
  Result        := FLicenseCode;
end;

procedure TTscLicenseCodeEncorder.BaseRandomize;
begin
  FBaseRandomValue  := Random(4095);
end;

function TTscLicenseCodeEncorder.IntToBase24(value:Integer):string;
var
  res : string;
begin
  if value <> 0 then
    begin
      while value > 0 do
        begin
          res   := ALLAY_BASE_24[value mod 24] + res;
          value := value div 24;
        end;
    end
  else
    res := ALLAY_BASE_24[value mod 24];
  Result  := res;
end;

function TTscLicenseCodeEncorder.IntToBase34(value:Integer):string;
var
  res : string;
begin
  if value <> 0 then
    begin
      while value > 0 do
        begin
          res   := ALLAY_BASE_34[value mod 34] + res;
          value := value div 34;
        end;
    end
  else
    res := ALLAY_BASE_34[value mod 34];
  Result  := res;
end;

function TTscLicenseCodeEncorder.Base34ToInt(value:string):Integer;
var
  I : Integer;
  X: Integer;
begin
  Result  := 0;
  for X := 0 to Length(value) do
    begin
      for I := 0 to Length(ALLAY_BASE_34)-1 do
        begin
          if ALLAY_BASE_34[I] = value[Length(value)-X] then
            begin
              Result  := Result + Floor(I * Power(34, X));
              Break;
            end;
        end;
    end;
end;

function TTscLicenseCodeEncorder.Base24ToInt(value:string):Integer;
var
  I : Integer;
  X: Integer;
begin
  Result  := 0;
  for X := 0 to Length(value) do
    begin
      for I := 0 to Length(ALLAY_BASE_24)-1 do
        begin
          if ALLAY_BASE_24[I] = value[Length(value)-X] then
            begin
              Result  := Result + Floor(I * Power(24, X));
              Break;
            end;
        end;
    end;
end;

procedure TTscLicenseCodeEncorder.RondomBit;
var
  rand_bit      : array[0..8] of Integer;
  rand_bit_str  : array[0..8] of string;
  I: Integer;
  idx : Integer;
  dig_code  : string;
begin
  Randomize;
  for I := 0 to Length(FRand_Bit) -1 do
      FRand_Bit[I] := I;
  TspShuffle(FRand_Bit);
  BitSort;

  for I := 0 to Length(FRand_Bit) -1 do
    begin
      rand_bit[I] := Floor(Power(2, FRand_Bit[I]));
    end;

  for I := 0 to 2 do
    begin
      DigitEncord(dig_code, rand_bit[I*3] + rand_bit[I*3+1] + rand_bit[I*3+2]);
      case I of
        0 : FHEX_Inc_Digit  := dig_code;
        1 : FHEX_Dec_Digit  := dig_code;
        2 : FAlp_Dec_Digit  := dig_code;
      end;
    end;
end;

procedure TTscLicenseCodeEncorder.BitSort;
var
  I : Integer;
  X: Integer;
  cash  : Integer;
  N: Integer;
begin
  for N := 0 to 2 do
    begin
      for I := 0 to 1 do
        begin
          for X := N*3 to N*3+1-I do
            begin
              if FRand_Bit[X] > FRand_Bit[X+1] then
                begin
                  cash            := FRand_Bit[X];
                  FRand_Bit[X]    := FRand_Bit[X+1];
                  FRand_Bit[X+1]  := cash;
                end;
            end;
        end;
    end;
end;

procedure TTscLicenseCodeEncorder.DigitEncord(var dig_code:string; value:Integer);
begin
  dig_code  := IntToBase34(value);
  while Length(dig_code) < 2 do
    dig_code  := '0' + dig_code;
end;

function TTscLicenseCodeEncorder.Decode:Boolean;
begin
  if CheckSum and CheckRandomValue then
    Result  := True
  else
    Result  := False;
end;


function TTscLicenseCodeEncorder.CheckSum:Boolean;
var
  I: Integer;
  checksum  : Integer;
  cash  : string;
begin
  checksum  := 0;
  for I := 1 to 15 do
    begin
      //cash  := FLicenseCode[I];
      checksum  := checksum xor Base34ToInt(FLicenseCode[I]);
    end;
  Result  := FLicenseCode[16] = IntToBase34(checksum mod 34);
end;

function TTscLicenseCodeEncorder.CheckRandomValue:Boolean;
var
  inc_dig, dec_dig, alp_dig : string;
  hex_inc, hex_dec, alp_dec : Integer;
  index : TTsdIndexArray;
  cash  : string;
begin
  hex_inc := CheckValueHex(MidStr(FLicenseCode, 10, 2));
  alp_dec := CheckValueAlp(MidStr(FLicenseCode, 14, 2));
  hex_dec := CheckValueHex(MidStr(FLicenseCode, 12, 2));

  if (hex_inc = (4095 - hex_dec)) and (hex_inc =  (Floor(Power(24, 3) -1) -alp_dec)) then
    Result  := True
  else
    Result  := False;
end;

function TTscLicenseCodeEncorder.CheckValue(dig_code:string):string;
var
  index : TTsdIndexArray;
  cash  : string;
  I: Integer;
  st  : PChar;
  //cash  : PChar;
begin
  CheckDigit(dig_code, index);
  cash  := '';
  //st  := PChar(FLicenseCode);
  for I := 0 to 2 do
    begin
      cash  := cash + FLicenseCode[index[I]+1];
      //cash[I]^ := st[index[I]]^;
    end;
  Result  := cash;
end;

function TTscLicenseCodeEncorder.CheckValueHex(dig_code:string):Integer;
begin
  Result  := StrToInt('$' + CheckValue(dig_code));
end;

function TTscLicenseCodeEncorder.CheckValueAlp(dig_code:string):Integer;
begin
  Result  := Base24ToInt(CheckValue(dig_code));
end;

procedure TTscLicenseCodeEncorder.CheckDigit(dig_code:string; var index:TTsdIndexArray);
var
  value,  I : Integer;
  idx : Integer;
  flag  : Boolean;
  exclude : array[0..8] of Boolean;
begin
  flag  := False;
  for I := 0 to 8 do exclude[I] := True;
  while not flag do
    begin
      idx := 2;
      value := Base34ToInt(dig_code);
      for I := 0 to 8 do
        begin
          if exclude[8-I] then
            begin
              if value >= Power(2, 8-I) then
                begin
                  index[idx]  := 8-I;
                  value := value - Floor(Power(2, 8-I));
                  Dec(idx);
                end;
            end;
        end;
      if idx = -1 then flag := True
      else
        exclude[index[2]] := False;
    end;
end;

end.
