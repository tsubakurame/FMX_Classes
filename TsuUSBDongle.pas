unit TsuUSBDongle;

interface
uses
  System.StrUtils, System.SysUtils, System.UITypes,
  TsuMessageDlgFMX,
  TsuD2XX, TsuFTDITypedefD2XX
  ;

type
  TTscUSBDongle = class(TObject)
    private
      D2XX                : TTscD2XX;
      FProductCode        : string;
      //FDongleSerial       : string;
      {$HINTS OFF}
      FDongleDescription  : string;
      {$HINTS ON}
      //FDebugMode          : Boolean;
      FReadProductCode    : string;
      FReadDummyCode      : string;
      FReadLotNo          : string;
      FReadSerialNo       : string;
      FReadEditionCode    : string;
      FReadPassCode       : string;
      FWriteDummyCode     : string;
      FWriteLotNo         : string;
      FWriteSerialNo      : string;
      FWriteEditionCode   : string;
      FWritePassCode      : string;
      FWriteAnsCode       : string;

      WriteKeyCodeByte    : Array[0..23] of Byte;
      WriteAnsCodeByte    : Array[0..23] of Byte;
      WritePassCodeByte   : Array[0..23] of Byte;
      WriteKeyCodeChar    : Array[0..23] of Char;
      WriteAnsCodeChar    : Array[0..23] of Char;
      WritePassCodeChar   : Array[0..23] of Char;
    public
      constructor Create;
      destructor Destroy;override;

      function GetDongleCode:UInt32;overload;
      procedure GetDongleCode(serial:PAnsiChar);overload;
      procedure CodeCreate;
      procedure SetDongleCode(serial:PAnsiChar);

      property ProductCode      : string read FProductCode write FProductCode;
      //property DongleSerial     : string read FDongleSerial write FDongleSerial;
      //property DebugMode        : Boolean read FDebugMode write FDebugMode default False;

      property ReadProductCode  : string read FReadProductCode;
      property ReadDummyCode    : string read FReadDummyCode;
      property ReadEditionCode  : string read FReadEditionCode;
      property ReadPassCode     : string read FReadPassCode;
      property ReadLotNo        : string read FReadLotNo;
      property ReadSerialNo     : string read FReadSerialNo;

      property WriteDummyCode   : string read FWriteDummyCode write FWriteDummyCode;
      property WriteLotNo       : string read FWriteLotNo write FWriteLotNo;
      property WriteSerialNo    : string read FWriteSerialNo write FWriteSerialNo;
      property WriteEditionCode : string read FWriteEditionCode write FWriteEditionCode;
      property WriteAnsCode     : string read FWriteAnsCode;
      property WritePassCode    : string read FWritePassCode;
  end;
const
  KEY_CODE          = 'FRIENTECH_USB_Dongle_Key';
  Key_Description   = 'USB Dongle ';

implementation

constructor TTscUSBDongle.Create;
begin
  inherited Create;
  D2XX      := TTscD2XX.Create;
end;

destructor TTscUSBDongle.Destroy;
begin
  inherited Destroy;
  D2XX.Free;
end;

function TTscUSBDongle.GetDongleCode:UInt32;
var
  pc          : PAnsiChar;
  ftHandle    : UInt32;
  pucData     : FT_pucData;
  BytesRead   : UInt32;
  Index       : Integer;
  PassCode    : Array[0..23] of Byte;
  KeyCode     : Array[0..23] of Byte;
  Decode      : Array[0..23] of Byte;
  DecodeChar  : Array[0..23] of Char;
  PassCodeChar : Array[0..23] of Char;
  I: Integer;
  //decodeStr   : string;
begin
  pc := PAnsiChar(Ansistring(Key_Description + FProductCode));
  D2XX.GetDeviceIndex(Index,pc);
  if not Index < 0 then
    begin
      if D2XX.OpenEx(pc, FT_OPEN_BY_DESCRIPTION, ftHandle) = FT_OK then
        begin
          if D2XX.EE_UARead(ftHandle, pucData, BytesRead) = FT_OK then
            begin
              for I := 0 to 23 do
                begin
                  KeyCode[I]      := Ord(KEY_CODE[I+1]);
                  PassCode[I]     := Ord(pucData[I]);
                  PassCodeChar[I] := Char(PassCode[I]);
                  Decode[I]       := KeyCode[I] xor PassCode[I];
                  DecodeChar[I]   := Char(Decode[I]);
                end;
              FReadProductCode  := LeftStr(DecodeChar, 4);
              FReadDummyCode    := MidStr(DecodeChar, 5, 4);
              FReadLotNo        := MidStr(DecodeChar, 9, 4);
              FReadSerialNo     := MidStr(DecodeChar, 13, 8);
              FReadEditionCode  := RightStr(DecodeChar, 4);
              FReadPassCode     := string(PassCodeChar);
              Result  := 0;
            end
          else
            Result  := 1;
            //MessageDlg('USB Dongle EEPROM Read Error', mtError, [mbOK],0);
          D2XX.Close(ftHandle);
        end
      else
        Result  := 2;
        //MessageDlg('USB Dongle Open Error', mtError, [mbOK],0);
    end
  else
    Result  := 3;
    //MessageDlg('USB Dongle is Not Found', mtError, [mbOK],0);
  //Result  := StrToIntDef(FReadEditionCode,0);
