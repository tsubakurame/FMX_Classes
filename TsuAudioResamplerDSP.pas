unit TsuAudioResamplerDSP;

interface
uses
  System.IOUtils,
  Winapi.Windows,
  //System.Win.ComObj,
  //Winapi.Windows,
  WinApi.Unknwn,
  //WinApi.ActiveX,
  WinApi.ActiveX.ObjBase,
  WinApi.ComBaseApi,
  WinApi.MediaFoundationApi.MfTransform,
  WinApi.MediaFoundationApi.wmCodecDsp,
  WinApi.MediaFoundationApi.MfApi,
  WinApi.MediaFoundationApi.MfObjects,
  WinApi.MediaFoundationApi.MfUtils,
  WinApi.MediaFoundationApi.Mferror,
  WinApi.MediaObj,
  WinApi.WinMM.MMReg,
  WinApi.WinApiTypes,
  TsuWasapiBase
  ;

type
  TTscAudioResamplerDSP = class(TTscWasapiBase)
    private
      spResamplerProps: IWMResamplerProps;
      info            : MFT_REGISTER_TYPE_INFO;
      info2           : MFT_REGISTER_TYPE_INFO;
      ppActivate      : PIMFActivate;
      pEncoder        : IMFTransform;
      count           : UInt32;
      pObject         : IMediaObject;
      ppCLSIDs        : PCLSID;
      spTransformUnk  : IMFTransform;
      pTransform      : IMFTransform;
      spBuffer        : IMFMediaBuffer;
      outputDataBuffer: PMFT_OUTPUT_DATA_BUFFER;

      pStreamInfoIn   : _MFT_INPUT_STREAM_INFO;
      pMediaTypeIn    : IMFMediaType;
      Fwfxin          : WAVEFORMATEXTENSIBLE;
      pSampleIn       : IMFSample;

      pStreamInfoOut  : _MFT_OUTPUT_STREAM_INFO;
      pMediaTypeOut   : IMFMediaType;
      FwfxOut         : WAVEFORMATEXTENSIBLE;
      pSampleOut      : IMFSample;

      bufferBytes     : UINT32;
      procedure SetWaveFormatOut(wfx:WAVEFORMATEXTENSIBLE);
      procedure SetWaveFormatIn(wfx:WAVEFORMATEXTENSIBLE);
      procedure SetMediaType(var pmType:IMFMediaType; wfx:WAVEFORMATEXTENSIBLE);
      function SetInput:Boolean;
    public
      constructor Create;
      procedure StartStream;
      function SetInputData(data:PBYTE; length:Integer):Boolean;
      function GetInputStatus:Boolean;
      function GetOutputData(out data:PBYTE; var length:DWORD):Boolean;
      function GetOutputStatus:Boolean;
      property InputWaveFormat  : WAVEFORMATEXTENSIBLE read FwfxIn write SetWaveFormatIn;
      property OutputWaveFormat : WAVEFORMATEXTENSIBLE read FwfxOut write SetWaveFormatOut;
  end;

implementation

constructor TTscAudioResamplerDsp.Create;
var
  I: Integer;
  hr  : HRESULT;
  inmin, inmax, outmin, outmax  : DWORD;
  incnt, outcnt : DWORD;
  pin, pout     : PDWORD;
begin
  try
    HResultShowMess(CoInitializeEx(nil, COINIT_APARTMENTTHREADED or COINIT_DISABLE_OLE1DDE),
                    'CoInitializeEx');
  finally
    HResultShowMess(MFStartup(MF_VERSION, MFSTARTUP_NOSOCKET),
                    'MFStartup');
    HResultShowMess(CoCreateInstance( CLSID_CResamplerMediaObject,
                                      nil,
                                      CLSCTX_INPROC_SERVER,
                                      IID_IUnknown,
                                      spTransformUnk),
                    'CoCreateInstance');
    HResultShowMess(spTransformUnk.QueryInterface(IID_IMFTransform, pTransform),
                    'QueryInterface');
    HResultShowMess(spTransformUnk.QueryInterface(IID_IWMResamplerProps, spResamplerProps),
                    'QueryInterface');
    HResultShowMess(spResamplerProps.SetHalfFilterLength(60),
                    'SetHalfFilterLength');
    pTransform.GetStreamLimits(inmin, inmax, outmin, outmax);
    ptransform.GetStreamCount(incnt, outcnt);
    //incnt := 0;
    //outcnt  := 0;
    new(outputDataBuffer);
    HResultShowMess(MFCreateSample(pSampleOut), 'MFCreateSample');
    hr  := pTransform.GetStreamIDs(incnt, pin, outcnt, pout);
    if hr = E_NOTIMPL then

  end;
