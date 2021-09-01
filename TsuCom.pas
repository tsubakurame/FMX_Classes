unit TsuCom;

{
  FMXで動作させられるComPort用クラス
  現時点ではプラットフォームはWindowsに依存
}

interface
uses
  windows,
  System.SysUtils, System.Classes,
  FMX.Forms,
  TsuComTypes
  ;
{$region'    定数    '}
const
  IXCom_VER = 1;
  ASCII_XON = $11; // XON文字
  ASCII_XOFF = $13; // XOFF文字

  dcb_OutxCtsFlow = $00000004;
  dcb_OutxDsrFlow = $00000008;
  dcb_Dtr_Enable = $00000010;
  dcb_Dtr_Handshake = $00000020;
  dcb_OutX = $00000100;
  dcb_InX = $00000200;
  dcb_Rts_Enable = $00001000;
  dcb_Rts_Handshake = $00002000;
  dcb_Rts_Toggle = $00003000;
{$endregion}

type
  TTsdComNotifyEvent = procedure(Sender: TObject; EventMask: TTsdEventMask) of object;
  TTsdComNotifyRxTxEvent = procedure(Sender: TObject; Size: Word) of object;
  TTscComWatch  = class(TThread)
    private
      FComDev : THandle;
      FOwner  : TComponent;
      FTerminatedComp : Boolean;
      //FOnTerminate  : TNotifyEvent;
    protected
      procedure Execute; override;
    public
      constructor Create(AOwner: TComponent; ComDev: THandle; callback:TNotifyEvent);
      property TerminatedComp : Boolean read FTerminatedComp;
  end;

  TTscCom = class(TComponent)
    private
      procedure SetPort(const Value: string);
    protected
      FHandle               : THandle;                  //  通信デバイスのハンドル
      FDCB                  : TDCB;                     //  通信デバイス制御ブロック
      FPort                 : string;
      FBaudRate             : Integer;
      FBaudRateUserDefined  : UInt32;
      FDataBits             : TTseDataBits;
      FParityBits           : TTseParityBits;
      FStopBits             : TTseStopBits;
      FFlowControls         : TTsdFlowControls;

      FInQueueSize          : UInt16;                   //  受信バッファサイズ
      FOutQueueSize         : UInt16;                   //  送信バッファサイズ
      FReceiveNotifySize    : Integer;                  //  受信バッファ通知バイト数
      FSendNotifySize       : Integer;                  //  送信バッファ通知バイト数
      FEventMask            : TTsdEventMask;

      FReadOs               : TOverlapped;              //  受信用オーバーラップ構造体
      FWriteOs              : TOverlapped;

      FOnComReceive        : TTsdComNotifyRxTxEvent;  // 受信イベント
      FOnComTransmit       : TTsdComNotifyRxTxEvent;  // 送信イベント
      FOnComEvent          : TTsdComNotifyEvent;      // 通信イベントの発生

      FThread               : TTscComWatch;
      FRts                  : Boolean;
      FDtr                  : Boolean;
      procedure SetBaudRate(Value: Integer); virtual;
      procedure SetBaudRateUserDefined(Value: DWord); virtual;

      procedure SetParityBits(Value: TTseParityBits); virtual;
      procedure SetDataBits(Value: TTseDataBits); virtual;
      procedure SetStopBits(Value: TTseStopBits); virtual;
      procedure SetFlowControls(Value: TTsdFlowControls); virtual;

      procedure SetReceiveNotifySize(Value: Integer);
      procedure SetSendNotifySize(Value: Integer);
      procedure SetEventMask(Value: TTsdEventMask);
      procedure DoComReceive; virtual;
      procedure DoComTransmit; virtual;
      procedure DoComEvent(EvtMask: DWord); virtual;
      procedure SetFlowRts(fBool: Boolean); virtual;
      procedure SetFlowDtr(fBool: Boolean); virtual;
      procedure SetReadTimeOut(const Value: DWord); virtual;
      procedure SetWriteTimeOut(const Value: DWord); virtual;
      function GetDsrState: Boolean; virtual;
      function GetReadTimeOut: DWord;
      function GetWriteTimeOut: DWord;
      procedure OnTerminate(Sender:TObject);
    public
      ComTimeOuts           : TCommTimeouts;
      constructor Create(AOwner: TComponent); override;
      destructor Destroy;override;

      procedure Open; virtual;
      procedure Close; virtual;

      procedure Read(Buffer: PByte; Size: Integer); virtual;
      procedure Write(Buffer: Pointer; Size: Integer); virtual;
    published
      property Port: string read FPort write SetPort;
      property BaudRate: Integer read FBaudRate write SetBaudRate default 9600;
      property BaudRateUserDefined: DWord read FBaudRateUserDefined write SetBaudRateUserDefined default 9600;
      property ParityBits: TTseParityBits read FParityBits write SetParityBits default PB_NONE;
      property DataBits: TTseDataBits read FDataBits write SetDataBits default DB_8;
      property StopBits: TTseStopBits read FStopBits write SetStopBits default SB_1;
      property FlowControls: TTsdFlowControls read FFlowControls write SetFlowControls default [FC_RTS_CTS];

      property InQueueSize: Word read FInQueueSize write FInQueueSize default 4096;
      property OutQueueSize: Word read FOutQueueSize write FOutQueueSize default 4096;
      property ReceiveNotifySize: Integer read FReceiveNotifySize write SetReceiveNotifySize default 3072;
      property SendNotifySize: Integer read FSendNotifySize write SetSendNotifySize default 1024;
      property EventMask: TTsdEventMask read FEventMask write SetEventMask default [];

      property DsrState: Boolean read GetDsrState;

      property OnComEvent: TTsdComNotifyEvent read FOnComEvent write FOnComEvent;
      property OnComReceive: TTsdComNotifyRxTxEvent read FOnComReceive write FOnComReceive;
      property OnComTransmit: TTsdComNotifyRxTxEvent read FOnComTransmit write FOnComTransmit;

      property Rts: Boolean read FRts write SetFlowRts;
      property Dtr: Boolean read FDtr write SetFlowDtr;

      property ReadTimeOut: DWord read GetReadTimeOut write SetReadTimeOut;
      property WriteTimeOut: DWord read GetWriteTimeOut write SetWriteTimeOut;
  end;

