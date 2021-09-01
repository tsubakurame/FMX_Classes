unit TsuWaveUtils;

interface
uses
  windows, MMSystem,
  WinApi.WinMM.MMReg
  ;

type
  TTseWaveUtilsMode  = (WU_NEW, WU_OPEN);
  TTsdWaveOneBuffer  = array[0..4096-1] of SmallInt;
  TTsdWaveOneBufferBytes = array[0..8192-1] of Byte;
  TTsrWaveSize = record
    ByteSize      : UInt32;
    SmallIntSize  : UInt32;
  end;
  TTscWaveUtils  = class(TObject)
    private
      FMode     : TTseWaveUtilsMode;
      FSampling : UInt32;
      FCh       : UInt16;
      FBpS      : UInt16;
      FFileName : string;
      hIO       : Integer;
      PCM       : tWAVEFORMATEX;
      RIFF      : MMCKINFO;
      FMT       : MMCKINFO;
      DATA      : MMCKINFO;
      FFormat   : Word;
      FTotalReadSize : TTsrWaveSize;
      FTotalWriteSize: TTsrWaveSize;
      procedure NewFileCreate;
      procedure NewFileOpen;
    protected
      FPlaySize : TTsrWaveSize;
    public
      constructor Create( mode:TTseWaveUtilsMode;
                          FileName:string;
                          fs:UInt32 = 0;
                          ch:UInt32 = 0;
                          bps:UInt32 =0);overload;
      constructor Create( mode: TTseWaveUtilsMode;
                          FileName:string;
                          format:WAVEFORMATEX);overload;
      destructor Destroy;override;

      procedure WriteData(data:array of Byte);overload;
      procedure WriteData(data:array of Byte; bytes:UInt32);overload;
      procedure WriteData(data:TTsdWaveOneBuffer; writeWord:Integer);overload;
      procedure Close;

      procedure ReadData(var buffer:TTsdWaveOneBuffer; var ReadWord:Integer);

      property PlaySize : TTsrWaveSize read FPlaySize;
      property TotalReadSize : TTsrWaveSize read FTotalReadSize;
      property TotalWriteSize: TTsrWaveSize read FTotalWriteSize;
      property FileName : string read FFileName;
      property SamplingFreq : UInt32 read FSampling;
  end;

implementation

constructor TTscWaveUtils.Create(mode:TTseWaveUtilsMode;
                                FileName:string;
                                fs:UInt32 = 0;
                                ch:UInt32 = 0;
                                bps:UInt32 =0);
begin
  inherited Create;
  FFileName   := FileName;
  case mode of
    WU_NEW  :
      begin
        FMode       := mode;
        FSampling   := fs;
        FCh         := ch;
        FBpS        := bps;
        FFormat     := WAVE_FORMAT_PCM;
        NewFileCreate;
      end;
    WU_OPEN :
      begin
        FMode       := mode;
        NewFileOpen;
      end;
  end;
end;

constructor TTscWaveUtils.Create(mode:TTseWaveUtilsMode;
                                FileName:string;
                                format:WAVEFORMATEX);
begin
  inherited Create;
  FFileName   := FileName;
  case mode of
    WU_NEW  :
      begin
        FMode       := mode;
        FSampling   := format.nSamplesPerSec;
        FCh         := format.nChannels;
        FBpS        := format.wBitsPerSample;
        FFormat     := format.wFormatTag;
        NewFileCreate;
      end;
    WU_OPEN :
      begin
        FMode       := mode;
        NewFileOpen;
      end;
  end;
end;

destructor TTscWaveUtils.Destroy;
begin
  inherited Destroy;
end;

procedure TTscWaveUtils.NewFileCreate;
begin
  hIO := mmioOpen(PWideChar(FFileName), nil, MMIO_CREATE or MMIO_WRITE or MMIO_EXCLUSIVE);

  PCM.wFormatTag      := FFormat;
  PCM.nSamplesPerSec  := FSampling;
  PCM.wBitsPerSample  := FBpS;
  PCM.nChannels       := FCh;
  PCM.nBlockAlign     := FCh *FBpS div 8;
  PCM.nAvgBytesPerSec := FSampling * PCM.nBlockAlign;
  PCM.cbSize          := 0;

  RIFF.fccType        := mmioStringToFOURCC('WAVE', 0);
  mmioCreateChunk(hIO, @RIFF, MMIO_CREATERIFF);

  FMT.ckid            := mmioStringToFOURCC('fmt', 0);
  mmioCreateChunk(hIO, @FMT, 0);
  mmioWrite(hIO, @PCM, SizeOf(PCM) -2);
  mmioAscend(hIO, @FMT, 0);

  DATA.ckid           := mmioStringToFOURCC('data', 0);
  mmioCreateChunk(hIO, @DATA, 0);
