unit TsuWaveUtilsEx;

interface
uses
  Winapi.MMSystem,
  WinApi.WinMM.MMReg,
  WinApi.Ks
  ;


type
  TTseWaveUtilsMode  = (WU_NEW, WU_OPEN);
  TTsdWaveOneBuffer  = array[0..4096-1] of SmallInt;
  TTsdWaveOneBufferBytes = array[0..8192-1] of Byte;
  TTsdWaveOneBufferSingle = array[0..(8192 div 4)-1] of Single;
  TTsrWaveSize = record
    ByteSize      : UInt32;
    SmallIntSize  : UInt32;
    SingleSize    : UInt32;
  end;
  TTScWaveSize  = class(TObject)
    protected
      FSize     : TTsrWaveSize;
    public
      property Size : TTsrWaveSize read FSize;
      procedure Add(ByteSize:UInt32);
  end;
  TTscWaveUtilsEx = class(TObject)
    private
      FFileName : string;
      //FMode     : TTseWaveUtilsMode;
      hIO       : Integer;
      PCM       : WAVEFORMATEXTENSIBLE;
      RIFF      : MMCKINFO;
      FMT       : MMCKINFO;
      DATA      : MMCKINFO;
      KS        : KSDATAFORMAT;
      function GetPlaySize:TTsrWaveSize;
      function GetTotalReadSize:TTsrWaveSize;
      function GetWriteSize:TTsrWaveSize;
    public
      constructor Create;{
                        ( mode: TTseWaveUtilsMode;
                          FileName:string;
                          format:WAVEFORMATEXTENSIBLE);}
      destructor Destroy;override;
      procedure NewFileCreate(FileName:string;format:WAVEFORMATEXTENSIBLE);
      procedure NewFileOpen(FileName:string);
      procedure WriteData(data:array of Byte);
      procedure ReadData(var buffer:TTsdWaveOneBuffer; var ReadWord:Integer);overload;
      function ReadData(var buffer:TTsdWaveOneBufferSingle):Integer;overload;
      procedure Close;
    protected
      FPlaySize       : TTscWaveSize;
      FTotalReadSize  : TTscWaveSize;
      FTotalWriteSize : TTscWaveSize;
    published
      property WaveFormat : WAVEFORMATEXTENSIBLE read PCM;
      property PlaySize       : TTsrWaveSize read GetPlaySize;
      property TotalReadSize  : TTsrWaveSize read GetTotalReadSize;
      property TotalWriteSize : TTsrWaveSize read GetWriteSize;
  end;

implementation

procedure TTscWaveSize.Add(ByteSize:UInt32);
begin
  FSize.ByteSize  := FSize.ByteSize + ByteSize;
  FSize.SmallIntSize  := FSize.ByteSize div 2;
  FSize.SingleSize    := FSize.ByteSize div 4;
end;

constructor TTscWaveUtilsEx.Create;{( mode:TTseWaveUtilsMode;
                                    FileName:string;
                                    format:WAVEFORMATEXTENSIBLE);}
begin
  inherited Create;
  {
  FMode       := mode;
  FFileName   := FileName;
  case mode of
    WU_NEW  :
      begin
        PCM         := format;
        NewFileCreate;
      end;
    WU_OPEN :
      begin
        NewFileOpen;
      end;
  end;
  }
  FPlaySize       := TTscWaveSize.Create;
  FTotalReadSize  := TTscWaveSize.Create;
  FTotalWriteSize := TTscWaveSize.Create;
end;

destructor TTscWaveUtilsEx.Destroy;
begin
  inherited Destroy;
end;

