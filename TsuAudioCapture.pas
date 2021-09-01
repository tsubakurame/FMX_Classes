unit TsuAudioCapture;

{$region'    ReadMe    '}
  {
  WASAPIを使用したサウンドデバイスから音声データをキャプチャするクラス

  インスタンスをメインスレッドではなく、別スレッドから生成する場合
  スレッドのコンストラクタで生成する必要がある。
      ー  エラーコード：CO_E_NOTINITIALIZEDの発生
  }
{$endregion}

interface
uses
  System.SysUtils, System.Generics.Collections, System.Classes,
  Winapi.ShlObj,
  Winapi.Windows,
  Winapi.ActiveX,
  WinApi.CoreAudioApi.MMDeviceApi,
  WinApi.CoreAudioApi.AudioClient,
  WinApi.CoreAudioApi.AudioSessionTypes,
  WinApi.WinApiTypes,
  WinApi.WinMM.MMReg,
  WinApi.ActiveX.PropSys,
  WinApi.ActiveX.PropIdl
  ;

type
  TTsdMethod  = function:HRESULT;
  PTTsdMethod = ^TTsdMethod;
  TTsdByteArray = array of Byte;
  TTscAudioCapture = class(TObject)
    private
      IID_IMMDeviceEnumerator   : IID;
      pEnumerator               : IMMDeviceEnumerator;
      pDevice                   : IMMDevice;
      pAudioClient              : IAudioClient;
      hnsRequestedDuration      : REFERENCE_TIME;
      pwfx                      : PWAVEFORMATEXTENSIBLE;
      pCaptureClient            : IAudioCaptureClient;
      bufferFrameCount          : UINT32;
      numFramesAvailable        : UINT32;
      flags                     : DWORD;
      pu64DevicePosition        : UInt64;
      pu64QPCPosition           : UInt64;
      hnsActualDuration         : REFERENCE_TIME;
      FDeviceCollection         : IMMDeviceCollection;
      FDeviceList               : TStringList;
      procedure HResultShowMess(hr:HRESULT; func:string);
      procedure RaiseException(func, types, mess:String);
      function CreateInstance:HRESULT;
      function Enumerator_GetDefaultAudioEndpoint:HRESULT;
      function Device_Active:HRESULT;
      function AudioClient_GetMixFormat:HRESULT;
      function AudioClient_Initialize:HRESULT;
      function AudioClient_GetBufferSize:HRESULT;
      function AudioClient_GetService:HRESULT;
      procedure ReleaseBuffer;
      function GetWaveFormat:WAVEFORMATEXTENSIBLE;
      function EnumAudioEndpoints:HRESULT;
      procedure Activate;
    public
      //  コンストラクタ　ReadMe参照
      constructor Create;
      //  サウンドデバイスをアクティブにする
      //  引数なしの場合、既定のデバイスをアクティブにする
      procedure DeviceActivate;overload;
      procedure DeviceActivate(DeviceListIndex:Cardinal);overload;
      procedure DeviceActivate(DeviceName:string);overload;
      procedure CaptureStart;
      procedure GetNextPacketSize(var packetLength : UINT32);
      procedure GetBuffer(var data:TTsdByteArray);
      procedure CaptureStop;
      procedure waitSleep;
      procedure GetDeviceList;
    published
      property WaveFormat : WAVEFORMATEXTENSIBLE read GetWaveFormat;
      property DeviceList : TStringList read FDeviceList;
      //property DeviceCollection : IMMDeviceCollection read FDeviceCollection;
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

constructor TTscAudioCapture.Create;
begin
  FDeviceList := TStringList.Create;
  HResultShowMess(CreateInstance, 'CreateInstance');
  HResultShowMess(EnumAudioEndpoints, 'EnumAudioEndpoints');
end;

