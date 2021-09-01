unit TsuVISA;

interface
uses
  Winapi.Windows,
  System.SysUtils, System.AnsiStrings, System.Classes, System.Generics.Collections, System.RegularExpressions
  ;

const
  visa_dll                  = 'visa32.dll';
//  visa_dll                  = 'C:\Windows\System32\visa32.dll';
//  visa_dll  = 'C:\Program Files\IVI Foundation\VISA\Win64\agvisa\agbin\Visa32.dll';
  {$region'    Completion Codes    '}
  VI_SUCCESS                  = 0;
  VI_SUCCESS_EVENT_EN         = $3FFF0002;
  VI_SUCCESS_EVENT_DIS	      = $3FFF0003;
  VI_SUCCESS_QUEUE_EMPTY	    = $3FFF0004;
  VI_SUCCESS_TERM_CHAR	      = $3FFF0005;
  VI_SUCCESS_MAX_CNT	        = $3FFF0006;
  VI_WARN_QUEUE_OVERFLOW	    = $3FFF000C;
  VI_WARN_CONFIG_NLOADED	    = $3FFF0077;
  VI_SUCCESS_DEV_NPRESENT	    = $3FFF007D;
  VI_SUCCESS_TRIG_MAPPED	    = $3FFF007E;
  VI_SUCCESS_QUEUE_NEMPTY	    = $3FFF0080;
  VI_WARN_NULL_OBJECT	        = $3FFF0082;
  VI_WARN_NSUP_ATTR_STATE	    = $3FFF0084;
  VI_WARN_UNKNOWN_STATUS	    = $3FFF0085;
  VI_WARN_NSUP_BUF		        = $3FFF0088;
  VI_SUCCESS_NCHAIN		        = $3FFF0098;
  VI_SUCCESS_NESTED_SHARED    = $3FFF0099;
  VI_SUCCESS_NESTED_EXCLUSIVE = $3FFF009A;
  VI_SUCCESS_SYNC		          = $3FFF009B;
  {$endregion}
  {$region'    Error Codes    '}
  VI_WARN_EXT_FUNC_NIMPL		  = $3FFF00A9;
  VI_ERROR_SYSTEM_ERROR	      = $BFFF0000;
  VI_ERROR_INV_OBJECT	        = $BFFF000E;
  VI_ERROR_RSRC_LOCKED	      = $BFFF000F;
  VI_ERROR_INV_EXPR	          = $BFFF0010;
  VI_ERROR_RSRC_NFOUND	      = $BFFF0011;
  VI_ERROR_INV_RSRC_NAME	    = $BFFF0012;
  VI_ERROR_INV_ACC_MODE	      = $BFFF0013;
  VI_ERROR_TMO	              = $BFFF0015;
  VI_ERROR_CLOSING_FAILED	    = $BFFF0016;
  VI_ERROR_INV_DEGREE	        = $BFFF001B;
  VI_ERROR_INV_JOB_ID	        = $BFFF001C;
  VI_ERROR_NSUP_ATTR	        = $BFFF001D;
  VI_ERROR_NSUP_ATTR_STATE	  = $BFFF001E;
  VI_ERROR_ATTR_READONLY	    = $BFFF001F;
  VI_ERROR_INV_LOCK_TYPE	    = $BFFF0020;
  VI_ERROR_INV_ACCESS_KEY	    = $BFFF0021;
  VI_ERROR_INV_EVENT	        = $BFFF0026;
  VI_ERROR_INV_MECH	          = $BFFF0027;
  VI_ERROR_HNDLR_NINSTALLED	  = $BFFF0028;
  VI_ERROR_INV_HNDLR_REF	    = $BFFF0029;
  VI_ERROR_INV_CONTEXT	      = $BFFF002A;
  VI_ERROR_QUEUE_OVERFLOW	    = $BFFF002D;
  VI_ERROR_NENABLED	          = $BFFF002F;
  VI_ERROR_ABORT	            = $BFFF0030;
  VI_ERROR_RAW_WR_PROT_VIOL	  = $BFFF0034;
  VI_ERROR_RAW_RD_PROT_VIOL	  = $BFFF0035;
  VI_ERROR_OUTP_PROT_VIOL	    = $BFFF0036;
  VI_ERROR_INP_PROT_VIOL	    = $BFFF0037;
  VI_ERROR_BERR	              = $BFFF0038;
  VI_ERROR_IN_PROGRESS	      = $BFFF0039;
  VI_ERROR_INV_SETUP	        = $BFFF003A;
  VI_ERROR_QUEUE_ERROR	      = $BFFF003B;
  VI_ERROR_ALLOC	            = $BFFF003C;
  VI_ERROR_INV_MASK	          = $BFFF003D;
  VI_ERROR_IO	                = $BFFF003E;
  VI_ERROR_INV_FMT	          = $BFFF003F;
  VI_ERROR_NSUP_FMT	          = $BFFF0041;
  VI_ERROR_LINE_IN_USE	      = $BFFF0042;
  VI_ERROR_NSUP_MODE	        = $BFFF0046;
  VI_ERROR_SRQ_NOCCURRED	    = $BFFF004A;
  VI_ERROR_INV_SPACE	        = $BFFF004E;
  VI_ERROR_INV_OFFSET	        = $BFFF0051;
  VI_ERROR_INV_WIDTH	        = $BFFF0052;
  VI_ERROR_NSUP_OFFSET	      = $BFFF0054;
  VI_ERROR_NSUP_VAR_WIDTH	    = $BFFF0055;
  VI_ERROR_WINDOW_NMAPPED	    = $BFFF0057;
  VI_ERROR_RESP_PENDING	      = $BFFF0059;
  VI_ERROR_NLISTENERS	        = $BFFF005F;
  VI_ERROR_NCIC	              = $BFFF0060;
  VI_ERROR_NSYS_CNTLR	        = $BFFF0061;
  VI_ERROR_NSUP_OPER	        = $BFFF0067;
  VI_ERROR_INTR_PENDING	      = $BFFF0068;
  VI_ERROR_ASRL_PARITY	      = $BFFF006A;
  VI_ERROR_ASRL_FRAMING	      = $BFFF006B;
  VI_ERROR_ASRL_OVERRUN	      = $BFFF006C;
  VI_ERROR_TRIG_NMAPPED	      = $BFFF006E;
  VI_ERROR_NSUP_ALIGN_OFFSET	= $BFFF0070;
  VI_ERROR_USER_BUF	          = $BFFF0071;
  VI_ERROR_RSRC_BUSY	        = $BFFF0072;
  VI_ERROR_NSUP_WIDTH	        = $BFFF0076;
  VI_ERROR_INV_PARAMETER	    = $BFFF0078;
  VI_ERROR_INV_PROT	          = $BFFF0079;
  VI_ERROR_INV_SIZE	          = $BFFF007B;
  VI_ERROR_WINDOW_MAPPED	    = $BFFF0080;
  VI_ERROR_NIMPL_OPER	        = $BFFF0081;
  VI_ERROR_INV_LENGTH	        = $BFFF0083;
  VI_ERROR_INV_MODE	          = $BFFF0091;
  VI_ERROR_SESN_NLOCKED	      = $BFFF009C;
  VI_ERROR_MEM_NSHARED	      = $BFFF009D;
  VI_ERROR_LIBRARY_NFOUND	    = $BFFF009E;
  VI_ERROR_NSUP_INTR	        = $BFFF009F;
  VI_ERROR_INV_LINE	          = $BFFF00A0;
  VI_ERROR_FILE_ACCESS	      = $BFFF00A1;
  VI_ERROR_FILE_IO	          = $BFFF00A2;
  VI_ERROR_NSUP_LINE	        = $BFFF00A3;
  VI_ERROR_NSUP_MECH	        = $BFFF00A4;
  VI_ERROR_INTF_NUM_NCONFIG	  = $BFFF00A5;
  VI_ERROR_CONN_LOST	        = $BFFF00A6;
  VI_ERROR_MACHINE_NAVAIL	    = $BFFF00A7;
  VI_ERROR_NPERMISSION	      = $BFFF00A8;
  {$endregion}
  {$region'    Values and Ranges    '}
  VI_NULL = 0;
  {$endregion}
  {$region'    Attribute    '}
  VI_ATTR_RSRC_NAME           = $BFFF0002;
  VI_ATTR_TMO_VALUE           = $3FFF001A;
  {$endregion}
  VI_FIND_BUFLEN  = 256;
