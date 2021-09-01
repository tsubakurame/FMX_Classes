unit TsuAudioRender;

interface
uses
  WinApi.CoreAudioApi.AudioClient,
  WinApi.CoreAudioApi.MMDeviceApi,
  Winapi.WinApiTypes,
  TsuAudioClient
  ;

type
  TTscAudioRender = class(TTscAudioClient)
    private
      pRenderClient             : IAudioRenderClient;
      function Enumerator_EnumAudioEndpoints:HRESULT; override;
      function Enumerator_GetDefaultAudioEndpoint:HRESULT; override;
      function AudioClient_GetService:HRESULT; override;
    public
      constructor Create;
      procedure GetBuffer(NumFramesRequested: UInt32;out ppData:PByte);
      procedure ReleaseBuffer(const NumFramesWritten: UINT32; const dwFlags: UInt32);
  end;

implementation

constructor TTscAudioRender.Create;
begin
  inherited Create;
end;

function TTscAudioRender.Enumerator_EnumAudioEndpoints:HRESULT;
begin
  Result  := pEnumerator.EnumAudioEndpoints(eRender, DEVICE_STATE_ACTIVE, FDeviceCollection);
end;

function TTscAudioRender.Enumerator_GetDefaultAudioEndpoint:HRESULT;
begin
  Result  := pEnumerator.GetDefaultAudioEndpoint(eRender, eConsole, pDevice);
end;

function TTscAudioRender.AudioClient_GetService:HRESULT;
begin
  Result  := pAudioClient.GetService(IAudioRenderClient, pRenderClient);
end;

procedure TTscAudioRender.GetBuffer(NumFramesRequested: UInt32; out ppData:PByte);
begin
  HResultShowMess(pRenderClient.GetBuffer(NumFramesRequested, ppData), 'GetBuffer');
end;

procedure TTscAudioRender.ReleaseBuffer(const NumFramesWritten: UINT32; const dwFlags: UInt32);
begin
  HResultShowMess(pRenderClient.ReleaseBuffer(NumFramesWritten, dwFlags), 'ReleaseBuffer');
end;

end.
