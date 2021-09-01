unit TsuSoftwareLicenseManager;

interface

uses
  System.SysUtils, System.JSON.Serializers, System.Classes, System.DateUtils, System.Generics.Collections,
  System.JSON.Converters, System.Types, System.IOUtils,
  IdHTTP, IdSSLOpenSSL, IdSSLOpenSSLHeaders,
  TsuLicenseCodeEncorder, TsuPathUtilsFMX,
  ScSSLClient
  ;

const
  OPERATION_TYPE_SCAN   = 'SCAN';
  OPERATION_TYPE_PUT    = 'PUT';
  OPERATION_TYPE_QUERY  = 'QUERY';
  LIMIT_DATE_ARRAY      : array[0..7] of string = ( 'Forever',  '1 month',  '6 months',
                                                    '1 year',   '2 years',  '3 years',
                                                    '4 years',  '5 years');
  LICENSE_FILE_EXT      = '.flcd';
  JSON_FILE_EXT         = '.json';

type
  TTseLimitPeriod = ( LD_FOREVER,
                      LD_MONTH,
                      LD_6MONTH,
                      LD_YEAR,
                      LD_2YEAR,
                      LD_3YEAR,
                      LD_4YEAR,
                      LD_5YEAR);
  TTseLicenseStatus = ( LC_STATUS_CHECKING,
                        LC_STATUS_AUTHENTICATE,
                        LC_STATUS_OK,
                        LC_STATUS_WRONG,
                        LC_STATUS_LIMIT_OUT,
                        LC_STATUS_CODE_DUPLICATE,
                        LC_STATUS_USED,
                        LC_NETWORK_DISCONECT,
                        LC_STATUS_EXCEPTION,
                        LC_NOT_OPEN_SSL_LIB,
                        LC_STATUS_UNAUTHENTICATED,
                        LC_STATUS_UNAUTHENTICATED_FILE_BREAK,
                        LC_STATUS_RETURN_ERROR);
  TTseAuthState = (AS_STATUS_LOCAL, AS_STATUS_NETWORK, AS_STATUS_AUTHENTICATED, AS_STATUS_ERROR);
  TTseLicenseCheckStep  = ( LCP_LOCAL_CHECK,
                            LCP_DECODE,
                            LCP_UNAUTHENTICATED,
                            LCP_POST_SERVER,
                            LCP_JSON_DECODE,
                            LCP_LOCAL_JSON_READ,
                            LCP_ITEMS_COUNT,
                            LCP_CHECK_PERIOD,
                            LCP_CHECK_LIMIT,
                            LCP_SAVE_FILES,
                            LCP_LOCAL_FILE_BREAK);

  TTseLicenseManagerMode  = ( LM_MODE_CHECKER, LM_MODE_MASTAR);

  TTsrLicenseData = record
    FPCode      : string;
    LicenseCode : string;
    Used        : Boolean;
    RegistDate  : TDateTime;
    LimitDate   : TDateTime;
    LimitPeriod : Integer;
  end;
  TTsrPostMessage = record
    OperationType : string;
    Keys          : TTsrLicenseData;
  end;
  TTsrHTTPHeaders = record
    server            : string;
    date              : string;
    [JsonName('content-type')]
    content_type      : string;
    [JsonName('content-length')]
    content_length    : string;
    connection        : string;
    [JsonName('x-amzn-requestid')]
    x_amzn_requestid  : string;
  end;
  TTsrResponseMetadata = record
    RequestId       : String;
    HTTPStatusCode  : Integer;
    HTTPHeaders     : TTsrHTTPHeaders;
  end;
  TTsrResponseMessage = record
    Items : TArray<TTsrLicenseData>;
    Count : Integer;
    ScannedCount  : Integer;
    ResponseMetadata  : TTsrResponseMetadata;
  end;
  TTsrCheckStepStatus = record
    Step    : TTseLicenseCheckStep;
    Status  : TTseLicenseStatus;
    Auth    : TTseAuthState;
  end;
  TTsdNotifyEvent = procedure(Sender:TObject; ErrorCode:TTseLicenseStatus) of object;
  //TTsdAuthNotifyEvent = procedure(Sender:TObject; var SerialCode) of object;

  TTscSoftwareLicenseManager = class(TObject)
    private
      Fhttp : TIdHTTP;
      Fssl  : TIdSSLIOHandlerSocketOpenSSL;
      FLicenseCode  : string;
      FFPCode       : string;
      FLicenseEnable: Boolean;
      FSSLdllPath   : string;
      FURL          : string;
      FEncorder     : TTscLicenseCodeEncorder;
      FLimitPeriod  : TTseLimitPeriod;
      FRegistDate   : TDateTime;
      FLimitDate    : TDateTime;
      FAppdataPath  : string;
      FOnCodeDisable  : TTsdNotifyEvent;
      FOnCodeEnable   : TNotifyEvent;
      FOnUnauthenticated  : TTsdNotifyEvent;
      FAuthState      : TTseAuthState;
      FState          : TTsrCheckStepStatus;
      FLicenseData    : TTsrLicenseData;
      FSSLClient      : TScSSLClient;
      FOnlineAuth     : Boolean;
      procedure SetSSLdllPath(path:string);
      procedure SetAppdataPath(path:string);

      procedure Authenticate;
      procedure CheckLocalfile( var state : TTsrCheckStepStatus;
                                var json:string;
                                path:string);

      procedure CalcLimitDate;
      function Post(params:TTsrPostMessage):string;
      procedure jsonDecode( var state : TTsrCheckStepStatus;
                            var data:TTsrResponseMessage;
                            json:string);
      procedure Decode( var state : TTsrCheckStepStatus);
      procedure PostServer( var state : TTsrCheckStepStatus;
                            var json:string);
      procedure CheckDuplicate( var state : TTsrCheckStepStatus;
                                data:TTsrResponseMessage);
      procedure CheckPeriod(var state : TTsrCheckStepStatus;
                            data:TTsrResponseMessage);
      procedure CheckLimit( var state : TTsrCheckStepStatus;
                            data:TTsrResponseMessage);
      procedure NewCodeCreate;
      procedure SetEvent(state : TTsrCheckStepStatus);
      procedure SetNotifyEvent(event : TNotifyEvent);
      procedure SetNotifyEventWithState(event : TTsdNotifyEvent);
      procedure LoadLicenseFile(path:string);
      procedure LoadJsonFile(var state:TTsrCheckStepStatus; var json:string);
      function GetKey(str:string):Byte;
      procedure SaveFiles(var state:TTsrCheckStepStatus ;json:string);
      procedure LoadCompositeFile(var data:string; path:string);
      procedure SaveEncryptFile(data, ext:string);
      Function GetFileList(ext:string):TStringDynArray;
      procedure FileDelete;
      procedure LocalFileBreak(var state:TTsrCheckStepStatus);
    protected
    public
      constructor Create;
      destructor Destroy;override;
      procedure CheckAuthenticated;
      procedure Add;
    published
      property LicenseCode    : string read FLicenseCode write FLicenseCode;
      property FPCode         : string read FFPCode write FFPCode;
      property LicenseEnable  : Boolean read FLicenseEnable;
      property SSLdllPath     : string read FSSLdllPath write SetSSLdllPath;
      property LimitPeriod    : TTseLimitPeriod read FLimitPeriod write FLimitPeriod;
      property AppDataPath    : string read FAppdataPath write SetAppdataPath;
      property LicenseStatus  : TTseLicenseStatus read FState.status;
      property AuthStatus     : TTseAuthState read FAuthState;
      property LicenseData    : TTsrLicenseData read FLicenseData;
      property OnlineAuth     : Boolean read FOnlineAuth write FOnlineAuth;

      property OnCodeDisable  : TTsdNotifyEvent read FOnCodeDisable write FOnCodeDisable;
      property OnAuthenticated : TNotifyEvent read FOnCodeEnable write FOnCodeEnable;
      property OnUnauthenticated  : TTsdNotifyEvent read FOnUnauthenticated write FOnUnauthenticated;
  end;