procedure TTscWaveUtilsEx.NewFileCreate(FileName:string;format:WAVEFORMATEXTENSIBLE);
begin
  FFileName  := FileName;
  hIO := mmioOpen(PWideChar(FFileName), nil, MMIO_CREATE or MMIO_WRITE or MMIO_EXCLUSIVE);

  RIFF.fccType        := mmioStringToFOURCC('WAVE', 0);
  mmioCreateChunk(hIO, @RIFF, MMIO_CREATERIFF);

  FMT.ckid            := mmioStringToFOURCC('fmt', 0);
  mmioCreateChunk(hIO, @FMT, 0);
  //mmioCreateChunk(hIo, @KS, 0);
  //mmioWrite(hIO, @KS, SizeOf(KS));
  //PCM.SubFormat := KSDATAFORMAT_SUBTYPE_IEEE_FLOAT;
  //mmioWrite(hIO, @KS, SizeOf(KS));
  PCM := format;
  mmioWrite(hIO, @PCM, SizeOf(PCM));
  mmioAscend(hIO, @FMT, 0);

  DATA.ckid           := mmioStringToFOURCC('data', 0);
  mmioCreateChunk(hIO, @DATA, 0);
end;

procedure TTscWaveUtilsEx.NewFileOpen(FileName:string);
var
  MMres : MMRESULT;
  size  : UInt32;
begin
  FFileName :=FileName;
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

  FPlaySize.Add(data.cksize);
  //FPlaySize.ByteSize      := DATA.cksize;
  //FPlaySize.SmallIntSize  := FPlaySize.ByteSize div 2;
  //FPlaySize.SingleSize    := FPlaySize.ByteSize div 4;
  //FSampling               := PCM.nSamplesPerSec;
  //FCh                     := PCM.nChannels;
  //FBpS                    := PCM.wBitsPerSample;
end;

procedure TTscWaveUtilsEx.WriteData(data: array of Byte);
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
  FTotalWriteSize.Add(writed);
end;

procedure TTscWaveUtilsEx.ReadData(var buffer:TTsdWaveOneBuffer; var ReadWord:Integer);
var
  buf : TTsdWaveOneBufferBytes;
  I   : Integer;
begin
  ReadWord  := mmioRead(hIO, @buf, Length(buf));
  for I := 0 to Length(buffer) -1 do
    begin
      buffer[I] := (buf[I*2 +1] shl 8) + buf[I*2];
    end;
  FTotalReadSize.Add(ReadWord);
  //FTotalReadSize.ByteSize  := FTotalReadSize.ByteSize + ReadWord;
  //FTotalReadSize.SmallIntSize  := FTotalReadSize.ByteSize div 2;
  if ReadWord > 0 then ReadWord := ReadWord div 2;
end;

function TTscWaveUtilsEx.ReadData(var buffer:TTsdWaveOneBufferSingle):Integer;
var
  buf : TTsdWaveOneBufferBytes;
  I   : Integer;
  cash  : Single;
  bytes : array[0..3] of Byte absolute cash;
  X: Integer;
  ReadSingle  : Integer;
begin
  ReadSingle  := mmioRead(hIO, @buf, Length(buf));
  for I := 0 to Length(buffer) -1 do
    begin
      for X := 0 to Length(bytes) -1 do
          bytes[X]  := buf[I*4 +X];
      buffer[I] := cash;
    end;
  FTotalReadSize.Add(ReadSingle);
  //FTotalReadSize.ByteSize  := FTotalReadSize.ByteSize + ReadSingle;
  //FTotalReadSize.SmallIntSize  := FTotalReadSize.ByteSize div 2;
  //FTotalReadSize.SingleSize   := FTotalReadSize.ByteSize div 4;
  if ReadSingle > 0 then ReadSingle := ReadSingle div 4;
  Result  := ReadSingle;
end;

procedure TTscWaveUtilsEx.Close;
begin
  mmioAscend(hIO, @DATA, 0);
  mmioAscend(hIO, @RIFF, 0);
  mmioClose(hIO, 0);
end;

function TTscWaveUtilsEx.GetPlaySize:TTsrWaveSize;
begin
  Result  := FPlaySize.Size;
end;

function TTscWaveUtilsEx.GetTotalReadSize:TTsrWaveSize;
begin
  Result  := FTotalReadSize.Size;
end;

function TTscWaveUtilsEx.GetWriteSize:TTsrWaveSize;
begin
  Result  := FTotalWriteSize.Size;
end;

end.