type
  ViStatus      = UInt32;
  ViUInt32      = UInt32;
  ViObject      = ViUInt32;
  ViPObject     = ^ViObject;
  ViSession     = ViObject;
  ViPSession    = ^ViSession;
  ViChar        = AnsiChar;
  ViPChar       = ^ViChar;
  ViString      = AnsiString;
  ViPString     = ^ViString;
  ViRsrc        = ViString;
  ViAccessMode  = ViUInt32;
  ViAttr        = ViUInt32;
  ViConstString = string;
  ViAttrState   = ViUInt32;
  ViFindList    = ViObject;
  ViInstrDesc   = array [0..VI_FIND_BUFLEN-1] of ViChar;
  ViByte        = Byte;
  ViPByte       = ^ViByte;
  ViBuf         = ViPByte;
  ViPBuf        = ViPByte;
  TTsrVISAPortProparties  = record
    PortDescriptor  : string;
    INSTR           : ViSession;
    IsOpen          : Boolean;
    TimeOut         : UInt32;
  end;
  TTscVISAPortPropertiesList  = class(TList<TTsrVISAPortProparties>)
    public
      function Add(data  : TTsrVISAPortProparties):Integer;
      function FindItems(descriptor : string):TTsrVISAPortProparties;overload;
      function FindItems(descriptor : string; out prts  : TTsrVISAPortProparties):Boolean;overload;
      property ItemFromDescriptor[descriptor:string] : TTsrVISAPortProparties read FindItems;
  end;
  TTscVISA  = class(TObject)
    private
      FDefaultRM        : ViSession;
      FINSTR            : ViSession;
      FHandle           : HMODULE;
      FDeviceList       : TStringList;
      FIsOpen           : Boolean;
      FTimeOut          : UInt32;
      FPortList         : TTscVISAPortPropertiesList;
      function StatusCheck(state:ViStatus):ViStatus;