implementation

{$region'    public Method    '}
constructor TTscSoftwareLicenseManager.Create;
//(app_data_path:string; mode:TTseLicenseManagerMode = LM_MODE_CHECKER);
begin
  Fhttp := TIdHTTP.Create(nil);
  Fssl  := TIdSSLIOHandlerSocketOpenSSL.Create(Fhttp);
  FSSLClient  := TScSSLClient.Create(nil);
  FEncorder := TTscLicenseCodeEncorder.Create;

  Fhttp.Request.ContentType   := 'application/json';
  Fhttp.Request.CharSet       := 'utf-8';
  Fhttp.IOHandler             := Fssl;

  Fssl.SSLOptions.Method      := sslvSSLv23;
  Fssl.SSLOptions.SSLVersions := [sslvSSLv2,sslvSSLv3,sslvTLSv1,sslvTLSv1_1,sslvTLSv1_2];

  FURL  := 'https://2zz9a3bchh.execute-api.ap-northeast-1.amazonaws.com/FrientechLicenseManager';
  FState.Step   := LCP_LOCAL_CHECK;
  FAuthState    := AS_STATUS_LOCAL;
  FOnlineAuth   := True;
end;

destructor TTscSoftwareLicenseManager.Destroy;
begin
  Fhttp.Free;
