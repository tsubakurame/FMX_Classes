unit TsuD2XX;

interface
uses
  System.StrUtils, System.SysUtils,
  TsuFTDITypedefD2XX
  ;

type
  TTscD2XX  = class(TObject)
    public
      constructor Create;
      destructor Destroy;override;
      function CreateDeviceInfoList(lpdwNumDevs:PUint32):FT_STATUS;
      function GetDeviceInfoDetail(Index:UInt32;var lpdwFlags:UInt32; var lpdwType:FT_DEVICE;var lpdwID, lpdwLocId:UInt32; var pcSerialNumber:FT_SerialNumber;var pcDescription:FT_Description; var ftHandle:UInt32):FT_STATUS;
      function OpenEx(pvArg1:pointer; dwFlags:FT_OpenEx_Flags; var ftHandle:UInt32):FT_STATUS;
      function Close(ftHandle:UInt32):FT_STATUS;

      function EE_UASize(ftHandle:UInt32; var Size:UInt32):FT_STATUS;
      function EE_UARead(ftHandle:UInt32; var pucData:FT_pucData; var lpdwBytesRead:UInt32):FT_STATUS;
      function EE_UAWrite(ftHandle:UInt32; pucData:string):FT_STATUS;

      procedure GetDeviceIndex(var Index:Integer; Description:PAnsiChar);
  end;

{$region'    FTD2XX.dll Call    '}
function FT_CreateDeviceInfoList(NumDevs: Pointer): FT_STATUS; stdcall;
  External D2XX_DLL name 'FT_CreateDeviceInfoList' delayed;
function FT_GetDeviceInfoDetail(dwIndex:UInt32; lpdwFlagsl, lpdwType, lpdwID, lpdwLocId, pcSerialNumber, pcDescription, ftHandle:Pointer):FT_STATUS;stdcall;
  External D2XX_DLL name 'FT_GetDeviceInfoDetail' delayed;
function FT_OpenEx(pvArg1:pointer; dwFlags:FT_OpenEx_Flags; ftHandle:Pointer):FT_STATUS;stdcall;
  external D2XX_DLL name 'FT_OpenEx' delayed;
function FT_Close(ftHandle:UInt32):FT_STATUS;stdcall;
  external D2XX_DLL name 'FT_Close' delayed;

function FT_EE_UASize(ftHandle:UInt32; lpdwSize:PUint32):FT_STATUS; stdcall;
  External D2XX_DLL name 'FT_EE_UASize' delayed;
function FT_EE_UARead(ftHandle:UInt32; pucData:pointer; dwDataLen:UInt32; lpdwBytesRead:pointer):FT_STATUS;stdcall;
  external D2XX_DLL name 'FT_EE_UARead' delayed;
function FT_EE_UAWrite(ftHandle:UInt32; pucData:pointer; dwDataLen:UInt32):FT_STATUS;stdcall;
  external D2XX_DLL name 'FT_EE_UAWrite' delayed;

function FT_EEPROM_Read(ftHandle:UInt32; eepromData:pointer; eepromDataSize:UInt32; Manugacturer, ManufactureId, Description, SerialNumber:pointer):FT_STATUS;stdcall;
  external D2XX_DLL name 'FT_EEPROM_Read' delayed;
{$endregion}

implementation

constructor TTscD2XX.Create;
begin
  inherited Create;
end;

destructor TTscD2XX.Destroy;
begin
  inherited Destroy;
end;

function TTscD2XX.CreateDeviceInfoList(lpdwNumDevs: PUint32):FT_STATUS;
begin
  Result  := FT_CreateDeviceInfoList(lpdwNumDevs);
end;

function TTscD2XX.GetDeviceInfoDetail(Index: Cardinal; var lpdwFlags: UInt32; var lpdwType: FT_DEVICE;
                                      var lpdwID: Cardinal; var lpdwLocId: Cardinal;
                                      var pcSerialNumber: FT_SerialNumber; var pcDescription: FT_Description;
                                      var ftHandle: UInt32):FT_STATUS;
var
  handletemp: UInt32;
begin
  Result  := FT_GetDeviceInfoDetail(Index, @lpdwFlags, @lpdwType, @lpdwID, @lpdwLocId, @pcSerialNumber, @pcDescription, @handletemp);
end;

function TTscD2XX.EE_UASize(ftHandle: UInt32; var Size: Cardinal):FT_STATUS;
begin
  Result  := FT_EE_UASize(ftHandle, @Size);
end;

function TTscD2XX.OpenEx(pvArg1:pointer; dwFlags: FT_OpenEx_Flags; var ftHandle: Cardinal):FT_STATUS;
begin
  Result  := FT_OpenEx(pvArg1, dwFlags, @ftHandle);
end;

function TTscD2XX.Close(ftHandle: Cardinal):FT_STATUS;
begin
  Result  := FT_Close(ftHandle);
end;

function TTscD2XX.EE_UARead(ftHandle: Cardinal; var pucData:FT_pucData; var lpdwBytesRead: Cardinal):FT_STATUS;
//var
  //len : DWORD;
begin
  //len := SizeOf(pucData);
  Result  := FT_EE_UARead(ftHandle, @pucData, 44, @lpdwBytesRead);
end;

function TTscD2XX.EE_UAWrite(ftHandle: Cardinal; pucData: string):FT_STATUS;
var
  //buf : UCHAR;
  len : UInt32;
  //Encoding  : TEncoding;
  //buf : AnsiChar;
  pbuf : PAnsiChar;
begin
  //buf := AnsiChar(pucData);
  //buf := UCHAR(pucData);
  //Encoding  := TEncoding.GetEncoding('UTF-8');
  //len := Encoding.GetByteCount(pucData);
  //Result  := FT_EE_UAWrite(ftHandle, PUCHAR(pucData), len);
  len     := Length(pucData);
  //StrCopy(@buf, PAnsiChar(pucData));
  //StrPCopy(@buf, pucData);
  pbuf    := PAnsichar(AnsiString(pucData));
  Result  := FT_EE_UAWrite(ftHandle, pbuf, len);
end;

procedure TTscD2XX.GetDeviceIndex(var Index:Integer; Description: PAnsiChar);
//
//  指定されたDescriptionに該当するデバイスのIndexを返す関数
//  Indexが-1だった場合は、該当デバイスが存在しない
//  Indexが-2だった場合は、該当デバイスが複数存在する
//
var
  Num   : UInt32;
  I     : Integer;
  Flags : UInt32;
  Types : FT_DEVICE;
  ID,LocID,ftHandle : UInt32;
  Serial  : FT_SerialNumber;
  Descript: FT_Description;
  Count   : Integer;
  ds,gds  : string;
begin
  Count := 0;
  if CreateDeviceInfoList(@Num) = FT_OK then
    begin
      for I := 0 to Num -1 do
        begin
          if GetDeviceInfoDetail(I, Flags, Types, ID, LocID, Serial, Descript, ftHandle) = FT_OK then
            begin
              ds  := string(Description);
              gds := string(Descript);
              if ds = LeftStr(gds, Length(ds)) then
              //if Description^ = LeftStr(Descript, Length(Description^)) then
                begin
                  Index := I;
                  Inc(Count);
                end;
            end;
        end;
      if Count = 0 then
        begin
          Index := -1;
        end
      else if Count >= 2 then
        begin
          Index := -2;
        end;
    end
  else
    raise Exception.Create('例外発生');
end;
end.