//      procedure GetAttribute(attr:ViAttr;out attrState:ViAttrState);
//      function SetAttribute(attr:ViAttr; attrState:ViAttrState):Boolean;
      function CheckOpen(adr:ViString): Boolean;
      procedure SetTimeOut(descriptor:ViString; val:UInt32);
      function GetTimeOut(descriptor:ViString):UInt32;
      function GetIsOpen(descriptor:ViString):Boolean;
//      procedure SetIsOpen(descriptor:ViString; value:Boolean);
    public
      constructor Create;
      destructor Destroy;override;
      procedure FindList;
      function Open(adr:ViString):Boolean;
      function Close(adr:ViString):Boolean;
      procedure Write(adr, mess: ViString; count:ViUInt32; var retCount:ViUInt32);
      function Read(adr:ViString; count:ViUInt32; var retCount:ViUInt32):ViString;
      property DeviceList : TStringList read FDeviceList;
      property IsOpen[descriptor:ViString]  : Boolean read GetIsOpen;
      property TimeOut[descriptor:ViString] : UInt32 read GetTimeOut write SetTimeOut;
  end;
  EVISAError  = class(Exception);

{$region'    visa32.dll Call    '}
//var
//  viAssertIntrSignal
//  viAssertTrigger
//  viAssertUtilSignal
//  viBufRead
  function viBufWrite(vi:ViSession; buf:ViBuf; count:ViUInt32; var retCount:ViUInt32):ViStatus;
    stdcall; External visa_dll name 'viBufWrite';