//  Fssl.Free;
  FSSLClient.Free;
  FEncorder.Free;
end;

procedure TTscSoftwareLicenseManager.CheckAuthenticated;
begin
  TThread.CreateAnonymousThread(
    procedure()
      begin
        Authenticate;
      end
  ).Start;
end;

procedure TTscSoftwareLicenseManager.Add;
var
  params  : TTsrPostMessage;
  res     : string;
  flag    : Boolean;
begin
  flag  := False;
  while not flag do
    begin
      NewCodeCreate;
      params.OperationType    := OPERATION_TYPE_QUERY;
      params.Keys.FPCode      := FFPCode;
      params.Keys.LicenseCode := FLicenseCode;
      if Post(params) = 'null' then
        begin
          params.OperationType    := OPERATION_TYPE_PUT;
          params.Keys.FPCode      := FFPCode;
          params.Keys.LicenseCode := FLicenseCode;
          params.Keys.Used        := False;
          CalcLimitDate;
          params.Keys.RegistDate  := FRegistDate;
          params.Keys.LimitDate   := FLimitDate;
          params.Keys.LimitPeriod := Ord(FLimitPeriod);
          res := Post(params);
          flag  := True;
        end;
    end;
end;
{$endregion}

{$region'    Property Method    '}
procedure TTscSoftwareLicenseManager.SetSSLdllPath(path:string);
begin
  FSSLdllPath := ExcludeTrailingBackslash(path);
  IdOpenSSLSetLibPath(FSSLdllPath);
end;

procedure TTscSoftwareLicenseManager.SetAppdataPath(path:string);
begin
  if Pos('license', path) <= 0 then
    path  := IncludeTrailingBackslash(path) + 'license';
  if not DirectoryExists(path) then
    ForceDirectories(path);
  FAppdataPath  := path;
end;
{$endregion}

procedure TTscSoftwareLicenseManager.Authenticate;
var
  json    : string;
  data    : TTsrResponseMessage;
begin
  FState.Status := LC_STATUS_CHECKING;
  while FState.Status = LC_STATUS_CHECKING do
    begin
      try
        case FState.Step of
          LCP_LOCAL_CHECK     : CheckLocalfile(FState, json, FAppdataPath);
          LCP_DECODE          : Decode(FState);
          LCP_UNAUTHENTICATED : ;
          LCP_POST_SERVER     : PostServer(FState, json);
          LCP_LOCAL_JSON_READ : LoadJsonFile(FState ,json);
          LCP_JSON_DECODE     : jsonDecode(FState, data, json);
          LCP_ITEMS_COUNT     : CheckDuplicate(FState, data);
          LCP_CHECK_PERIOD    : CheckPeriod(FState, data);
          LCP_CHECK_LIMIT     : CheckLimit(FState, data);
          LCP_SAVE_FILES      : SaveFiles(FState, json);
          LCP_LOCAL_FILE_BREAK: LocalFileBreak(FState);
        end;
      except
        FState.Status  := LC_STATUS_EXCEPTION;
      end;
    end;
  SetEvent(FState);
