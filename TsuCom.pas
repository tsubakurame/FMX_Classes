unit TsuCom;

{
  FMX�œ��삳������ComPort�p�N���X
  �����_�ł̓v���b�g�t�H�[����Windows�Ɉˑ�
}

interface
uses
  windows,
  System.SysUtils, System.Classes,
  FMX.Forms,
  TsuComTypes
  ;
{$region'    �萔    '}
const
  IXCom_VER = 1;
  ASCII_XON = $11; // XON����
  ASCII_XOFF = $13; // XOFF����

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
      FHandle               : THandle;                  //  �ʐM�f�o�C�X�̃n���h��
      FDCB                  : TDCB;                     //  �ʐM�f�o�C�X����u���b�N
      FPort                 : string;
      FBaudRate             : Integer;
      FBaudRateUserDefined  : UInt32;
      FDataBits             : TTseDataBits;
      FParityBits           : TTseParityBits;
      FStopBits             : TTseStopBits;
      FFlowControls         : TTsdFlowControls;

      FInQueueSize          : UInt16;                   //  ��M�o�b�t�@�T�C�Y
      FOutQueueSize         : UInt16;                   //  ���M�o�b�t�@�T�C�Y
      FReceiveNotifySize    : Integer;                  //  ��M�o�b�t�@�ʒm�o�C�g��
      FSendNotifySize       : Integer;                  //  ���M�o�b�t�@�ʒm�o�C�g��
      FEventMask            : TTsdEventMask;

      FReadOs               : TOverlapped;              //  ��M�p�I�[�o�[���b�v�\����
      FWriteOs              : TOverlapped;

      FOnComReceive        : TTsdComNotifyRxTxEvent;  // ��M�C�x���g
      FOnComTransmit       : TTsdComNotifyRxTxEvent;  // ���M�C�x���g
      FOnComEvent          : TTsdComNotifyEvent;      // �ʐM�C�x���g�̔���

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
  if FHandle = INVALID_HANDLE_VALUE then // �ʐM���łȂ���
    begin
      FReadOs.Offset := 0; // ��M�I�[�o�[���b�v�����p
      FReadOs.OffsetHigh := 0;
      // �C�x���g�I�u�W�F�N�g�̍쐬
      FReadOs.hEvent := CreateEvent(nil, // �n���h�����p�����Ȃ�
        True, // �蓮���Z�b�g�C�x���g
        False, // ��V�O�i����Ԃŏ�����
        nil); // �C�x���g�I�u�W�F�N�g�̖��O
      if FReadOs.hEvent = 0 then
        raise TTsxComOpenError(-2); // �C�x���g���쐬�ł��Ȃ�

      FWriteOs.Offset := 0; // ���M�I�[�o�[���b�v�����p
      FWriteOs.OffsetHigh := 0;
      // �C�x���g�I�u�W�F�N�g�̍쐬
      FWriteOs.hEvent := CreateEvent( nil, // �n���h�����p�����Ȃ�
                                      True, // �蓮���Z�b�g�C�x���g
                                      False, // ��V�O�i����Ԃŏ�����
                                      nil); // �C�x���g�I�u�W�F�N�g�̖��O
      if FWriteOs.hEvent = 0 then
        begin
          CloseHandle(FReadOs.hEvent); // ��M�p�C�x���g�̃N���[�Y
          raise TTsxComOpenError(-3); // �C�x���g���쐬�ł��Ȃ�
        end;

      StrPCopy(szPort, '\\.\' + FPort); // �|�[�g���̍쐬
      FHandle := CreateFile(szPort, // �|�[�g��
                            GENERIC_READ or GENERIC_WRITE, 0, // �r���I�g�p(*)
                            nil, // �Z�L�����e�B�[�����Ȃ�
                            OPEN_EXISTING, // ����(*)
                            FILE_ATTRIBUTE_NORMAL or // �ʏ�
                            FILE_FLAG_OVERLAPPED, // �I�[�o�[���b�v���o��
                            0); // �e���v���[�g�Ȃ�(*)
      if FHandle = INVALID_HANDLE_VALUE then // �G���[������
        raise TTsxComOpenError.Create(FHandle); // ��O�̐���

      // ����M�o�b�t�@�[�T�C�Y�̐ݒ�
      SetupComm(FHandle, FInQueueSize, FOutQueueSize);

      // ���ׂẴo�b�t�@�[����j������
      PurgeComm(FHandle, PURGE_TXABORT or PURGE_RXABORT or PURGE_TXCLEAR or PURGE_RXCLEAR);

      // �^�C���A�E�g�̃Z�b�g�A�b�v
      ComTimeouts.ReadIntervalTimeout := MAXDWORD;
      ComTimeouts.ReadTotalTimeoutMultiplier := 0;
      ComTimeouts.ReadTotalTimeoutConstant := 100;
      ComTimeouts.WriteTotalTimeoutMultiplier := 0;
      ComTimeouts.WriteTotalTimeoutConstant := 100;
      SetCommTimeouts(FHandle, ComTimeouts);

      // �ʐM���̐ݒ�
      SetBaudRate(FBaudRate); // �ʐM���x
      SetDataBits(FDataBits); // �f�[�^�r�b�g��
      SetParityBits(FParityBits); // �p���e�B�[�r�b�g��
      SetStopBits(FStopBits); // �X�g�b�v�r�b�g��

      SetFlowControls(FFlowControls); // �t���[����
      SetReceiveNotifySize(FReceiveNotifySize);
      SetSendNotifySize(FSendNotifySize);

      SetEventMask(FEventMask); // �C�x���g�}�X�N

      FThread := TTscComWatch.Create(self, FHandle, OnTerminate);
      // ��M�Ď��X���b�h�̋N��

      EscapeCommFunction(FHandle, SETDTR); // DTR���I���ɂ���
    end;
end;

procedure TTscCom.Close;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
  begin
    FOnComReceive := nil;
    SetCommMask(FHandle, 0); // �ʒm�C�x���g���N���A����

    //FThread.Terminate;
    //OnTerminate(Self);
    //Form1.Memo1.Lines.Add('Event Clear');
    //while not FThread.TerminatedComp do SetCommMask(FHandle, 0);
    //Form1.Memo1.Lines.Add('TerminatedComp');
    // �X���b�h���I��������

    //FThread.OnTerminate(Self);
    //FThread.Terminate;
    //while FThread <> nil do;
    //FreeAndNil(FThread);

    EscapeCommFunction(FHandle, CLRDTR); // DTR���I�t�ɂ���
    //while not FThread.TerminatedComp do; // �X���b�h�̏I����҂�

    // ���ׂẴo�b�t�@�[����j������
    PurgeComm(FHandle, PURGE_TXABORT or PURGE_RXABORT or PURGE_TXCLEAR or PURGE_RXCLEAR);

    CloseHandle(FHandle); // �V���A���ʐM�̃N���[�Y
    FHandle := INVALID_HANDLE_VALUE; // �ēx�I�[�v�����邽��

    CloseHandle(FReadOs.hEvent); // ��M�C�x���g�̃N���[�Y
    CloseHandle(FWriteOs.hEvent); // ���M�C�x���g�̃N���[�Y
  end;
end;

procedure TTscCom.Read(Buffer: PByte; Size: Integer);
var
  dwError: DWord;
  Stat: TComStat;
  dwLength: DWord;
begin
  if FHandle = INVALID_HANDLE_VALUE then
    raise TTsxComError.Create('�ʐM���J�n����Ă��Ȃ��B');

  ClearCommError(FHandle, dwError, @Stat);
  dwLength := Size;
  if not ReadFile(FHandle, Buffer^, Size, dwLength, @FReadOs) then
  begin
    if GetLastError = ERROR_IO_PENDING then // �I�[�o�[���b�v�����̏ꍇ
    begin
      while not GetOverlappedResult(FHandle, FReadOs, dwLength, True) do
      begin
        if GetLastError = ERROR_IO_INCOMPLETE then // �����������̏ꍇ
          Continue
        else
        begin
          ClearCommError(FHandle, dwError, @Stat);
          Break;
        end;
      end;
    end
    else
    begin // ���̑��̃G���[����
      ClearCommError(FHandle, dwError, @Stat); // �G���[���N���A
      raise TTsxComReadWriteError.Create(dwError); // ��O�̐���
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
    raise TTsxComError.Create('�ʐM���J�n����Ă��Ȃ��B');

  if FOutQueueSize < Size then
    raise TTsxComError.Create('���M�f�[�^������������B');

  repeat // ���M�L���[���󂭂̂�҂�
    // Application.ProcessMessages;          // ���ꂪ����Ƒ��M���t�]����
    ClearCommError(FHandle, dwError, @Stat);
  until (FOutQueueSize - Stat.cbOutQue) >= Word(Size);

  if not WriteFile(FHandle, Buffer^, Size, dwBytesWritten, @FWriteOs) then
  begin
    if GetLastError = ERROR_IO_PENDING then // �I�[�o�[���b�v������
    begin
      while not GetOverlappedResult(FHandle, FWriteOs, dwBytesWritten, True) do
      begin
        if GetLastError = ERROR_IO_INCOMPLETE then // �܂��������Ȃ�
          Continue
        else
        begin
          ClearCommError(FHandle, dwError, @Stat);
          Break;
        end;
      end;
    end
    else
    begin // ���̑��̃G���[����
      ClearCommError(FHandle, dwError, @Stat);
      raise TTsxComReadWriteError.Create(dwError);
    end;
  end;
end;

{$region'    �v���p�e�B���\�b�h    '}
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
    if FBaudRate <> -1 then // ���[�U�[��`�łȂ��ꍇ
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
  FParityBits := Value; // �����ϐ��ɕۑ�
  if FHandle <> INVALID_HANDLE_VALUE then // �ʐM���I�[�v������Ă�����
  begin
    GetCommState(FHandle, FDCB); // ���݂�TDCB�̎擾
    FDCB.Parity := Ord(FParityBits); // �����������̂܂ܐݒ�
    SetCommState(FHandle, FDCB); // �V����TDCB���Z�b�g
  end;
end;

procedure TTscCom.SetDataBits(Value: TTseDataBits);
begin
  FDataBits := Value; // �����ϐ��ɕۑ�
  if FHandle <> INVALID_HANDLE_VALUE then // �ʐM���I�[�v������Ă�����
  begin
    GetCommState(FHandle, FDCB); // ���݂�TDCB�̎擾
    FDCB.ByteSize := 4 + Ord(FDataBits); // �������ɂS�𑫂��ĂS����W��
    SetCommState(FHandle, FDCB); // �V����TDCB���Z�b�g
  end;
end;

procedure TTscCom.SetStopBits(Value: TTseStopBits);
begin
  FStopBits := Value; // �����ϐ��ɕۑ�
  if FHandle <> INVALID_HANDLE_VALUE then // �ʐM���I�[�v������Ă�����
  begin
    GetCommState(FHandle, FDCB); // ���݂�TDCB�̎擾
    FDCB.StopBits := Ord(FStopBits); // �����������̂܂ܐݒ�
    SetCommState(FHandle, FDCB); // �V����TDCB���Z�b�g
  end;
end;

procedure TTscCom.SetFlowControls(Value: TTsdFlowControls);
begin
  FFlowControls := Value; // �����ϐ��ɕۑ�
  if FHandle <> INVALID_HANDLE_VALUE then // �ʐM���I�[�v������Ă�����
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
    // ���I�t�ɂ���

    if FC_RTS_CTS in FFlowControls then // RTS/CTS�t���[����̏ꍇ
      FDCB.Flags := FDCB.Flags or dcb_OutxCtsFlow or dcb_Rts_Handshake
    else
      FDCB.Flags := FDCB.Flags or dcb_Rts_Enable;

    if FC_DTR_DSR in FFlowControls then // DTR/DSR�t���[����̏ꍇ
      FDCB.Flags := FDCB.Flags or dcb_OutxDsrFlow or dcb_Dtr_Handshake
    else
      FDCB.Flags := FDCB.Flags or dcb_Dtr_Enable;

    if FC_XON_XOFF in FFlowControls then // XON/XOFF�t���[����̏ꍇ
      FDCB.Flags := FDCB.Flags or dcb_OutX or dcb_InX;
    FDCB.XonChar := Char(ASCII_XON);
    FDCB.XoffChar := Char(ASCII_XOFF);

    FDCB.Flags := FDCB.Flags or $00000003; // fBinary & fParity;
    SetCommState(FHandle, FDCB);
  end;
end;

procedure TTscCom.SetReceiveNotifySize(Value: Integer);
begin
  FReceiveNotifySize := Value; // �����ϐ��ɕۑ�
  if FHandle <> INVALID_HANDLE_VALUE then // �ʐM���I�[�v������Ă���Ȃ�
  begin
    GetCommState(FHandle, FDCB); // ���݂�TDCB�̎擾
    FDCB.XoffLim := FInQueueSize - FReceiveNotifySize;
    SetCommState(FHandle, FDCB); // �V����TDCB�̃Z�b�g
  end;
end;

procedure TTscCom.SetSendNotifySize(Value: Integer);
begin
  FSendNotifySize := Value; // �����ϐ��ɕۑ�
  if FHandle <> INVALID_HANDLE_VALUE then // �ʐM���I�[�v������Ă���Ȃ�
  begin
    GetCommState(FHandle, FDCB); // ���݂�TDCB�̎擾
    FDCB.XonLim := FSendNotifySize; // �V�����l�̐ݒ�
    SetCommState(FHandle, FDCB); // �V����TDCB�̃Z�b�g
  end;
end;

procedure TTscCom.SetEventMask(Value: TTsdEventMask);
var
  dwEvtMask: DWord;
begin
  FEventMask := Value; // �����ϐ��ɕۑ�
  if FHandle <> INVALID_HANDLE_VALUE then // �ʐM���I�[�v������Ă���Ȃ�
  begin
    dwEvtMask := 0; // �C�x���g�}�X�N��������
    if EVN_RX_CHAR in FEventMask then // ������M�C�x���g
      dwEvtMask := dwEvtMask or EV_RXCHAR;
    if EVN_RX_FLAG in FEventMask then // �C�x���g�����̎�M
      dwEvtMask := dwEvtMask or EV_RXFLAG;
    if EVN_TX_EMPTY in FEventMask then // ���M�o�b�t�@����
      dwEvtMask := dwEvtMask or EV_TXEMPTY;
    if EVN_CTS in FEventMask then // CTS�M���̕ω�
      dwEvtMask := dwEvtMask or EV_CTS;
    if EVN_DSR in FEventMask then // DSR�M���̕ω�
      dwEvtMask := dwEvtMask or EV_DSR;
    if EVN_RLSD in FEventMask then // RLSD(CD)�M���̕ω�
      dwEvtMask := dwEvtMask or EV_RLSD;
    if EVN_BREAK in FEventMask then // �u���[�N�̌��o
      dwEvtMask := dwEvtMask or EV_BREAK;
    if EVN_ERROR in FEventMask then // �����ԃG���[
      dwEvtMask := dwEvtMask or EV_ERR;
    if EVN_RING in FEventMask then // �d�b���|�����Ă���
      dwEvtMask := dwEvtMask or EV_RING;
    if EVN_PERR in FEventMask then // �v�����^�G���[�H
      dwEvtMask := dwEvtMask or EV_PERR;
    SetCommMask(FHandle, dwEvtMask); // �ʐM�C�x���g�}�X�N�̐ݒ�
  end;
end;

procedure TTscCom.SetFlowRts(fBool: Boolean);
begin
  FRts := fBool;

  if FHandle <> INVALID_HANDLE_VALUE then // �ʐM���I�[�v������Ă�����
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

  if FHandle <> INVALID_HANDLE_VALUE then // �ʐM���I�[�v������Ă�����
    if fBool then
      EscapeCommFunction(FHandle, SETDTR)
    else
      EscapeCommFunction(FHandle, CLRDTR);
end;

function TTscCom.GetDsrState: Boolean;
var
  ModemStat: DWord;
begin
  if FHandle <> INVALID_HANDLE_VALUE then // �ʐM���I�[�v������Ă�����
  begin
    GetCommModemStatus(FHandle, ModemStat); // ���f���X�e�[�^�X�̎擾
    Result := ((ModemStat and MS_DSR_ON) = MS_DSR_ON);
  end
  else
    Result := False;
end;

  {$region'    �^�C���A�E�g    '}
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

{$region'    �C�x���g���\�b�h    '}
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
  // �ʐM����OnComEvent���ݒ肳��Ă���ꍇ
  if (FHandle <> INVALID_HANDLE_VALUE) and Assigned(FOnComEvent) then
  begin
    EventMask := []; // �C�x���g�}�X�N�̏�����
    if (EvtMask and EV_BREAK) = EV_BREAK then // EV_BREAK   �u���[�N�M����M
      EventMask := EventMask + [EVN_BREAK];
    if (EvtMask and EV_CTS) = EV_CTS then // EV_CTS     CTS�M���̕ω�
      EventMask := EventMask + [EVN_CTS];
    if (EvtMask and EV_DSR) = EV_DSR then // EV_DSR     DSR�M���̕ω�
      EventMask := EventMask + [EVN_DSR];
    if (EvtMask and EV_ERR) = EV_ERR then // EV_ERR     �����ԃG���[
      EventMask := EventMask + [EVN_ERROR];
    if (EvtMask and EV_RING) = EV_RING then // EV_RING    RI�M�����m
      EventMask := EventMask + [EVN_RING];
    if (EvtMask and EV_RLSD) = EV_RLSD then // EV_RLSD    RLSD�M���̕ω�
      EventMask := EventMask + [EVN_RLSD];
    if (EvtMask and EV_RXFLAG) = EV_RXFLAG then // EV_RXFLAG  �C�x���g������M
      EventMask := EventMask + [EVN_RX_FLAG];
    FOnComEvent(self, EventMask);
  end;
end;
{$endregion}

{$region'    ��M�X���b�h    '}
constructor TTscComWatch.Create(AOwner: TComponent; ComDev: THandle; callback:TNotifyEvent);
var
  dwEvtMask: DWord;
begin
  inherited Create(False); // ��������s�J�n
  OnTerminate := callback;

  FOwner := AOwner; // �I�[�i�[�̕ۑ�
  FComDev := ComDev; // �ʐM�n���h���̕ۑ�

  // ��M�����C�x���g���Z�b�g����
  GetCommMask(FComDev, dwEvtMask); // ���݂̒ʐM�C�x���g�}�X�N�̎擾
  dwEvtMask := dwEvtMask or EV_RXCHAR; // ��M�����C�x���g��ǉ�
  SetCommMask(FComDev, dwEvtMask); // �V�����ʐM�C�x���g�}�X�N�̐ݒ�

  //FreeOnTerminate := True; // �����j��
  FTerminatedComp := False;
end;

procedure TTscComWatch.Execute;
var
  dwEvtMask: DWord;
begin
  while not Terminated do // �ڑ����̓��[�v����
    begin
      dwEvtMask := 0;
      //Form1.Memo1.Lines.Add('wait');
      WaitCommEvent(FComDev, dwEvtMask, nil); // �ʐM�C�x���g�����̑ҋ@
      //Form1.Memo1.Lines.Add('Event Catch');
      try
        if (dwEvtMask and EV_RXCHAR) = EV_RXCHAR then
          TTscCom(FOwner).DoComReceive // EV_RXCHAR  ������M
        else if (dwEvtMask and EV_TXEMPTY) = EV_TXEMPTY then
          TTscCom(FOwner).DoComTransmit // EV_TXEMPTY ���M�o�b�t�@�[����
        else if dwEvtMask <> 0 then
          TTscCom(FOwner).DoComEvent(dwEvtMask) // EV_BREAK   �u���[�N�M����M
          // EV_CTS     CTS�M���̕ω�
          // EV_DSR     DSR�M���̕ω�
          // EV_ERR     �����ԃG���[
          // EV_RING    RI�M�����m
          // EV_RLSD    RLSD�M���̕ω�
          // EV_RXFLAG  �C�x���g������M
        else // ���[�v���甲���o��
          Break;
      except
        Application.HandleException(self); // �C�x���g�n���h���[�ŗ�O����
      end;
    end;
  FTerminatedComp := True;
  OnTerminate(Self);
end;
{$endregion}

end.
