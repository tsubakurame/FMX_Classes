unit TsuMediaPlayer;

interface
uses
  System.Types, System.Math, System.Classes, System.SysUtils,
  FMX.Objects, FMX.Graphics, FMX.StdCtrls,
  WinApi.WinMM.MMReg,
  WinApi.WinApiTypes,
  TsuFrameRateTimer, TsuThread, TsAVIUtilsEx, TsuAudioRender,
  TsuAudioResamplerDSP
  ;

type
  TTseMediaType = (MTYPE_UNKNOWN, MTYPE_WAVE, MTYPE_AVI);
  TTsePlayerState = ( PLAY_STATE_FILECHECK,
                      PLAY_STATE_FILEOPEN,
                      PLAY_STATE_WAIT_TIMER);
  TTsrMediaPlayerThreadParams = record
    FileList  : TStringList;
    Image     : TImage;
    TrackBar  : TTrackBar;
  end;
  TTscMediaPlayerThread = class(TTscThread)
    private
      FFileList   : TStringList;
      FTimer      : TTscFrameRateTimer;
      FFileIndex  : Integer;
      FMediaType  : TTseMediaType;
      FState      : TTsePlayerState;
      FAVI        : TTsAVIUtilsEX;
      FSeekDC     : Integer;
      FSeekWB     : Integer;
      FImage      : TImage;
      FAudioRender: TTscAudioRender;
      DSP         : TTscAudioResamplerDSP;
      FCashBuffer : array of Byte;
      FCashCnt    : integer;
      FTrackBar   : TTrackBar;

      procedure Initialize;override;
      procedure ThreadMain;override;
      procedure DeInitialize;override;
      procedure FileCheck;
      procedure FileOpen;
      procedure OpenAVI;
      procedure SetFormat(wfx:WAVEFORMATEX);
      procedure WaitTimer;
      procedure ReadAVIImage;
      procedure ReadAVISound;
      procedure TrackBarChange;
    public
      constructor Create(params:TTsrMediaPlayerThreadParams);
  end;
  TTscMediaPlayer = class(TObject)
    private
      procedure SetImage(img:TImage);
      procedure ImageResize(Sender:TObject);
      procedure SetImageSize;

      procedure SetPlayButton(btn:TSpeedButton);
      procedure OnPlayClick(Sender:TObject);

      procedure SetStopButton(btn:TSpeedButton);
      procedure OnStopClick(Sender:TObject);

      procedure SetTrackBar(bar:TTrackBar);

      procedure ExecutePlayThread;
    protected
      FImage        : TImage;
      FBitmap       : TBitmap;
      FFileList     : TStringList;

      FPlayButton   : TSpeedButton;
      FStopButton   : TSpeedButton;
      FPauseButton  : TSpeedButton;

      FFileIndex    : UInt32;
      FPlayThread   : TTscMediaPlayerThread;
      FTrackBar     : TTrackBar;
    public
      constructor Create;
      destructor Destroy;

      procedure Play;
      procedure Stop;

      //  外部コンポーネントとの紐づけ
      property VideoImage : TImage read FImage write SetImage;
      property PlayButton : TSpeedButton read FPlayButton write SetPlayButton;
      property StopButton : TSpeedButton read FStopButton write SetSTopButton;
      property TrackBar   : TTrackBar read FTrackBar write SetTrackBar;

      property FileList   : TStringList read FFileList write FFileList;
      property FileIndex  : UInt32 read FFileIndex write FFileIndex;
  end;

implementation

{$region'    TTscMediaPlayerThread    '}
constructor TTscMediaPlayerThread.Create(params:TTsrMediaPlayerThreadParams);
begin
  FFileList := TStringList.Create;
  FFileList := params.FileList;
  FTimer    := TTscFrameRateTimer.Create;
  FFileIndex:= 0;
  //FBitmap   := TBitmap.Create;
  FImage    := params.Image;
  FAudioRender  := TTscAudioRender.Create;
  DSP       := TTscAudioResamplerDSP.Create;
  FTrackBar := params.TrackBar;
  inherited Create;
end;

procedure TTscMediaPlayerThread.Initialize;
begin
  FAudioRender.DeviceActivate;
end;

procedure TTscMediaPlayerThread.Deinitialize;
begin
  FAudioRender.Free;
  FAVI.Free;
  DSP.Free;
end;

