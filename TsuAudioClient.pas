unit TsuAudioClient;

interface
uses
  System.Classes, System.SysUtils,
  Winapi.Windows,
  Winapi.ActiveX,
  WinApi.CoreAudioApi.AudioClient,
  WinApi.CoreAudioApi.MMDeviceApi,
  WinApi.CoreAudioApi.AudioSessionTypes,
  WinApi.WinApiTypes,
  WinApi.WinMM.MMReg,
  WinApi.ActiveX.PropSys,
  WinApi.ActiveX.PropIdl,
  TsuWasapiBase
  ;

type
  TTscAudioClient = class(TTscWasapiBase)
    private
      wfx                       : PWAVEFORMATEXTENSIBLE;
      pwfx                      : PWAVEFORMATEXTENSIBLE;
      hnsRequestedDuration      : REFERENCE_TIME;
      bufferFrameCount          : UINT32;
      FShareMode                : AUDCLNT_SHAREMODE;
      FDefaultDevPeriod         : PREFERENCE_TIME;
      FMinumumDevPeriod         : PREFERENCE_TIME;
      FPeriod                   : REFERENCE_TIME;
      FDeviceList               : TStringList;
      FBufferSize               : Uint32;
      FStart                    : Boolean;
      function GetWaveFormat:WAVEFORMATEXTENSIBLE;
      procedure SetWaveFormat(format:WAVEFORMATEXTENSIBLE);
      function CreateInstance:HRESULT;
      function EnumAudioEndpoints:HRESULT;
      function Device_Active:HRESULT;
      procedure Activate;
      function AudioClient_GetMixFormat:HRESULT;
      function AudioClient_Initialize:HRESULT;
      function CheckFormatSupported:HRESULT;
      function AudioClient_GetBufferSize:HRESULT;
      function AudioClient_GetDevicePeriod:HRESULT;
    protected
      pEnumerator               : IMMDeviceEnumerator;
      pDevice                   : IMMDevice;
      FDeviceCollection         : IMMDeviceCollection;
      pAudioClient              : IAudioClient;
      function Enumerator_EnumAudioEndpoints:HRESULT; virtual; abstract;
      function Enumerator_GetDefaultAudioEndpoint:HRESULT; virtual; abstract;
      function AudioClient_GetService:HRESULT; virtual; abstract;
      //procedure HResultShowMess(hr:HRESULT; func:string);
      //procedure RaiseException(func, types, mess:String);
    public
      constructor Create;
      //  サウンドデバイスをアクティブにする
      //  引数なしの場合、既定のデバイスをアクティブにする
      procedure DeviceActivate;overload;
      procedure DeviceActivate(DeviceListIndex:Cardinal);overload;
      procedure DeviceActivate(DeviceName:string);overload;
      procedure Initialize;
      procedure GetCurrentPadding(var size:UInt32);
      procedure Start;
      procedure Stop;
    published
      property DeviceList : TStringList read FDeviceList;
      property WaveFormat : WAVEFORMATEXTENSIBLE read GetWaveFormat write SetWaveFormat;
      property ShareMode  : AUDCLNT_SHAREMODE read FShareMode write FShareMode;
      property BufferSize : Uint32 read bufferFrameCount;
      property Started  : Boolean read FStart;
  end;

const
  REFTIMES_PER_SEC  = 10000000;
  REFTIMES_PER_MILLISEC = 10000;
  PKEY_Device_FriendlyName: PROPERTYKEY = (fmtid: (D1:$a45c254e;
                                                    D2:$df1c;
                                                    D3:$4efd;
                                                    D4: ($80, $20, $67, $d1, $46, $a8, $50, $e0));
                                            pid:  14);

implementation

constructor TTscAudioClient.Create;
begin
  FShareMode  := AUDCLNT_SHAREMODE_SHARED;
  FDeviceList := TStringList.Create;
  HResultShowMess(CreateInstance, 'CreateInstance');
  HResultShowMess(EnumAudioEndpoints, 'EnumAudioEndpoints');
  FStart  := False;
end;

function TTscAudioClient.CreateInstance:HRESULT;
begin
  Result  := CoCreateInstance(CLSID_MMDeviceEnumerator, nil, CLSCTX_ALL, IMMDeviceEnumerator, pEnumerator);
end;

function TTscAudioClient.EnumAudioEndpoints:HRESULT;
var
  cnt : Cardinal;
  I: Cardinal;
  dev : IMMDevice;
  str : PWideChar;
  prop : IPropertyStore;
  varnamae  : PROPVARIANT;