end;

procedure TTscAudioResamplerDsp.SetWaveFormatIn(wfx:WAVEFORMATEXTENSIBLE);
begin
  Fwfxin  := wfx;
  SetMediaType(pMediaTypeIn, wfx);
  HResultShowMess(pTransform.SetInputType(0, pMediaTypeIn, 0),
                  'SetInputType');
  pTransform.GetInputStreamInfo(0, pStreamInfoIn);
end;

procedure TTscAudioResamplerDsp.SetWaveFormatOut(wfx:WAVEFORMATEXTENSIBLE);
var
  pMediaType      : IMFMediaType;
begin
  FwfxOut  := wfx;
  SetMediaType(pMediaTypeOut, wfx);
  HResultShowMess(pTransform.SetOutputType(0, pMediaTypeOut, 0),
                  'SetOutputType');
  pTransform.GetOutputStreamInfo(0, pStreamInfoOut);
end;

procedure TTscAudioResamplerDsp.SetMediaType(var pmType:IMFMediaType; wfx:WAVEFORMATEXTENSIBLE);
var
  format          : TGUID;
begin
  MFCreateMediaType(pmType);
  HResultShowMess(pmType.SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Audio),
                  'SetGUID');
  //  WaveFormatの指定
  case wfx.Format.wFormatTag of
    WAVE_FORMAT_PCM         : format  := MFAudioFormat_PCM;
    WAVE_FORMAT_EXTENSIBLE  :
      begin
        if wfx.SubFormat = KSDATAFORMAT_SUBTYPE_PCM then
          format  := MFAudioFormat_PCM
        else if wfx.SubFormat = KSDATAFORMAT_SUBTYPE_IEEE_FLOAT then
          format  := MFAudioFormat_Float
        else
          format  := MFAudioFormat_PCM;
      end
    else                      format  := MFAudioFormat_PCM;
  end;
  HResultShowMess(pmType.SetGUID(MF_MT_SUBTYPE, format),
                  'SetGUID');

  HResultShowMess(pmType.SetUINT32(MF_MT_AUDIO_NUM_CHANNELS, wfx.Format.nChannels),
                  'SetUINT32');
  HResultShowMess(pmType.SetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND, wfx.Format.nSamplesPerSec),
                  'SetUINT32');
  HResultShowMess(pmType.SetUINT32(MF_MT_AUDIO_BLOCK_ALIGNMENT, wfx.Format.nBlockAlign),
                  'SetUINT32');
  HResultShowMess(pmType.SetUINT32(MF_MT_AUDIO_AVG_BYTES_PER_SECOND, wfx.Format.nAvgBytesPerSec),
                  'SetUINT32');
  HResultShowMess(pmType.SetUINT32(MF_MT_AUDIO_BITS_PER_SAMPLE, wfx.Format.wBitsPerSample),
                  'SetUINT32');
  HResultShowMess(pmType.SetUINT32(MF_MT_ALL_SAMPLES_INDEPENDENT, 0),
                  'SetUINT32');
  if wfx.dwChannelMask <> 0 then
    HResultShowMess(pmType.SetUINT32(MF_MT_AUDIO_CHANNEL_MASK, wfx.dwChannelMask),
                    'SetUINT32');
  if wfx.Samples.wValidBitsPerSample <> wfx.Format.wBitsPerSample then
    HResultShowMess(pmType.SetUINT32(MF_MT_AUDIO_VALID_BITS_PER_SAMPLE, wfx.Samples.wValidBitsPerSample),
                    'SetUINT32');


end;

procedure TTscAudioResamplerDsp.StartStream;
var
  params  : NativeUInt;
begin
  {
  HResultShowMess(pTransform.ProcessMessage(MFT_MESSAGE_COMMAND_FLUSH, params),
                  'ProcessMessage');
  }
  HResultShowMess(pTransform.ProcessMessage(MFT_MESSAGE_NOTIFY_BEGIN_STREAMING, params),
                  'ProcessMessage');
  {
  HResultShowMess(pTransform.ProcessMessage(MFT_MESSAGE_NOTIFY_START_OF_STREAM, params),
                  'ProcessMessage');
  }
end;

function TTscAudioResamplerDsp.SetInputData(data:PBYTE; length:Integer):Boolean;
var
  pByteBufferTo : PBYTE;
  hr            : HRESULT;
  pBuffer       : IMFMediaBuffer;
