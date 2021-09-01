unit TsuComTypes;

interface
uses
  System.SysUtils
  ;
type
  TTseParityBits    = (PB_NONE, PB_ODD, PB_EVEN, PB_MARK, PB_SPACE);
  TTseDataBits      = (DB_4, DB_5, DB_6, DB_7, DB_8);
  TTseStopBits      = (SB_1, SB_15, SB_2);
  TTseFlowControl   = (FC_DTR_DSR, FC_RTS_CTS, FC_XON_XOFF);
  TTsdFlowControls  = set of TTseFlowControl;
  TTseEvents        = ( EVN_RX_CHAR, EVN_RX_FLAG, EVN_TX_EMPTY, EVN_CTS, EVN_DSR,
                        EVN_RLSD, EVN_BREAK, EVN_ERROR, EVN_RING, EVN_PERR);
  TTsdEventMask     = set of TTseEvents;
  TTseDelimiter     = (DL_NONE, DL_CR, DL_LF, DL_CRLF, DL_CRLF_ONE_SIDE);
  TTseComPortState  = (COM_PORT_CLOSE, COM_PORT_OPEN);
  TTsdGetStrFunction= procedure(Sender:TObject; str:String) of object;

  TTscComItem = class(TObject)
    public
      Value: string;
  end;

  TTsxComError      = class(Exception);

  { エラーコード一覧

  }
  TTsxComOpenError  = class(TTsxComError)
    private
      FErrorCode  : Integer;
    public
      constructor Create(OpenErrorCode:Integer);
      property ErrorCode:Integer read FErrorCode;
  end;

  TTsxComReadWriteError = class(TTsxComError)
  private
    FErrorCode: UInt32;
  public
    constructor Create(ReadWriteErrorCode: UInt32);
    property ErrorCode: UInt32 read FErrorCode;
  end;

implementation

constructor TTsxComOpenError.Create(OpenErrorCode: Integer);
var
  msg: string;
begin
  FErrorCode := OpenErrorCode;
  msg := Format('オープンエラー ErrorCode = %d', [FErrorCode]);
  inherited Create(msg);
end;

constructor TTsxComReadWriteError.Create(ReadWriteErrorCode: UInt32);
var
  msg: string;
begin
  FErrorCode := ReadWriteErrorCode;
  msg := Format('入出力エラー ErrorCode = %d', [FErrorCode]);
  inherited Create(msg);
end;

end.