end;

procedure TTscSoftwareLicenseManager.CheckLocalfile( var state : TTsrCheckStepStatus;
                                                    var json:string;
                                                    path:string);
var
  FileNames : TStringDynArray;
begin
  if FAppdataPath <> '' then
    begin
      FileNames := GetFileList(LICENSE_FILE_EXT);
      //  ローカルにライセンスコードファイルが存在するか
      if Length(FileNames) = 1 then
        begin
          //  ライセンスコードファイルを読み込み復号する
          LoadLicenseFile(FileNames[0]);
          FState.Step := LCP_DECODE;
          FAuthState  := AS_STATUS_LOCAL;
        end
      else if Length(FileNames) > 1 then
        state.Step  := LCP_LOCAL_FILE_BREAK
      else
        begin
          state.Status  := LC_STATUS_UNAUTHENTICATED; //  ステータスを未認証にし、OnUnauthenticatedを発生させる
          state.Step    := LCP_DECODE;                //  ステップをデコードへ（ライセンスコードの入力待ち）
          FAuthState    := AS_STATUS_NETWORK;         //  認証ステータスをネットワークへ
          FileDelete;
        end;
    end
  else
    raise Exception.Create('Appdata path is not assign');
end;

function TTscSoftwareLicenseManager.GetFileList(ext:string):TStringDynArray;
begin
  Result  := TDirectory.GetFiles(FAppdataPath, '*'+ext);
end;

procedure TTscSoftwareLicenseManager.FileDelete;
var
  filename :string;
  FileNames : TStringDynArray;
begin
  FileNames := TDirectory.GetFiles(FAppdataPath);
  for filename in FileNames do
    DeleteFile(filename);
end;

procedure TTscSoftwareLicenseManager.Decode(var state : TTsrCheckStepStatus);
var
  flag  : Boolean;
begin
  flag  := True;
  if Length(FLicenseCode) = 16 then
    begin
      FEncorder.LicenseCode := FLicenseCode;
      flag  := FEncorder.Decode;
    end
  else  flag  := False;

  if flag then
    begin
      if FOnlineAuth then
        state.Step  := LCP_POST_SERVER
      else
        state.Step  := LCP_SAVE_FILES;
    end
  else
    begin
      if FAuthState = AS_STATUS_LOCAL then
        state.Step    := LCP_LOCAL_FILE_BREAK //  ローカル認証の場合、ファイル破損状態へ
      else
        state.Status  := LC_STATUS_WRONG;     //  ネットワーク認証の場合、コードミス扱い
    end;
end;

procedure TTscSoftwareLicenseManager.PostServer(var state : TTsrCheckStepStatus;
                                                var json:string);
var
  params : TTsrPostMessage;
begin
  try
    params.OperationType    := OPERATION_TYPE_QUERY;
    params.Keys.FPCode      := FFPCode;
    params.Keys.LicenseCode := FLicenseCode;
    json                    := Post(params);
    state.Step              := LCP_JSON_DECODE;
  except
    on E:EIdOSSLCouldNotLoadSSLLibrary do state.Status  := LC_NOT_OPEN_SSL_LIB
    else state.Status := LC_NETWORK_DISCONECT;
    state.Step  := LCP_DECODE;
    if FAuthState = AS_STATUS_LOCAL then
      begin
        state.Status := LC_STATUS_CHECKING;
        state.Step   := LCP_LOCAL_JSON_READ;
      end;
  end;
end;

procedure TTscSoftwareLicenseManager.CheckDuplicate(var state : TTsrCheckStepStatus;
                                                    data:TTsrResponseMessage);
begin
  if data.Count = 1 then
    begin
      state.Step    := LCP_CHECK_PERIOD;
      FLicenseData  := data.Items[0];
    end
  else
    begin
      if FAuthState = AS_STATUS_LOCAL then
        state.Step  := LCP_LOCAL_FILE_BREAK
      else
        state.Status  := LC_STATUS_CODE_DUPLICATE;
    end;
end;