begin
  HResultShowMess(MFCreateMemoryBuffer(length, pBuffer),
                  'MFCreateMemoryBuffer');
  HResultShowMess(pBuffer.Lock(pByteBufferTo, nil, nil),
                  'Lock');
  CopyMemory(pByteBufferTo, data, length);
  HResultShowMess(pBuffer.Unlock, 'Unlock');

  HResultShowMess(pBuffer.SetCurrentLength(length), 'SetCurrentLength');

  HResultShowMess(MFCreateSample(pSampleIn), 'MFCreateSample');
  HResultShowMess(pSampleIn.AddBuffer(pBuffer), 'AddBuffer');
  SafeRelease(pBuffer);
  //FreeMem(pByteBufferTo);
  //bufferBytes := bufferBytes + length;
  Result  := SetInput;
  //pSampleOut.AddBuffer(pBuffer);
  outputDataBuffer^.dwStreamID  := 0;
  outputDataBuffer^.dwStatus    := 0;
  outputDataBuffer^.pSample     := nil;

  pTransform.GetOutputStreamInfo(0, pStreamInfoOut);
  if ((pStreamInfoOut.dwFlags and MFT_OUTPUT_STREAM_WHOLE_SAMPLES) > 0) then
  //(pStreamInfoOut.dwFlags = MFT_OUTPUT_STREAM_PROVIDES_SAMPLES) or
  //(pStreamInfoOut.dwFlags = MFT_OUTPUT_STREAM_CAN_PROVIDE_SAMPLES) then
    begin
      outputDataBuffer^.pSample     := nil;
    end
  else
    begin
      outputDataBuffer^.pSample := pSampleOut;
      MFCreateMemoryBuffer(pStreamInfoOut.cbSize, pBuffer);
      //MFCreateMemoryBuffer(1056, pBuffer);
      outputDataBuffer^.pSample.AddBuffer(pBuffer);
      //outputDataBuffer^.pSample.ConvertToContiguousBuffer(pBuffer);
    end;
end;

function TTscAudioResamplerDsp.SetInput:Boolean;
var
  hr  : HRESULT;
  data  : PByte;
begin
  hr  := pTransform.ProcessInput(0, pSampleIn, 0);
  case hr of
    S_OK              : Result  := True;
    MF_E_NOTACCEPTING : Result  := False;
    else                Result  := False;
  end;
end;

function TTscAudioResamplerDsp.GetInputStatus:Boolean;
var
  flag  : UINT32;
begin
  HResultShowMess(pTransform.GetInputStatus(0, flag), 'GetInputStatus');
  Result  := flag = MFT_INPUT_STATUS_ACCEPT_DATA;
end;

function TTscAudioResamplerDsp.GetOutputData(out data:PBYTE; var length:DWORD):Boolean;
var
  state         : UINT32;
  hr            : HRESULT;
  pByteBuffer   : PBYTE;
  incnt, outcnt : uint32;
  dwflag  : DWORD;
  pBuffer       : IMFMediaBuffer;
begin
  if True then
    begin

      hr  := pTransform.ProcessOutput(0, 1, outputDataBuffer, state);
      //outputDataBuffer^.dwStatus = MFT_OUTPUT_DATA_BUFFER_INCOMPLETE
      if (hr = S_OK) then
        begin
          HResultShowMess(outputDataBuffer.pSample.GetTotalLength(length),
                          'GetTotalLength');
          HResultShowMess(MFCreateMemoryBuffer(length, spBuffer),
                          'MFCreateMemoryBuffer');
          HResultShowMess(outputDataBuffer.pSample.CopyToBuffer(spBuffer),
                          'CopyToBuffer');
          HResultShowMess(spBuffer.Lock(pByteBuffer, nil, nil), 'Lock');
          GetMem(data, length);
          CopyMemory(data, pByteBuffer, length);
          HResultShowMess(spBuffer.Unlock, 'Unlock');
          Result  := True;
        end
      else if hr = MF_E_TRANSFORM_NEED_MORE_INPUT then
        begin
          Result  := False;
        end
      else
        begin
          HResultShowMess(hr, 'ProcessOutput');
          Result  := False;
        end;
    end;
end;

function TTscAudioResamplerDSP.GetOutputStatus:Boolean;
var
  hr            : HRESULT;
  dwflag  : DWORD;
begin
  hr  := pTransform.GetOutputStatus(dwflag);
  if hr = E_NOTIMPL then
  case hr of
    S_OK  :
      begin
        case dwflag of
          MFT_OUTPUT_STATUS_SAMPLE_READY  : Result  := False;
          else                              Result  := True;
        end;
      end;
    E_NOTIMPL : Result  := True;
    else        Result  := False;
  end;
end;

end.
