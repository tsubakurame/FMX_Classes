unit TsuWasapiBase;

interface
uses
  System.SysUtils,
  Winapi.Windows, Winapi.ActiveX,
  WinApi.CoreAudioApi.AudioClient,
  WinApi.CoreAudioApi.MMDeviceApi,
  WinApi.MediaFoundationApi.Mferror
  ;

type
  TTscWasapiBase  = class(TObject)
    protected
      procedure HResultShowMess(hr:HRESULT; func:string);
      procedure RaiseException(func, types, mess:String);
  end;

implementation

procedure TTscWasapiBase.RaiseException(func, types, mess:String);
begin
  raise Exception.Create(func +#13#10+ types + #13#10 + mess);
end;

procedure TTscWasapiBase.HResultShowMess(hr:HRESULT; func:string);
var
  hresult_str : string;
begin
  case hr of
    S_OK                          : Exit;
    S_FALSE                       : Exit;// := 'S_FALSE';
    REGDB_E_CLASSNOTREG           : hresult_str := 'REGDB_E_CLASSNOTREG';
    CLASS_E_NOAGGREGATION         : hresult_str := 'CLASS_E_NOAGGREGATION';
    E_NOINTERFACE                 : hresult_str := 'E_NOINTERFACE';
    E_POINTER                     : hresult_str := 'E_POINTER';
    E_INVALIDARG                  : hresult_str := 'E_INVALIDARG';
    E_NOTFOUND                    : hresult_str := 'E_NOTFOUND';
    E_OUTOFMEMORY                 : hresult_str := 'E_OUTOFMEMORY';
    E_UNEXPECTED                  : hresult_str := 'E_UNEXPECTED';
    AUDCLNT_E_DEVICE_INVALIDATED  : hresult_str := 'AUDCLNT_E_DEVICE_INVALIDATED';
    AUDCLNT_S_BUFFER_EMPTY        : hresult_str := 'AUDCLNT_S_BUFFER_EMPTY';
    AUDCLNT_E_BUFFER_ERROR        : hresult_str := 'AUDCLNT_E_BUFFER_ERROR';
    AUDCLNT_E_OUT_OF_ORDER        : hresult_str := 'AUDCLNT_E_OUT_OF_ORDER';
    AUDCLNT_E_BUFFER_OPERATION_PENDING
                                  : hresult_str := 'AUDCLNT_E_BUFFER_OPERATION_PENDING';
    AUDCLNT_E_SERVICE_NOT_RUNNING : hresult_str := 'AUDCLNT_E_SERVICE_NOT_RUNNING';
    AUDCLNT_E_INVALID_SIZE        : hresult_str := 'AUDCLNT_E_INVALID_SIZE';
    AUDCLNT_E_BUFFER_SIZE_ERROR   : hresult_str := 'AUDCLNT_E_BUFFER_SIZE_ERROR';
    AUDCLNT_E_NOT_INITIALIZED     : hresult_str := 'AUDCLNT_E_NOT_INITIALIZED';
    CO_E_NOTINITIALIZED           : hresult_str := 'CO_E_NOTINITIALIZED';
    MF_E_INVALIDMEDIATYPE         : hresult_str := 'MF_E_INVALIDMEDIATYPE';
    MF_E_INVALIDSTREAMNUMBER      : hresult_str := 'MF_E_INVALIDSTREAMNUMBER';
    MF_E_TRANSFORM_TYPE_NOT_SET   : hresult_str := 'MF_E_TRANSFORM_TYPE_NOT_SET';
    MF_E_TRANSFORM_CANNOT_CHANGE_MEDIATYPE_WHILE_PROCESSING
                                  : hresult_str := 'MF_E_TRANSFORM_CANNOT_CHANGE_MEDIATYPE_WHILE_PROCESSING';
    MF_E_TRANSFORM_NEED_MORE_INPUT: hresult_str := 'MF_E_TRANSFORM_NEED_MORE_INPUT';
    MF_E_TRANSFORM_STREAM_CHANGE  : hresult_str := 'MF_E_TRANSFORM_STREAM_CHANGE';
    MF_E_UNSUPPORTED_D3D_TYPE     : hresult_str := 'MF_E_UNSUPPORTED_D3D_TYPE';
    MF_E_NO_SAMPLE_DURATION       : hresult_str := 'MF_E_NO_SAMPLE_DURATION';
    MF_E_NO_SAMPLE_TIMESTAMP      : hresult_str := 'MF_E_NO_SAMPLE_TIMESTAMP';
    MF_E_NOTACCEPTING             : hresult_str := 'MF_E_NOTACCEPTING';
    else                            hresult_str := 'unkown';
  end;
  RaiseException(func, hresult_str, '');
end;

end.