//  function viClear(vi:ViSession):ViStatus;
//    stdcall; External visa_dll name 'viClear';
  function viClose(vi:ViObject):ViStatus;
    stdcall; External visa_dll name 'viClose';
//  viDisableEvent
//  viDiscardEvents
//  viEnableEvent
//  viEventHandler
  function viFindNext(findlist  : ViFindList; out instrDesc:ViInstrDesc):ViStatus;
    stdcall; external visa_dll name 'viFindNext';
  function viFindRsrc(vi:ViSession; expr:ViString; out findList:ViFindList; out retcnt:ViUInt32; out instrDesc:ViInstrDesc):ViStatus;
    stdcall; external visa_dll name 'viFindRsrc';
////  viFlush
  function viGetAttribute(vi:ViSession; attribute:ViAttr; out attrState:ViAttrState):ViStatus;
    stdcall; External visa_dll name 'viGetAttribute';
//  viGpibCommand
//  viGpibControlATN
//  viGpibControlREN
//  viGpibPassControl
//  viGpibSendIFC
//  viIn8/viIn16/viIn32/viIn64
//  viIn8Ex/viIn16Ex/viIn32Ex/viIn64Ex
//  viInstallHandler
//  viLock
//  viMapAddress/viMapAddressEx
//  viMapTrigger
//  viMemAlloc/viMemAllocEx
//  viMemFree/viMemFreeEx
//  viMove/viMoveEx
//  viMoveAsync/viMoveAsyncEx
//  viMoveIn8/viMoveIn16/viMoveIn32/viMoveIn64
//  viMoveIn8Ex/viMoveIn16Ex/viMoveIn32Ex/viMoveIn64Ex
//  viMoveOut8/viMoveOut16/viMoveOut32/viMoveOut64
//  viMoveOut8Ex/viMoveOut16Ex/viMoveOut32Ex/viMoveOut64Ex
//  function viOpen(sesn:ViSession; rsrcName:ViRsrc; accessMode:ViAccessMode; openTimeout:ViUInt32; out vi:ViSession):ViStatus;
  function viOpen(sesn:ViSession; rsrcName:ViString; accessMode:ViAccessMode; openTimeout:ViUInt32; out vi:ViSession):ViStatus;
    stdcall; External visa_dll name 'viOpen';
  function viOpenDefaultRM(out sesn:ViSession):ViStatus;
    stdcall; External visa_dll name 'viOpenDefaultRM';
//  viOut8/viOut16/viOut32/viOut64
//  viOut8Ex/viOut16Ex/viOut32Ex/viOut64Ex
//  viParseRsrc
//  viParseRsrcEx
//  viPeek8/viPeek16/viPeek32/viPeek64
//  viPoke8/viPoke16/viPoke32/viPoke64
//  function viPrintf(vi:ViSession;writeFmt:ViConstString;params:UInt32):ViStatus;
//    stdcall; External visa32_dll name 'viPrintf';
//  viQueryf
  function viRead(vi:ViSession; var buf:ViInstrDesc; count:ViUInt32; var retCount:ViUInt32):ViStatus;
    stdcall; External visa_dll name 'viRead';
//  viReadAsync
//  viReadSTB
//  viReadToFile
//  viScanf
  function viSetAttribute(vi:ViSession; attribute:ViAttr; attrState:ViAttrState):ViStatus;
    stdcall; External visa_dll name 'viSetAttribute';