procedure TTscSoftwareLicenseManager.jsonDecode(var state : TTsrCheckStepStatus;
                                                var data:TTsrResponseMessage;
                                                json:string);
var
  desi  : TJsonSerializer;
begin
  try
    desi        := TJsonSerializer.Create;
    data        := desi.Deserialize<TTsrResponseMessage>(json);
    state.Step  := LCP_ITEMS_COUNT;
  except
    state.Step  := LCP_LOCAL_FILE_BREAK;
  end;
end;

procedure TTscSoftwareLicenseManager.NewCodeCreate;
begin
  FLicenseCode  := FEncorder.CodeCreate;
end;

procedure TTscSoftwareLicenseManager.CalcLimitDate;
begin
  FRegistDate := now;
  case FLimitPeriod of
    LD_FOREVER  : FLimitDate  := FRegistDate;
    LD_MONTH    : FLimitDate  := IncMonth(FRegistDate);
    LD_6MONTH   : FLimitDate  := IncMonth(FRegistDate, 6);
    LD_YEAR     : FLimitDate  := IncYear(FRegistDate);
    LD_2YEAR    : FLimitDate  := IncYear(FRegistDate, 2);
    LD_3YEAR    : FLimitDate  := IncYear(FRegistDate, 3);
    LD_4YEAR    : FLimitDate  := IncYear(FRegistDate, 4);
    LD_5YEAR    : FLimitDate  := IncYear(FRegistDate, 5);
  end;
end;

function TTscSoftwareLicenseManager.Post(params:TTsrPostMessage):string;
var
  strm  : TStringStream;
  res   : string;
  json  : TJsonSerializer;
begin
  json  := TJsonSerializer.Create;
  res := json.Serialize(params);
  strm  := TStringstream.Create(UTF8Encode(res));
  Result  := Fhttp.Post(FURL, strm);
  strm.Free;
  json.Free;
end;


procedure TTscSoftwareLicenseManager.CheckPeriod( var state : TTsrCheckStepStatus;
                                                  data:TTsrResponseMessage);
begin
  case TTseLimitPeriod(data.Items[0].LimitPeriod) of
    LD_FOREVER  :
      begin
        if FAuthState = AS_STATUS_NETWORK then
          state.Step  := LCP_SAVE_FILES
        else
          state.Status  := LC_STATUS_OK
      end;
    LD_MONTH,
    LD_6MONTH,
    LD_YEAR,
    LD_2YEAR,
    LD_3YEAR,
    LD_4YEAR,
    LD_5YEAR    : state.Step  := LCP_CHECK_LIMIT;
    else
      begin
        if FAuthState = AS_STATUS_LOCAL then
          state.Step  := LCP_LOCAL_FILE_BREAK
        else
          state.Status  := LC_STATUS_RETURN_ERROR;
      end;
  end;
end;

procedure TTscSoftwareLicenseManager.CheckLimit(var state : TTsrCheckStepStatus;
                                                data:TTsrResponseMessage);
begin
  if data.Items[0].LimitDate > now then
    begin
      if FAuthState = AS_STATUS_NETWORK then
        state.Step  := LCP_SAVE_FILES
      else
        state.Status  := LC_STATUS_OK
    end
  else
    state.Status  := LC_STATUS_LIMIT_OUT;
end;

procedure TTscSoftwareLicenseManager.LoadLicenseFile(path:string);
begin
  LoadCompositeFile(FLicenseCode, path);
end;

procedure TTscSoftwareLicenseManager.LoadJsonFile(var state:TTsrCheckStepStatus; var json:string);
var
  FileNames : TStringDynArray;
begin
  FileNames := TDirectory.GetFiles(FAppdataPath, '*'+JSON_FILE_EXT);
  if Length(FileNames) = 1 then
    begin
      LoadCompositeFile(json, FileNames[0]);
      state.Step  := LCP_JSON_DECODE;
    end
  else
    state.Step  := LCP_LOCAL_FILE_BREAK;
end;

procedure TTscSoftwareLicenseManager.LoadCompositeFile(var data:string; path:string);
var
  stream  : TBytesStream;
  key     : Byte;
  I: Integer;
  code  : string;