end;

procedure TTscUSBDongle.GetDongleCode(serial: PAnsiChar);
var
  ftHandle    : UInt32;
  pucData     : FT_pucData;
  BytesRead   : UInt32;
  PassCode    : Array[0..23] of Byte;
  KeyCode     : Array[0..23] of Byte;
  Decode      : Array[0..23] of Byte;
  DecodeChar  : Array[0..23] of Char;
  PassCodeChar : Array[0..23] of Char;
  I: Integer;
begin
  if D2XX.OpenEx(serial, FT_OPEN_BY_SERIAL_NUMBER, ftHandle) = FT_OK then
    begin
      if D2XX.EE_UARead(ftHandle, pucData, BytesRead) = FT_OK then
        begin
          for I := 0 to 23 do
            begin
              KeyCode[I]      := Ord(KEY_CODE[I+1]);
              PassCode[I]     := Ord(pucData[I]);
              PassCodeChar[I] := Char(PassCode[I]);
              Decode[I]       := KeyCode[I] xor PassCode[I];
              DecodeChar[I]   := Char(Decode[I]);
            end;
          FReadProductCode  := LeftStr(DecodeChar, 4);
          FReadDummyCode    := MidStr(DecodeChar, 5, 4);
          FReadLotNo        := MidStr(DecodeChar, 9, 4);
          FReadSerialNo     := MidStr(DecodeChar, 13, 8);
          FReadEditionCode  := RightStr(DecodeChar, 4);
          FReadPassCode     := string(PassCodeChar);
        end
      else
        raise Exception.Create('USB Dongle EEPROM Read Error');
        //MessageDlg('USB Dongle EEPROM Read Error', mtError, [mbOK],0);
      D2XX.Close(ftHandle);
    end
  else
    raise Exception.Create('USB Dongle Open Error');
    //MessageDlg('USB Dongle Open Error', mtError, [mbOK],0);
end;

procedure TTscUSBDongle.CodeCreate;
var
  I: Integer;
begin
  FWriteAnsCode     := FProductCode + FWriteDummyCode + FWriteLotNo + FWriteSerialNo + FWriteEditionCode;
  for I := 0 to 23 do
    begin
      WriteAnsCodeChar[I]   := FWriteAnsCode[I+1];
      WriteKeyCodeChar[I]   := KEY_CODE[I+1];
      WriteAnsCodeByte[I]   := Ord(WriteAnsCodeChar[I]);
      WriteKeyCodeByte[I]   := Ord(WriteKeyCodeChar[I]);
      WritePassCodeByte[I]  := WriteKeyCodeByte[I] xor WriteAnsCodeByte[I];
      WritePassCodeChar[I]  := Char(WritePassCodeByte[I]);
    end;
  FWritePassCode    := string(WritePassCodeChar);
end;

procedure TTscUSBDongle.SetDongleCode(serial:PAnsiChar);
var
  ftHandle  : UInt32;
  ret       : Integer;
begin
  ret := TsfMessageDlgInformation('Are you sure you want to write to the USB Dongle(Serial Number' +string(serial)+ ')?');
  if ret = mrYes then
    begin
      if D2XX.OpenEx(serial, FT_OPEN_BY_SERIAL_NUMBER, ftHandle) = FT_OK then
        begin
          if D2XX.EE_UAWrite(ftHandle,WritePassCodeChar) = FT_OK then
            begin

              D2XX.Close(ftHandle);
              TsfMessageDlgInformation('Pass Code Writed');
              //MessageDlg('Pass Code Writed', mtInformation, [mbOK], 0);
            end
          else
            TsfMessageDlgError('Write Error');
            //MessageDlg('Write Error', mtError, [mbOK],0);
        end
      else
        TsfMessageDlgError('USB Dongle Open Error');
        //MessageDlg('USB Dongle Open Error', mtError, [mbOK], 0);
    end
  else
    TsfMessageDlgInformation('Canceled It');
    //MessageDlg('Canceled It' ,mtInformation, [mbOK], 0);
end;
end.
