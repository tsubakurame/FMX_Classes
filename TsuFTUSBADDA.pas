unit TsuFTUSBADDA;

interface
uses
  System.RegularExpressions, System.SysUtils,
  IxCommIFUSBADDA, IxCommDeviceFTDI, TsuD2XXEEUA, TsuFTDITypedefD2XX,
  TsuStrUtils
  ;

type
  TTseChType        = (Rec, Play);
  TApPlayChSet      = set of Byte;
  TTscADDAChInfo  = class(TTscD2XXEEUA)
    private
      FChNum  : Integer;
      FChType : Array of TTseChType;
      procedure ChInfoSet(num:Integer; chtyp:UInt32);
      function GetChType(x:Integer):TTseChType;
    protected
      procedure DoRead(data:FT_pucData);override;
    public
      constructor Create;
      procedure ReadInfo;
      procedure WriteInfo(ChNum:Integer; playch:TApPlayChSet);
      property ChNum  : Integer read FChNum;
      property ChType[x:integer]  : TTseChType read GetChType;
  end;
  TTscFTUSBADDA = class(TObject)
    private
      FChInfo : TTscADDAChInfo;
      FCommIF : TIxCommIFUSBADDA;
      FPortA  : TIxCommDeviceFTDI;
      FRecSmpFreq   : UInt32;
      FPlaySmpFreq  : UInt32;
      function SamplingFreqToCMDByte(smp:UInt32):Byte;
      procedure SetRecSamplingFreq(smp:UInt32);
      procedure SetPlaySamplingFreq(smp:UInt32);
    public
      constructor Create;
      destructor Destroy;
      procedure Open;
      procedure Reset;
      procedure ADStop;
      procedure DAStop;
      procedure USBWritePointReset;
      procedure Purge;
      property RecSamplingFreq  : UInt32  read FRecSmpFreq write SetRecSamplingFreq;
      property PlaySamplingFreq : UInt32  read FPlaySmpFreq write SetPlaySamplingFreq;
      property ChInfo           : TTscADDAChInfo read FChInfo;
  end;

implementation
uses
  def_fpga_adr
  ;

{$region'    TTscADDAChInfo    '}
constructor TTscADDAChInfo.Create;
begin
  inherited Create;
//  FOpenInfo.Arg   := 'FTUSBADDAA';
//  FOpenInfo.Flag  := FT_OPEN_BY_SERIAL_NUMBER;
end;

procedure TTscADDAChInfo.DoRead(data:FT_pucData);
var
  cnum, chtyp : TMatch;
begin
  if data = '' then
    begin
      ChInfoSet($4,$C);
    end
  else
    begin
//      Log.d(data);
      cnum  := TRegEx.Match(data, '^.{2}');
      chtyp := TRegEx.Match(data, '(?<=^.{2})[0-9a-fA-F]*');
//      Form1.Memo1.Lines.Add(chtyp.Value);
      ChInfoSet(TsfHexToInt(cnum.Value), TsfHexToInt(chtyp.Value));
    end;
end;

procedure TTscADDAChInfo.ChInfoSet(num: Integer; chtyp: Cardinal);
var
  I : Integer;
begin
  FChNum  := num;
  SetLength(FChType, num+1);
  for I := 1 to num do
    begin
      if chtyp and (1 shl (I-1)) > 0 then
        FChType[I]  := TTseChType.Play
      else
        FChType[I]  := TTseChType.Rec;
    end;
end;

procedure TTscADDAChInfo.ReadInfo;
begin
  FOpenInfo.Arg   := AnsiString('FTUSBADDAA');
  FOpenInfo.Flag  := FT_OPEN_BY_SERIAL_NUMBER;
  ReadEEUA;
end;

function TTscADDAChInfo.GetChType(x: Integer): TTseChType;
begin
  Result  := FChType[x];
end;

procedure TTscADDAChInfo.WriteInfo(ChNum: Integer; playch: TApPlayChSet);
var
  pch: Byte;
  pval  : UInt32;
  pstr  : string;
begin
  FOpenInfo.Arg   := AnsiString('FTUSBADDAA');
  FOpenInfo.Flag  := FT_OPEN_BY_SERIAL_NUMBER;
  pval  := 0;
  for pch in playch do pval  := pval or (1 shl pch);
  DoWrite(IntToHex(ChNum,2)+IntToHex(pval));
end;
{$endregion}

constructor TTscFTUSBADDA.Create;
begin
  FChInfo := TTscADDAChInfo.Create;
  FChInfo.ReadInfo;
  FCommIF := TIxCommIFUSBADDA.Create('FTUSBADDAB');
  FPortA  := TIxCommDeviceFTDI.Create;
  FPortA.SetPath('FTUSBADDAA');
  RecSamplingFreq   := 768000;
  PlaySamplingFreq  := 768000;
//  FCommIF.exec_cmd_io_wr_word()
end;

procedure TTscFTUSBADDA.Open;
begin
  FPortA.Open;
  FPortA.SetTimeOuts(100,100);
end;

procedure TTscFTUSBADDA.Reset;
begin
  ADStop;
  DAStop;
end;

procedure TTscFTUSBADDA.ADStop;
begin
  FCommIF.exec_cmd_io_wr(ADR_ADC_CTRL, BIT_ADC_CTRL_STOP);
end;

procedure TTscFTUSBADDA.DAStop;
begin
  FCommIF.exec_cmd_io_wr(ADR_DAC_CTRL, BIT_DAC_CTRL_STOP)
end;

procedure TTscFTUSBADDA.USBWritePointReset;
begin
  FCommIF.exec_cmd_io_wr(ADR_USB_WP_RESET, BIT_USB_WP_RESET);
  FCommIF.exec_cmd_io_wr(ADR_USB_WP_RESET, 0);
end;

function TTscFTUSBADDA.SamplingFreqToCMDByte(smp: Cardinal): Byte;
begin
  case smp of
    768000:
      Result := BIT_DAC_MODE_768K;
    512000:
      Result := BIT_DAC_MODE_512K;
    384000:
      Result := BIT_DAC_MODE_384K;
    256000:
      Result := BIT_DAC_MODE_256K;
    192000:
      Result := BIT_DAC_MODE_192K;
    128000:
      Result := BIT_DAC_MODE_128K;
    96000:
      Result := BIT_DAC_MODE_96K;
    64000:
      Result := BIT_DAC_MODE_64K;
    48000:
      Result := BIT_DAC_MODE_48K;
    32000:
      Result := BIT_DAC_MODE_32K;
  else
    Result := BIT_DAC_MODE_768K;
  end;
end;

procedure TTscFTUSBADDA.SetRecSamplingFreq(smp: Cardinal);
begin
  FRecSmpFreq := smp;
  FCommIF.exec_cmd_io_wr(ADR_ADC_MODE, SamplingFreqToCMDByte(FRecSmpFreq));
end;

procedure TTscFTUSBADDA.SetPlaySamplingFreq(smp: Cardinal);
begin
  FPlaySmpFreq  := smp;
  FCommIF.exec_cmd_io_wr(ADR_DAC_MODE, SamplingFreqToCMDByte(FRecSmpFreq));
end;

procedure TTscFTUSBADDA.Purge;
begin
  FPortA.Purge;
end;

end.