begin
  stream  := TBytesStream.Create;
  stream.LoadFromFile(path);
  key := GetKey(path);
  code  := '';
  for I := 0 to stream.Size -1 do
    begin
      stream.Bytes[I] := stream.Bytes[I] xor key;
      code  := code + String(Char(Stream.Bytes[I]));
    end;
  data  := code;
  stream.Free;
end;

function TTscSoftwareLicenseManager.GetKey(str:string):Byte;
var
  strm  : TStringStream;
  I: Integer;
begin
  strm  := TStringStream.Create;
  strm.WriteString(str);
  Result  := 0;
  for I := 0 to strm.Size -1 do
    Result  := Result xor strm.Bytes[I];
  strm.Free;
end;

procedure TTscSoftwareLicenseManager.SaveFiles(var state:TTsrCheckStepStatus ;json:string);
var
  FileNames : TStringDynArray;
begin
  FileNames := GetFileList(LICENSE_FILE_EXT);
  if Length(FileNames) = 0 then
    SaveEncryptFile(FLicenseCode, LICENSE_FILE_EXT);
  FileNames := GetFileList(JSON_FILE_EXT);
  if Length(FileNames) = 0 then
    SaveEncryptFile(json, JSON_FILE_EXT);
  state.Status  := LC_STATUS_OK;
end;

procedure TTscSoftwareLicenseManager.SaveEncryptFile(data, ext:string);
var
  guid    : TGUID;
  stream  : TStringStream;
  filename  : string;
  key     : Byte;
  I : Integer;
begin
  stream  := TStringStream.Create;
  stream.WriteString(data);
  CreateGUID(guid);
  filename  := GUIDToString(guid);
  filename  := StringReplace(filename, '{', '', [rfReplaceAll]);
  filename  := StringReplace(filename, '}', '', [rfReplaceAll]);
  filename  := IncludeTrailingBackslash(FAppdataPath)+filename+ext;
  key := GetKey(filename);
  for I := 0 to stream.Size -1 do
    stream.Bytes[I] := stream.Bytes[I] xor key;
  stream.SaveToFile(filename);
  stream.Free;
end;

procedure TTscSoftwareLicenseManager.SetEvent(state:TTsrCheckStepStatus);
begin
  case state.Status of
    LC_STATUS_CHECKING        : ;
    LC_STATUS_OK              : SetNotifyEvent(FOnCodeEnable);
    //LC_STATUS_WRONG           : ;
    //LC_STATUS_LIMIT_OUT       : ;
    //LC_STATUS_CODE_DUPLICATE  : ;
    //LC_STATUS_USED            : ;
    //LC_NETWORK_DISCONECT      : ;
    //LC_STATUS_EXCEPTION       : ;
    //LC_NOT_OPEN_SSL_LIB       : ;
    LC_STATUS_UNAUTHENTICATED,
    LC_STATUS_UNAUTHENTICATED_FILE_BREAK  : SetNotifyEventWithState(FOnUnauthenticated);
    LC_STATUS_RETURN_ERROR    : SetNotifyEventWithState(FOnCodeDisable);
    else                        SetNotifyEventWithState(FOnCodeDisable);
  end;
end;

procedure TTscSoftwareLicenseManager.SetNotifyEvent(event:TNotifyEvent);
begin
  if Assigned(event) then
    TThread.Queue(nil, procedure begin event(Self) end);
end;

procedure TTscSoftwareLicenseManager.SetNotifyEventWithState(event : TTsdNotifyEvent);
begin
  if Assigned(event) then
    TThread.Queue(nil, procedure begin event(Self, FState.Status) end);
end;

procedure TTscSoftwareLicenseManager.LocalFileBreak(var state:TTsrCheckStepStatus);
begin
  state.Status  := LC_STATUS_UNAUTHENTICATED_FILE_BREAK;  //  ステータスを未認証にし、OnUnauthenticatedを発生させる
  state.Step    := LCP_DECODE;                //  ステップをデコードへ（ライセンスコードの入力待ち）
  FAuthState    := AS_STATUS_NETWORK;         //  認証ステータスをネットワークへ
  FileDelete;
end;

end.