procedure TTscAudioCapture.RaiseException(func, types, mess:String);
begin
  raise Exception.Create(func +#13#10+ types + #13#10 + mess);
end;

procedure TTscAudioCapture.HResultShowMess(hr:HRESULT; func:string);
var
  hresult_str : string;
begin
  case hr of
    S_OK                          : Exit;
    REGDB_E_CLASSNOTREG           : hresult_str := 'REGDB_E_CLASSNOTREG';
    CLASS_E_NOAGGREGATION         : hresult_str := 'CLASS_E_NOAGGREGATION';
    E_NOINTERFACE                 : hresult_str := 'E_NOINTERFACE';
    E_POINTER                     : hresult_str := 'E_POINTER';
    E_INVALIDARG                  : hresult_str := 'E_INVALIDARG';
    E_NOTFOUND                    : hresult_str := 'E_NOTFOUND';
    E_OUTOFMEMORY                 : hresult_str := 'E_OUTOFMEMORY';
    AUDCLNT_E_DEVICE_INVALIDATED  : hresult_str := 'AUDCLNT_E_DEVICE_INVALIDATED';
    AUDCLNT_S_BUFFER_EMPTY        : hresult_str := 'AUDCLNT_S_BUFFER_EMPTY';      
    AUDCLNT_E_BUFFER_ERROR        : hresult_str := 'AUDCLNT_E_BUFFER_ERROR';
    AUDCLNT_E_OUT_OF_ORDER        : hresult_str := 'AUDCLNT_E_OUT_OF_ORDER';
    AUDCLNT_E_BUFFER_OPERATION_PENDING        : hresult_str := 'AUDCLNT_E_BUFFER_OPERATION_PENDING';     
    AUDCLNT_E_SERVICE_NOT_RUNNING        : hresult_str := 'AUDCLNT_E_SERVICE_NOT_RUNNING';
    CO_E_NOTINITIALIZED           : hresult_str := 'CO_E_NOTINITIALIZED';
    else                            hresult_str := 'unkown';
  end;             
  RaiseException(func, hresult_str, '');
end;

function TTscAudioCapture.CreateInstance:HRESULT;
begin
  Result  := CoCreateInstance(CLSID_MMDeviceEnumerator, nil, CLSCTX_ALL, IMMDeviceEnumerator, pEnumerator);
end;

function TTscAudioCapture.EnumAudioEndpoints:HRESULT;
var
  cnt : Cardinal;
  I: Cardinal;
  dev : IMMDevice;
  str : PWideChar;
  prop : IPropertyStore;
  varnamae  : PROPVARIANT;
begin
  FDeviceList.Clear;
  Result  := pEnumerator.EnumAudioEndpoints(eCapture, DEVICE_STATE_ACTIVE, FDeviceCollection);
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

function TTscAudioCapture.Enumerator_GetDefaultAudioEndpoint:HRESULT;
begin
  Result  := pEnumerator.GetDefaultAudioEndpoint(eCapture, eConsole, pDevice);
end;

function TTscAudioCapture.Device_Active:HRESULT;
begin
  Result  := pDevice.Activate(IAudioClient, CLSCTX_ALL, nil, pAudioClient);
end;

function TTscAudioCapture.AudioClient_GetMixFormat:HRESULT;
begin
  Result  := pAudioClient.GetMixFormat(PWAVEFORMATEX(pwfx));
end;

function TTscAudioCapture.AudioClient_Initialize;
begin
  Result  := pAudioClient.Initialize(AUDCLNT_SHAREMODE_SHARED, 0, hnsRequestedDuration, 0, @pwfx.Format, nil);
end;

function TTscAudioCapture.AudioClient_GetBufferSize;
begin
  Result  := pAudioClient.GetBufferSize(bufferFrameCount);
end;

function TTscAudioCapture.AudioClient_GetService:HRESULT;
begin
  Result  := pAudioClient.GetService(IAudioCaptureClient, pCaptureClient);
end;

procedure TTscAudioCapture.Activate;
begin
  HResultShowMess(Device_Active,              'Device_Active');
  HResultShowMess(AudioClient_GetMixFormat,   'AudioClient_GetMixFormat');
  HResultShowMess(AudioClient_Initialize,     'AudioClient_Initialize');
  HResultShowMess(AudioClient_GetBufferSize,  'AudioClient_GetBufferSize');
  HResultShowMess(AudioClient_GetService,     'AudioClient_GetService');
end;

procedure TTscAudioCapture.DeviceActivate;
begin
  HResultShowMess(Enumerator_GetDefaultAudioEndpoint, 'Enumerator_GetDefaultAudioEndpoint');
  Activate;
end;

procedure TTscAudioCapture.DeviceActivate(DeviceListIndex:Cardinal);
begin
  FDeviceCollection.Item(DeviceListIndex, pDevice);
  Activate;
end;

procedure TTscAudioCapture.DeviceActivate(DeviceName:string);
var
  index : Integer;
begin
  if FDeviceList.Find(DeviceName, index) then
    begin
      FDeviceCollection.Item(index, pDevice);
      Activate;
    end
  else
    RaiseException('CaptureStart', 'Audio Device is not found', '');
end;

procedure TTscAudioCapture.CaptureStart;
begin
  HResultShowMess(pAudioClient.Start,         'CaptureStart');
end;

procedure TTscAudioCapture.GetNextPacketSize(var packetLength:UINT32);
begin
  try
    HResultShowMess(pCaptureClient.GetNextPacketSize(packetLength), 'GetNextPacketSize');
  finally

  end;
end;

procedure TTscAudioCapture.GetBuffer(var data:TTsdByteArray);
var
  I: Integer;
  val : Int32;
  buf : PByte;
begin
  try
    HResultShowMess(pCaptureClient.GetBuffer( buf,
                                              numFramesAvailable,
                                              flags,
                                              pu64DevicePosition,
                                              pu64QPCPosition),
                    'GetBuffer');
    SetLength(data, numFramesAvailable*pwfx.Format.nBlockAlign);
    //CopyMemory(data, buf, numFramesAvailable*pwfx.Format.nBlockAlign);

    for I := 0 to (numFramesAvailable*pwfx.Format.nBlockAlign) -1 do
      begin
        data[I] := buf^;
        inc(buf);
      end;

    ReleaseBuffer;
  finally

  end;
end;

procedure TTscAudioCapture.ReleaseBuffer;
begin
  HResultShowMess(pCaptureClient.ReleaseBuffer(numFramesAvailable), 'ReleaseBuffer');
end;

procedure TTscAudioCapture.CaptureStop;
begin
  HResultShowMess(pAudioClient.Stop, 'CaptureStop');
end;

procedure TTscAudioCapture.waitSleep;
begin
  sleep(hnsActualDuration div REFTIMES_PER_MILLISEC div 2);
end;

function TTscAudioCapture.GetWaveFormat:WAVEFORMATEXTENSIBLE;
begin
  Result  := pwfx^;
end;

procedure TTscAudioCapture.GetDeviceList;
begin
  HResultShowMess(EnumAudioEndpoints, 'EnumAudioEndpoints');
end;

end.