//  viSetBuf
//  viSPrintf
//  viSScanf
//  viStatusDesc
//  viTerminate
//  viUninstallHandler
//  viUnlock
//  viUnmapAddress
//  viUnmapTrigger
//  viUsbControlIn
//  viUsbControlOut
//  viVPrintf
//  viVQueryf
//  viVScanf
//  viVSPrintf
//  viVSScanf
//  viVxiCommandQuery
//  viWaitOnEvent
  function viWrite(vi:ViSession; buf:ViString; count:ViUInt32; var retCount:ViUInt32):ViStatus;
    stdcall; External visa_dll name 'viWrite';
//  viWriteAsync
//  viWriteFromFile
{$endregion}

implementation

function TTscVISAPortPropertiesList.Add(data: TTsrVISAPortProparties):Integer;
var
  I : Integer;
begin
  for I := 0 to Count -1 do
    begin
      if Items[I].PortDescriptor = data.PortDescriptor then
        begin
          Items[I]  := data;
          Result    := I;
          Exit;
        end;
    end;
  Result  := inherited Add(data);
end;

function TTscVISAPortPropertiesList.FindItems(descriptor: string): TTsrVISAPortProparties;
var
  I: Integer;
begin
  for I := 0 to Count -1 do
    begin
      if Items[I].PortDescriptor = descriptor then
        begin
          Result  := Items[I];
          Exit;
        end;
    end;
  raise EVISAError.Create('descriptor is not found.');
end;

function TTscVISAPortPropertiesList.FindItems(descriptor: string; out prts: TTsrVISAPortProparties): Boolean;
var
  I: Integer;
begin
  for I := 0 to Count -1 do
    begin
      if Items[I].PortDescriptor = descriptor then
        begin
          Result  := True;
          prts    := Items[I];
          Exit;
        end;
    end;
  Result  := False;
end;

constructor TTscVISA.Create;
begin
  FIsOpen := False;
  FDeviceList := TStringList.Create;
  FPortList   := TTscVISAPortPropertiesList.Create;
  StatusCheck(viOpenDefaultRM(FDefaultRM));
  FindList;
end;

destructor TTscVISA.Destroy;
var
  I: Integer;
begin
  for I := 0 to FPortList.Count -1 do
    begin
      if FPortList[I].IsOpen then
        StatusCheck(viClose(FPortList[I].INSTR));
    end;
  StatusCheck(viClose(FDefaultRM));
  FDeviceList.Free;
  FPortList.Free;
end;

{$region'    Private Method    '}
function TTscVISA.StatusCheck(state: Cardinal):ViStatus;
var
  mess  : string;
begin
  Result  := state;
  if (State and $3FFF0000) = $3FFF0000 then
    Exit;
  case state of
    VI_SUCCESS            : Exit;
    VI_ERROR_RSRC_NFOUND  : mess  := 'Insufficient location information or resource not present in the system.';
    VI_ERROR_INV_EXPR     : mess  := 'Invalid expression specified for search.';
    VI_ERROR_USER_BUF     : mess  := 'A specified user buffer is not valid or cannot be accessed for the required size.';
    VI_ERROR_INV_RSRC_NAME: mess  := 'Invalid resource reference specified. Parsing error.';
    VI_ERROR_NSUP_OPER    : mess  := 'The given vi does not support this operation.';
    VI_ERROR_TMO          : mess  := 'Timeout expired before operation completed.';
    else mess := IntToHex(state);
  end;
  raise EVISAError.Create(mess);
end;

function TTscVISA.CheckOpen(adr:ViString): Boolean;
var
  prts  : TTsrVISAPortProparties;
begin
  if FPortList.FindItems(adr, prts) then
    Result  := prts.IsOpen
  else
    Result  := False;
end;

procedure TTscVISA.SetTimeOut(descriptor: AnsiString; val: Cardinal);
var
  prts  : TTsrVISAPortProparties;
begin
  if FPortList.FindItems(descriptor, prts) then
    begin
      StatusCheck(viSetAttribute(prts.INSTR, VI_ATTR_TMO_VALUE, val));
      prts.TimeOut  := val;
      FPortList.Add(prts);
    end;