begin
  FDeviceList.Clear;
  HResultShowMess(Enumerator_EnumAudioEndpoints, 'Enumerator_EnumAudioEndpoints');
  //Result  := pEnumerator.EnumAudioEndpoints(eRender, DEVICE_STATE_ACTIVE, FDeviceCollection);
  FDeviceCollection.GetCount(cnt);
  for I := 0 to cnt-1 do
    begin
      FDeviceCollection.Item(I,dev);
      dev.GetId(str);
      dev.OpenPropertyStore(STGM_READ, prop);
      PropVariantInit(varnamae);
      prop.GetValue(PKEY_Device_FriendlyName, varnamae);
      FDeviceList.Add(varnamae.pwszVal);
    end;
end;

function TTscAudioClient.Device_Active:HRESULT;
begin
  Result  := pDevice.Activate(IAudioClient, CLSCTX_ALL, nil, pAudioClient);
end;

procedure TTscAudioClient.DeviceActivate;
begin
  HResultShowMess(Enumerator_GetDefaultAudioEndpoint, 'Enumerator_GetDefaultAudioEndpoint');
  Activate;
end;

procedure TTscAudioClient.DeviceActivate(DeviceListIndex:Cardinal);
begin
  FDeviceCollection.Item(DeviceListIndex, pDevice);
  Activate;
end;

procedure TTscAudioClient.DeviceActivate(DeviceName:string);
var
  index : Integer;
begin
  if FDeviceList.Find(DeviceName, index) then
    begin
      FDeviceCollection.Item(index, pDevice);
      Activate;
    end
  else
    RaiseException('RenderStart', 'Audio Device is not found', '');
end;

procedure TTscAudioClient.Activate;
begin
  HResultShowMess(Device_Active,              'Device_Active');
  HResultShowMess(AudioClient_GetMixFormat,   'AudioClient_GetMixFormat');
  //HResultShowMess(pAudioClient.GetBufferSize(FBufferSize),'GetBufferSize');
end;

function TTscAudioClient.AudioClient_GetMixFormat:HRESULT;
begin
  Result  := pAudioClient.GetMixFormat(PWAVEFORMATEX(wfx));
end;

function TTscAudioClient.GetWaveFormat:WAVEFORMATEXTENSIBLE;
begin
  Result  := wfx^;
end;

procedure TTscAudioClient.SetWaveFormat(format:WAVEFORMATEXTENSIBLE);
begin
  wfx^  := format;
end;

function TTscAudioClient.AudioClient_Initialize:HRESULT;
begin
  Result  := pAudioClient.Initialize(FShareMode, 0, hnsRequestedDuration, FPeriod, PWAVEFORMATEX(wfx), nil);
end;

procedure TTscAudioClient.Initialize;
begin
  HResultShowMess(CheckFormatSupported,       'CheckFormatSupported');
  HResultShowMess(AudioClient_GetDevicePeriod,'AudioClient_GetDevicePeriod');
  HResultShowMess(AudioClient_Initialize,     'AudioClient_Initialize');
  HResultShowMess(AudioClient_GetBufferSize,  'AudioClient_GetBufferSize');
  HResultShowMess(AudioClient_GetService,     'AudioClient_GetService');
end;

function TTscAudioClient.CheckFormatSupported:HRESULT;
begin
  Result  := pAudioClient.IsFormatSupported(AUDCLNT_SHAREMODE_SHARED, PWAVEFORMATEX(wfx), PWAVEFORMATEX(pwfx));
end;

function TTscAudioClient.AudioClient_GetBufferSize;
begin
  Result  := pAudioClient.GetBufferSize(bufferFrameCount);
end;

function TTscAudioClient.AudioClient_GetDevicePeriod:HRESULT;
begin
  Result  := pAudioClient.GetDevicePeriod(FDefaultDevPeriod, FMinumumDevPeriod);
  FPeriod := FDefaultDevPeriod^;
end;

procedure TTscAudioClient.GetCurrentPadding(var size:UINT32);
var
  sz  : UINT32;
begin
  HResultShowMess(pAudioClient.GetCurrentPadding(sz), 'GetCurrentPadding');
  //if sz <> nil then
  size  := bufferFrameCount- sz;
end;

procedure TTscAudioClient.Start;
begin
  HResultShowMess(pAudioClient.Start, 'Start');
  FStart  := True;
end;

procedure TTscAudioClient.Stop;
begin
  HResultShowMess(pAudioClient.Stop, 'Stop');
  FStart  := False;
end;

end.