end;

procedure TTscWaveUtils.NewFileOpen;
var
  MMres : MMRESULT;
  size  : UInt32;
begin
  hIO := mmioOpen(PWideChar(FFileName), nil, MMIO_READ);

  RIFF.fccType  := mmioStringToFOURCC('WAVE',0);
  MMres         := mmioDescend(hIO, @RIFF, nil, MMIO_FINDRIFF);
  if MMres <> MMSYSERR_NOERROR then Exit;

  FMT.ckid      := mmioStringToFOURCC('fmt', 0);
  MMres         := mmioDescend(hIO, @FMT, @RIFF, MMIO_FINDCHUNK);
  if MMres <> MMSYSERR_NOERROR then Exit;

  size          := mmioRead(hIO, @PCM, FMT.cksize);
  //FPlaySize.SmallIntSize  := FPlaySize.ByteSize div 2;
  if size <> FMT.cksize then Exit;

  DATA.ckid     := mmioStringToFOURCC('data',0);
  MMres         := mmioDescend(hIO, @DATA, @RIFF, MMIO_FINDCHUNK);
  if MMres <> MMSYSERR_NOERROR then Exit;

  FPlaySize.ByteSize      := DATA.cksize;
  FPlaySize.SmallIntSize  := FPlaySize.ByteSize div 2;
  FSampling               := PCM.nSamplesPerSec;
  FCh                     := PCM.nChannels;
  FBpS                    := PCM.wBitsPerSample;
end;

procedure TTscWaveUtils.WriteData(data: array of Byte);
var
  buf   : array[0..8191] of Byte;
  size  : UInt32;
  write : UInt32;
  writed: UInt32;
  I: UInt32;
begin
  size    := Length(data);
  writed  := 0;
  while size > 0 do
    begin
      if size >= 8192 then
        write := 8192
      else
        write := size;

      for I := 0 to write -1 do
        begin
          buf[I]  := data[writed +I];
        end;

      mmioWrite(hIO, @buf, write);
      size    := size -write;
      writed  := writed +write;
    end;
end;

procedure TTscWaveUtils.WriteData(data:array of Byte; bytes:UInt32);
var
  buf   : array[0..8191] of Byte;
  size  : UInt32;
  write : UInt32;
  writed: UInt32;
  I: Integer;
begin
  size  := bytes;
  writed:= 0;
  while size > 0 do
    begin
      if size >= 8192 then
        write := 8192
      else
        write := size;

        for I := 0 to write -1 do
          begin
            buf[I]  := data[writed +I];
          end;

      mmioWrite(hIO, @buf, write);
      size    := size -write;
      writed  := writed +write;
    end;
end;

procedure TTscWaveUtils.WriteData(data:TTsdWaveOneBuffer; WriteWord:Integer);
var
  buf : array[0..8191] of Byte;
  I : Integer;
begin
  for I := 0 to writeWord-1 do
    begin
      buf[I*2]      := data[I] and $00FF;
      buf[(I*2)+1]  := (data[I] shr 8) and $00FF;
    end;
  WriteData(buf, writeWord*2);
end;

procedure TTscWaveUtils.Close;
begin
  mmioAscend(hIO, @DATA, 0);
  mmioAscend(hIO, @RIFF, 0);
  mmioClose(hIO, 0);
end;

procedure TTscWaveUtils.ReadData(var buffer:TTsdWaveOneBuffer; var ReadWord:Integer);
var
  buf : TTsdWaveOneBufferBytes;
  I   : Integer;
begin
  ReadWord  := mmioRead(hIO, @buf, Length(buf));
  for I := 0 to Length(buffer) -1 do
    begin
      buffer[I] := (buf[I*2 +1] shl 8) + buf[I*2];
    end;
  FTotalReadSize.ByteSize  := FTotalReadSize.ByteSize + ReadWord;
  FTotalReadSize.SmallIntSize  := FTotalReadSize.ByteSize div 2;
  if ReadWord > 0 then ReadWord := ReadWord div 2;
end;

end.