end;

function TTscVISA.GetTimeOut(descriptor: AnsiString): Cardinal;
var
  prts  : TTsrVISAPortProparties;
begin
  if FPortList.FindItems(descriptor, prts) then
    begin
      StatusCheck(viGetAttribute(prts.INSTR, VI_ATTR_TMO_VALUE, prts.TimeOut));
      Result  := prts.TimeOut;
      FPortList.Add(prts);
      Exit;
    end
  else
    Result  := 0;
end;

function TTscVISA.GetIsOpen(descriptor: AnsiString): Boolean;
var
  prts  : TTsrVISAPortProparties;
begin
  if FPortList.FindItems(descriptor, prts) then
    Result  := prts.IsOpen
  else
    Result  := False;
end;
{$endregion}

{$region'    Public Method    '}
procedure TTscVISA.FindList;
var
  list  : ViFindList;
  count : ViUInt32;
  buffer  : ViInstrDesc;
begin
  StatusCheck(viFindRsrc(FDefaultRM, '?*', list, count, buffer));
  FDeviceList.Clear;
  FDeviceList.Add(buffer);
  while FDeviceList.Count <> count do
    begin
      StatusCheck(viFindNext(list, buffer));
      FDeviceList.Add(buffer);
    end;
  StatusCheck(viClose(list));
end;

function TTscVISA.Open(adr: ViString): Boolean;
var
  res : ViStatus;
  opend : Boolean;
  val : ViUInt32;
  I: Integer;
  portprts  : TTsrVISAPortProparties;
begin
  for I := 0 to FDeviceList.Count -1 do
    begin
      if TRegEx.IsMatch(adr, FDeviceList[I]) then
        begin
          adr := FDeviceList[I];
          Break;
        end;
    end;
  portprts.PortDescriptor := adr;
  for I := 0 to FPortList.Count -1 do
    begin
      if FPortList[I].PortDescriptor = adr then
        begin
          if FPortList[I].IsOpen then
            begin
              Result  := False;
              raise EVISAError.Create('This device is opened');
              Exit;
            end
          else
            begin
              portprts  := FPortList[I];
              Break;
            end;
        end;
    end;

//  if FIsOpen then StatusCheck(viClose(FINSTR));
  if StatusCheck(viOpen(FDefaultRM, adr, VI_NULL, VI_NULL, portprts.INSTR)) = VI_SUCCESS then
    begin
//  FPortList.Add(portprts);
      portprts.IsOpen   := True;
      FPortList.Add(portprts);
      GetTimeOut(adr);
    end
  else
    begin
      portprts.IsOpen := False;
    end;
end;

function TTscVISA.Close(adr:ViString): Boolean;
var
  prts  : TTsrVISAPortProparties;
begin
  if FPortList.FindItems(adr, prts) then
    begin
      if prts.IsOpen then
        begin
          try
            StatusCheck(viClose(prts.INSTR));
            prts.IsOpen := False;
          except
            prts.IsOpen := True;
          end;
        end;
      FPortList.Add(prts);
    end;
end;

procedure TTscVISA.Write(adr, mess: ViString; count:ViUInt32; var retCount:ViUInt32);
begin
  if CheckOpen(adr) then
    begin
      StatusCheck(viWrite(FPortList.FindItems(adr).INSTR, mess, count, retCount));
    end;
end;

function TTscVISA.Read(adr:ViString; count: Cardinal; var retCount: Cardinal): AnsiString;
var
  res : ViPBuf;
  res_str : ViInstrDesc;
begin
  if CheckOpen(adr) then
    begin
      StatusCheck(viRead(FPortList.FindItems(adr).INSTR, res_str, count, retCount));
      Result  := LeftStr(res_str, retCount);
    end;
end;
{$endregion}

end.