procedure TTscMediaPlayerThread.ThreadMain;
begin
  case FState of
    PLAY_STATE_FILECHECK  : FileCheck;
    PLAY_STATE_FILEOPEN   : FileOpen;
    PLAY_STATE_WAIT_TIMER : WaitTimer;
  end;
end;

procedure TTscMediaPlayerThread.FileCheck;
var
  ext : string;
begin
  if FFileIndex < FFileList.Count then
    begin
      ext := ExtractFileExt(FFileList[FFileIndex]);
      ext := LowerCase(ext);
      if ext = '.wav' then
        FMediaType  := MTYPE_WAVE
      else if ext = '.avi' then
        FMediaType  := MTYPE_AVI
      else
        FMediaType  := MTYPE_UNKNOWN;
      FState  := PLAY_STATE_FILEOPEN;
    end
  else
    begin

    end;
end;

procedure TTscMediaPlayerThread.FileOpen;
begin
  case FMediaType of
    MTYPE_UNKNOWN : ;
    MTYPE_WAVE    : ;
    MTYPE_AVI     : OpenAVI;
  end;
end;

procedure TTscMediaPlayerThread.OpenAVI;
var
  wfxt  : WAVEFORMATEXTENSIBLE;
begin
  FAVI          := TTsAVIUtilsEX.Create(FFileList[FFileIndex]);
  FAVI.HeaderRead;
  FTimer.Rate   := FAVI.Header.hdrl.strl_vids.strh.dwRate;
  FTimer.Scale  := FAVI.Header.hdrl.strl_vids.strh.dwScale;
  FState        := PLAY_STATE_WAIT_TIMER;
  wfxt.Format := FAVI.Header.hdrl.strl_auds.strf.wfx;
  wfxt.dwChannelMask  := 0;
  wfxt.Samples.wValidBitsPerSample  := wfxt.Format.wBitsPerSample;
  //wfxt.Format.cbSize  := SizeOf(WAVEFORMATEXTENSIBLE) - SizeOf(WAVEFORMATEX);
  FAudioRender.Initialize;
  DSP.InputWaveFormat   := wfxt;
  DSP.OutputWaveFormat  := FAudioRender.WaveFormat;
  DSP.StartStream;
  FTimer.Start;
end;

procedure TTscMediaPlayerThread.SetFormat(wfx:WAVEFORMATEX);
var
  wfx_cash  : WAVEFORMATEX;
begin
  wfx_cash  := wfx;
  if (wfx.nSamplesPerSec <> 44100) and (wfx.nSamplesPerSec <> 48000) then
    begin
    end;
end;

procedure TTscMediaPlayerThread.WaitTimer;
begin
  if FTimer.Event.WaitFor(0) = wrSignaled then
    begin
      ReadAVIImage;
    end;
  ReadAVISound;
end;

procedure TTscMediaPlayerThread.ReadAVIImage;
var
  memst : TMemoryStream;
  size  : UInt32;
  read_size : UInt16;
  buf   : array [0..Uint16.MaxValue] of Byte;
  FBitmap     : TBitmap;
begin
  FBitmap := TBitmap.Create;
  memst := TMemoryStream.Create;
  size    := FAVI.Header.idx1.idx_00dc[FSeekDC].dwChunkLength;
  FAVI.StreamSeekBeginning(FAVI.moviOffset);
  FAVI.StreamSeekCurrent(FAVI.Header.idx1.idx_00dc[FSeekDC].dwChunkOffset + 4);
  while size > 0 do
    begin
      if size > UInt16.MaxValue then
        read_size := UInt16.MaxValue
      else
        read_size := size;
      FAVI.StreamRead_Variable(buf, read_size);
      memst.Write(buf, read_size);
      size  := size - read_size;
    end;
  memst.Seek(0, soFromBeginning);
  FBitmap.LoadFromStream(memst);
  memst.Free;

  Synchronize(nil, procedure  begin
                                FImage.Bitmap.Canvas.BeginScene;
                                FImage.Bitmap.Canvas.DrawBitmap(FBitmap,
                                                                TRectF.Create(0,0,FBitmap.Width, FBitmap.Height),
                                                                TRectF.Create(0,0,FImage.Width, FImage.Height),
                                                                1.0);
                                FImage.Bitmap.Canvas.EndScene;
                              end);
  FBitmap.Free;
  Inc(FSeekDC);
end;