implementation

constructor TTscCom.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHandle               := INVALID_HANDLE_VALUE;
  FPort                 := '1';
  FBaudRate             := 9600;
  FBaudRateUserDefined  := 9600;
  FDataBits             := DB_8;
  FParityBits           := PB_NONE;
  FStopBits             := SB_1;
  FFlowControls         := [FC_RTS_CTS];
  FInQueueSize          := 4096;
  FOutQueueSize         := 4096;
  FReceiveNotifySize    := 3072;
  FSendNotifySize       := 1024;
  FEventMask            := [];
  FDCB.DCBLength        := SizeOf(FDCB);
  FOnComReceive         := nil;
end;

destructor TTscCom.Destroy;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
    Close;
  inherited Destroy;
end;

procedure TTscCom.Open;
var
  szPort  : array [0..15] of Char;
begin
  if FHandle = INVALID_HANDLE_VALUE then // 通信中でない時
    begin
      FReadOs.Offset := 0; // 受信オーバーラップ処理用
      FReadOs.OffsetHigh := 0;
      // イベントオブジェクトの作成
      FReadOs.hEvent := CreateEvent(nil, // ハンドルを継承しない
        True, // 手動リセットイベント
        False, // 非シグナル状態で初期化
        nil); // イベントオブジェクトの名前
      if FReadOs.hEvent = 0 then
        raise TTsxComOpenError(-2); // イベントが作成できない

      FWriteOs.Offset := 0; // 送信オーバーラップ処理用
      FWriteOs.OffsetHigh := 0;
      // イベントオブジェクトの作成
      FWriteOs.hEvent := CreateEvent( nil, // ハンドルを継承しない
                                      True, // 手動リセットイベント
                                      False, // 非シグナル状態で初期化
                                      nil); // イベントオブジェクトの名前
      if FWriteOs.hEvent = 0 then
        begin
          CloseHandle(FReadOs.hEvent); // 受信用イベントのクローズ
          raise TTsxComOpenError(-3); // イベントが作成できない
        end;

      StrPCopy(szPort, '\\.\' + FPort); // ポート名の作成
      FHandle := CreateFile(szPort, // ポート名
                            GENERIC_READ or GENERIC_WRITE, 0, // 排他的使用(*)
                            nil, // セキュリティー属性なし
                            OPEN_EXISTING, // 既存(*)
                            FILE_ATTRIBUTE_NORMAL or // 通常
                            FILE_FLAG_OVERLAPPED, // オーバーラップ入出力
                            0); // テンプレートなし(*)
      if FHandle = INVALID_HANDLE_VALUE then // エラー発生時
        raise TTsxComOpenError.Create(FHandle); // 例外の生成

      // 送受信バッファーサイズの設定
      SetupComm(FHandle, FInQueueSize, FOutQueueSize);

      // すべてのバッファー情報を破棄する
      PurgeComm(FHandle, PURGE_TXABORT or PURGE_RXABORT or PURGE_TXCLEAR or PURGE_RXCLEAR);

      // タイムアウトのセットアップ
      ComTimeouts.ReadIntervalTimeout := MAXDWORD;
      ComTimeouts.ReadTotalTimeoutMultiplier := 0;
      ComTimeouts.ReadTotalTimeoutConstant := 100;
      ComTimeouts.WriteTotalTimeoutMultiplier := 0;
      ComTimeouts.WriteTotalTimeoutConstant := 100;
      SetCommTimeouts(FHandle, ComTimeouts);

      // 通信環境の設定
      SetBaudRate(FBaudRate); // 通信速度
      SetDataBits(FDataBits); // データビット数
      SetParityBits(FParityBits); // パリティービット数
      SetStopBits(FStopBits); // ストップビット数

      SetFlowControls(FFlowControls); // フロー制御
      SetReceiveNotifySize(FReceiveNotifySize);
      SetSendNotifySize(FSendNotifySize);

      SetEventMask(FEventMask); // イベントマスク

      FThread := TTscComWatch.Create(self, FHandle, OnTerminate);
      // 受信監視スレッドの起動

      EscapeCommFunction(FHandle, SETDTR); // DTRをオンにする
    end;
end;

procedure TTscCom.Close;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
  begin
    FOnComReceive := nil;
    SetCommMask(FHandle, 0); // 通知イベントをクリアして

    //FThread.Terminate;
    //OnTerminate(Self);
    //Form1.Memo1.Lines.Add('Event Clear');
    //while not FThread.TerminatedComp do SetCommMask(FHandle, 0);
    //Form1.Memo1.Lines.Add('TerminatedComp');
    // スレッドを終了させる

    //FThread.OnTerminate(Self);
    //FThread.Terminate;
    //while FThread <> nil do;
    //FreeAndNil(FThread);

    EscapeCommFunction(FHandle, CLRDTR); // DTRをオフにする
    //while not FThread.TerminatedComp do; // スレッドの終了を待つ

    // すべてのバッファー情報を破棄する
    PurgeComm(FHandle, PURGE_TXABORT or PURGE_RXABORT or PURGE_TXCLEAR or PURGE_RXCLEAR);

    CloseHandle(FHandle); // シリアル通信のクローズ
    FHandle := INVALID_HANDLE_VALUE; // 再度オープンするため

    CloseHandle(FReadOs.hEvent); // 受信イベントのクローズ
    CloseHandle(FWriteOs.hEvent); // 送信イベントのクローズ
  end;
end;

procedure TTscCom.Read(Buffer: PByte; Size: Integer);
var
  dwError: DWord;
  Stat: TComStat;
  dwLength: DWord;
begin
  if FHandle = INVALID_HANDLE_VALUE then
    raise TTsxComError.Create('通信が開始されていない。');

  ClearCommError(FHandle, dwError, @Stat);
  dwLength := Size;
  if not ReadFile(FHandle, Buffer^, Size, dwLength, @FReadOs) then
  begin
    if GetLastError = ERROR_IO_PENDING then // オーバーラップ処理の場合
    begin
      while not GetOverlappedResult(FHandle, FReadOs, dwLength, True) do
      begin
        if GetLastError = ERROR_IO_INCOMPLETE then // 処理未完了の場合
          Continue
        else
        begin
          ClearCommError(FHandle, dwError, @Stat);
          Break;
        end;
      end;
    end
    else
    begin // その他のエラー発生
      ClearCommError(FHandle, dwError, @Stat); // エラーをクリア
      raise TTsxComReadWriteError.Create(dwError); // 例外の生成
    end;
  end;
end;

procedure TTscCom.Write(Buffer: Pointer; Size: Integer);
var
  dwError: DWord;
  Stat: TComStat;
  dwBytesWritten: DWord;
begin
  if FHandle = INVALID_HANDLE_VALUE then
    raise TTsxComError.Create('通信が開始されていない。');

  if FOutQueueSize < Size then
    raise TTsxComError.Create('送信データ長が長すぎる。');

  repeat // 送信キューが空くのを待つ
    // Application.ProcessMessages;          // これがあると送信が逆転する
    ClearCommError(FHandle, dwError, @Stat);
  until (FOutQueueSize - Stat.cbOutQue) >= Word(Size);

  if not WriteFile(FHandle, Buffer^, Size, dwBytesWritten, @FWriteOs) then
  begin
    if GetLastError = ERROR_IO_PENDING then // オーバーラップ処理時
    begin
      while not GetOverlappedResult(FHandle, FWriteOs, dwBytesWritten, True) do
      begin
        if GetLastError = ERROR_IO_INCOMPLETE then // まだ完了しない
          Continue
        else
        begin
          ClearCommError(FHandle, dwError, @Stat);
          Break;
        end;
      end;
    end
    else
    begin // その他のエラー発生
      ClearCommError(FHandle, dwError, @Stat);
      raise TTsxComReadWriteError.Create(dwError);
    end;
  end;
end;

{$region'    プロパティメソッド    '}
procedure TTscCom.SetPort(const Value: string);
begin
  FPort := Value;
end;

procedure TTscCom.SetBaudRate(Value: Integer);
begin
  FBaudRate := Value;
  if FHandle <> INVALID_HANDLE_VALUE then
  begin
    GetCommState(FHandle, FDCB);
    if FBaudRate <> -1 then // ユーザー定義でない場合
      FDCB.BaudRate := FBaudRate
    else
      FDCB.BaudRate := FBaudRateUserDefined;
    SetCommState(FHandle, FDCB);
  end;
end;

procedure TTscCom.SetBaudRateUserDefined(Value: DWord);
begin
  FBaudRateUserDefined := Value;
  SetBaudRate(-1);
end;

procedure TTscCom.SetParityBits(Value: TTseParityBits);
begin
  FParityBits := Value; // 内部変数に保存
  if FHandle <> INVALID_HANDLE_VALUE then // 通信がオープンされていたら
  begin
    GetCommState(FHandle, FDCB); // 現在のTDCBの取得
    FDCB.Parity := Ord(FParityBits); // 順序数をそのまま設定
    SetCommState(FHandle, FDCB); // 新しいTDCBをセット
  end;
end;

procedure TTscCom.SetDataBits(Value: TTseDataBits);
begin
  FDataBits := Value; // 内部変数に保存
  if FHandle <> INVALID_HANDLE_VALUE then // 通信がオープンされていたら
  begin
    GetCommState(FHandle, FDCB); // 現在のTDCBの取得
    FDCB.ByteSize := 4 + Ord(FDataBits); // 順序数に４を足して４から８に
    SetCommState(FHandle, FDCB); // 新しいTDCBをセット
  end;
end;

procedure TTscCom.SetStopBits(Value: TTseStopBits);
begin
  FStopBits := Value; // 内部変数に保存
  if FHandle <> INVALID_HANDLE_VALUE then // 通信がオープンされていたら
  begin
    GetCommState(FHandle, FDCB); // 現在のTDCBの取得
    FDCB.StopBits := Ord(FStopBits); // 順序数をそのまま設定
    SetCommState(FHandle, FDCB); // 新しいTDCBをセット
  end;
end;

procedure TTscCom.SetFlowControls(Value: TTsdFlowControls);
begin
  FFlowControls := Value; // 内部変数に保存
  if FHandle <> INVALID_HANDLE_VALUE then // 通信がオープンされていたら
  begin
    GetCommState(FHandle, FDCB);
    FDCB.Flags := FDCB.Flags and $FFFF8003; // fOutxCtsFlow      ($00000004)
    // fOutxDsrFlow      ($00000008)
    // fDtrControl       ($00000030)
    // fDsrSensitivuty   ($00000040)
    // fTXContinueOnXoff ($00000080)
    // fOutX             ($00000100)
    // fInX              ($00000200)
    // fErrorChar        ($00000400)
    // fNull             ($00000800)
    // fRtsControl       ($00003000)
    // fAbortOnError     ($00004000)
    // をオフにする

    if FC_RTS_CTS in FFlowControls then // RTS/CTSフロー制御の場合
      FDCB.Flags := FDCB.Flags or dcb_OutxCtsFlow or dcb_Rts_Handshake
    else
      FDCB.Flags := FDCB.Flags or dcb_Rts_Enable;

    if FC_DTR_DSR in FFlowControls then // DTR/DSRフロー制御の場合
      FDCB.Flags := FDCB.Flags or dcb_OutxDsrFlow or dcb_Dtr_Handshake
    else
      FDCB.Flags := FDCB.Flags or dcb_Dtr_Enable;

    if FC_XON_XOFF in FFlowControls then // XON/XOFFフロー制御の場合
      FDCB.Flags := FDCB.Flags or dcb_OutX or dcb_InX;
    FDCB.XonChar := Char(ASCII_XON);
    FDCB.XoffChar := Char(ASCII_XOFF);

    FDCB.Flags := FDCB.Flags or $00000003; // fBinary & fParity;
    SetCommState(FHandle, FDCB);
  end;
end;

procedure TTscCom.SetReceiveNotifySize(Value: Integer);
begin
  FReceiveNotifySize := Value; // 内部変数に保存
  if FHandle <> INVALID_HANDLE_VALUE then // 通信がオープンされているなら
  begin
    GetCommState(FHandle, FDCB); // 現在のTDCBの取得
    FDCB.XoffLim := FInQueueSize - FReceiveNotifySize;
    SetCommState(FHandle, FDCB); // 新しいTDCBのセット
  end;
end;

procedure TTscCom.SetSendNotifySize(Value: Integer);
begin
  FSendNotifySize := Value; // 内部変数に保存
  if FHandle <> INVALID_HANDLE_VALUE then // 通信がオープンされているなら
  begin
    GetCommState(FHandle, FDCB); // 現在のTDCBの取得
    FDCB.XonLim := FSendNotifySize; // 新しい値の設定
    SetCommState(FHandle, FDCB); // 新しいTDCBのセット
  end;
end;

procedure TTscCom.SetEventMask(Value: TTsdEventMask);
var
  dwEvtMask: DWord;
begin
  FEventMask := Value; // 内部変数に保存
  if FHandle <> INVALID_HANDLE_VALUE then // 通信がオープンされているなら
  begin
    dwEvtMask := 0; // イベントマスクを初期化
    if EVN_RX_CHAR in FEventMask then // 文字受信イベント
      dwEvtMask := dwEvtMask or EV_RXCHAR;
    if EVN_RX_FLAG in FEventMask then // イベント文字の受信
      dwEvtMask := dwEvtMask or EV_RXFLAG;
    if EVN_TX_EMPTY in FEventMask then // 送信バッファが空
      dwEvtMask := dwEvtMask or EV_TXEMPTY;
    if EVN_CTS in FEventMask then // CTS信号の変化
      dwEvtMask := dwEvtMask or EV_CTS;
    if EVN_DSR in FEventMask then // DSR信号の変化
      dwEvtMask := dwEvtMask or EV_DSR;
    if EVN_RLSD in FEventMask then // RLSD(CD)信号の変化
      dwEvtMask := dwEvtMask or EV_RLSD;
    if EVN_BREAK in FEventMask then // ブレークの検出
      dwEvtMask := dwEvtMask or EV_BREAK;
    if EVN_ERROR in FEventMask then // 回線状態エラー
      dwEvtMask := dwEvtMask or EV_ERR;
    if EVN_RING in FEventMask then // 電話が掛かってきた
      dwEvtMask := dwEvtMask or EV_RING;
    if EVN_PERR in FEventMask then // プリンタエラー？
      dwEvtMask := dwEvtMask or EV_PERR;
    SetCommMask(FHandle, dwEvtMask); // 通信イベントマスクの設定
  end;
end;

procedure TTscCom.SetFlowRts(fBool: Boolean);
begin
  FRts := fBool;

  if FHandle <> INVALID_HANDLE_VALUE then // 通信がオープンされていたら
    begin
      if fBool then
        EscapeCommFunction(FHandle, SETRTS)
      else
        EscapeCommFunction(FHandle, CLRRTS);
    end;
end;

procedure TTscCom.SetFlowDtr(fBool: Boolean);
begin
  FDtr := fBool;

  if FHandle <> INVALID_HANDLE_VALUE then // 通信がオープンされていたら
    if fBool then
      EscapeCommFunction(FHandle, SETDTR)
    else
      EscapeCommFunction(FHandle, CLRDTR);
end;

function TTscCom.GetDsrState: Boolean;
var
  ModemStat: DWord;
begin
  if FHandle <> INVALID_HANDLE_VALUE then // 通信がオープンされていたら
  begin
    GetCommModemStatus(FHandle, ModemStat); // モデムステータスの取得
    Result := ((ModemStat and MS_DSR_ON) = MS_DSR_ON);
  end
  else
    Result := False;
end;

  {$region'    タイムアウト    '}
procedure TTscCom.SetReadTimeOut(const Value: DWord);
begin
  ComTimeouts.ReadTotalTimeoutConstant := Value;
  SetCommTimeouts(FHandle, ComTimeouts);
end;

procedure TTscCom.SetWriteTimeOut(const Value: DWord);
begin
  ComTimeouts.WriteTotalTimeoutConstant := Value;
  SetCommTimeouts(FHandle, ComTimeouts);
end;

function TTscCom.GetReadTimeOut: DWord;
begin
  Result := ComTimeouts.ReadTotalTimeoutConstant;
end;

function TTscCom.GetWriteTimeOut: DWord;
begin
  Result := ComTimeouts.WriteTotalTimeoutConstant;
end;
  {$endregion}

{$endregion}

procedure TTscCom.OnTerminate(Sender:TObject);
begin
  if FThread <> nil then
    begin
      FThread.Terminate;
      FreeAndNil(FThread);
    end;
end;

{$region'    イベントメソッド    '}
procedure TTscCom.DoComReceive;
var
  dwErrors: DWord;
  Stat: TComStat;
begin
  if (FHandle <> INVALID_HANDLE_VALUE) and Assigned(OnComReceive) then
    begin
      //Form1.Memo1.Lines.Add('2');
      ClearCommError(FHandle, dwErrors, @Stat);
      //Form1.Memo1.Lines.Add('3');
      if Stat.cbInQue > 0 then
        begin
          FOnComReceive(self, Stat.cbInQue);
          //Form1.Memo1.Lines.Add('4');
        end;
      ClearCommError(FHandle, dwErrors, @Stat);
      //Form1.Memo1.Lines.Add('5');
    end;
end;

procedure TTscCom.DoComTransmit;
var
  dwErrors: DWord;
  Stat: TComStat;
begin
  if (FHandle <> INVALID_HANDLE_VALUE) and Assigned(FOnComTransmit) then
  begin
    ClearCommError(FHandle, dwErrors, @Stat);
    FOnComTransmit(self, Stat.cbOutQue);
  end;
end;

procedure TTscCom.DoComEvent(EvtMask: DWord);
var
  EventMask: TTsdEventMask;
begin
  // 通信中でOnComEventが設定されている場合
  if (FHandle <> INVALID_HANDLE_VALUE) and Assigned(FOnComEvent) then
  begin
    EventMask := []; // イベントマスクの初期化
    if (EvtMask and EV_BREAK) = EV_BREAK then // EV_BREAK   ブレーク信号受信
      EventMask := EventMask + [EVN_BREAK];
    if (EvtMask and EV_CTS) = EV_CTS then // EV_CTS     CTS信号の変化
      EventMask := EventMask + [EVN_CTS];
    if (EvtMask and EV_DSR) = EV_DSR then // EV_DSR     DSR信号の変化
      EventMask := EventMask + [EVN_DSR];
    if (EvtMask and EV_ERR) = EV_ERR then // EV_ERR     回線状態エラー
      EventMask := EventMask + [EVN_ERROR];
    if (EvtMask and EV_RING) = EV_RING then // EV_RING    RI信号検知
      EventMask := EventMask + [EVN_RING];
    if (EvtMask and EV_RLSD) = EV_RLSD then // EV_RLSD    RLSD信号の変化
      EventMask := EventMask + [EVN_RLSD];
    if (EvtMask and EV_RXFLAG) = EV_RXFLAG then // EV_RXFLAG  イベント文字受信
      EventMask := EventMask + [EVN_RX_FLAG];
    FOnComEvent(self, EventMask);
  end;
end;
{$endregion}

{$region'    受信スレッド    '}
constructor TTscComWatch.Create(AOwner: TComponent; ComDev: THandle; callback:TNotifyEvent);
var
  dwEvtMask: DWord;
begin
  inherited Create(False); // 生成後実行開始
  OnTerminate := callback;

  FOwner := AOwner; // オーナーの保存
  FComDev := ComDev; // 通信ハンドルの保存

  // 受信文字イベントをセットする
  GetCommMask(FComDev, dwEvtMask); // 現在の通信イベントマスクの取得
  dwEvtMask := dwEvtMask or EV_RXCHAR; // 受信文字イベントを追加
  SetCommMask(FComDev, dwEvtMask); // 新しい通信イベントマスクの設定

  //FreeOnTerminate := True; // 自動破棄
  FTerminatedComp := False;
end;

procedure TTscComWatch.Execute;
var
  dwEvtMask: DWord;
begin
  while not Terminated do // 接続中はループする
    begin
      dwEvtMask := 0;
      //Form1.Memo1.Lines.Add('wait');
      WaitCommEvent(FComDev, dwEvtMask, nil); // 通信イベント発生の待機
      //Form1.Memo1.Lines.Add('Event Catch');
      try
        if (dwEvtMask and EV_RXCHAR) = EV_RXCHAR then
          TTscCom(FOwner).DoComReceive // EV_RXCHAR  文字受信
        else if (dwEvtMask and EV_TXEMPTY) = EV_TXEMPTY then
          TTscCom(FOwner).DoComTransmit // EV_TXEMPTY 送信バッファーが空
        else if dwEvtMask <> 0 then
          TTscCom(FOwner).DoComEvent(dwEvtMask) // EV_BREAK   ブレーク信号受信
          // EV_CTS     CTS信号の変化
          // EV_DSR     DSR信号の変化
          // EV_ERR     回線状態エラー
          // EV_RING    RI信号検知
          // EV_RLSD    RLSD信号の変化
          // EV_RXFLAG  イベント文字受信
        else // ループから抜け出す
          Break;
      except
        Application.HandleException(self); // イベントハンドラーで例外発生
      end;
    end;
  FTerminatedComp := True;
  OnTerminate(Self);
end;
{$endregion}

end.