procedure TTscMediaPlayerThread.ReadAVISound;
var
  ArSize    : UInt32;   //  AudioRenderの入力バッファサイズ
  ArSizeC   : UInt32;   //  AudioRenderの入力バッファサイズキャッシュ
  pArData   : PByte;    //  AudioRender入力バッファの開始アドレス
  chk_size  : Uint32;   //  チャンクサイズ
  buf       : array of Byte;  //  元Waveデータ
  outdata   : PByte;    //  変換後Waveデータ
  OutLength : DWORD;    //  変換後Waveデータ長
  I: Integer;
  stpidx  : Integer;
  cv_buf  : array of Variant;
  flags   : DWORD;
  cash_idx  : Integer;
  cash_to   : Integer;
begin
  FAudioRender.GetCurrentPadding(ArSize);
  if ArSize <> 0 then
    begin
      FAudioRender.GetBuffer(ArSize, pArData);
      ArSizeC := ArSize * FAudioRender.WaveFormat.Format.nBlockAlign;
      while ArSizeC > 0 do
        begin
          if dsp.GetInputStatus then
            begin
              chk_size  := FAVI.Header.idx1.idx_01wb[FSeekWB].dwChunkLength;
              FAVI.StreamSeekBeginning(FAVI.moviOffset);
              FAVI.StreamSeekCurrent(FAVI.Header.idx1.idx_01wb[FSeekWB].dwChunkOffset + 4);
              SetLength(buf, chk_size);
              FAVI.StreamRead_Variable(buf, chk_size);
              if DSP.SetInputData(PByte(buf), Length(buf)) then
                inc(FSeekWB);
            end;
          if DSP.GetOutputStatus then
            begin
              DSP.GetOutputData(outdata, OutLength);
              for I := 0 to OutLength -1 do
                begin
                  pArData^  := outdata^;
                  inc(pArData);
                  inc(outdata);
                  Dec(ArSizeC);
                end;
              Dec(outdata, OutLength);
            end;
        end;
      FAudioRender.ReleaseBuffer(ArSize, 0);
      if not FAudioRender.Started then FAudioRender.Start;
    end;
end;

procedure TTscMediaPlayerThread.TrackBarChange;
begin

end;
{$endregion}

{$region'    TTscMediaPlayer    '}
constructor TTscMediaPlayer.Create;
begin
  FImage      := nil;
  FPlayButton := nil;
  FBitmap     := TBitmap.Create;
  FFileList   := TStringList.Create;
  FPlayThread := nil;
  FFileIndex  := 0;
end;

destructor TTscMediaPlayer.Destroy;
begin
  FBitmap.Free;
end;

procedure TTscMediaPlayer.SetImage(img:TImage);
begin
  FImage  := img;
  SetImageSize;
  FImage.OnResize := ImageResize;
end;

procedure TTscMediaPlayer.ImageResize(Sender:TObject);
begin
  SetImageSize;
end;

procedure TTscMediaPlayer.SetImageSize;
begin
  FBitmap.SetSize(Floor(FImage.Width), Floor(FImage.Height));
  FImage.Bitmap.SetSize(FBitmap.Size);
end;

procedure TTscMediaPlayer.SetPlayButton(btn:TSpeedButton);
begin
  FPlayButton := btn;
  FPlayButton.OnClick := OnPlayClick;
end;

procedure TTscMediaPlayer.OnPlayClick(Sender:TObject);
begin
  Play;
end;

procedure TTscMediaPlayer.Play;
var
  params  : TTsrMediaPlayerThreadParams;
begin
  if FFileList.Count > 0 then
    begin
      if Assigned(FPlayButton) then
        FPlayButton.Enabled := False;
      if not Assigned(FPlayThread) then
        begin
          params.FileList := TStringList.Create;
          params.FileList := FFileList;
          params.Image    := FImage;
          FPlayThread := TTscMediaPlayerThread.Create(params);
        end;
    end;
end;

procedure TTscMediaPlayer.SetStopButton(btn:TSpeedButton);
begin
  FStopButton := btn;
  FStopButton.OnClick := OnStopClick;
end;

procedure TTScMediaPlayer.OnStopClick(Sender:TObject);
begin
  Stop;
end;

procedure TTscMediaPlayer.Stop;
begin
  if Assigned(FStopButton) then
    FPlayButton.Enabled := True;
  if Assigned(FPlayThread) then
    begin
      FPlayThread.Terminate;
      FreeAndNil(FPlayThread);
    end;
end;

procedure TTscMediaPlayer.ExecutePlayThread;
begin

end;

procedure TTscMediaPlayer.SetTrackBar(bar:TTrackBar);
begin
  FTrackBar := bar;
end;
{$endregion}

end.
