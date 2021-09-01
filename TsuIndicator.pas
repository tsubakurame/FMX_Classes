unit TsuIndicator;

interface
uses
  System.Math, System.UITypes, System.Types,
  Fmx.Objects, Fmx.Graphics, Fmx.Types
  ;

type
  TTseIndicateStatus  = ( IND_STATUS_NONE,
                          IND_STATUS_OK,
                          IND_STATUS_NG,
                          IND_STATUS_WAIT,
                          IND_STATUS_ERROR,
                          IND_STATUS_MEAS);
  TTscIndicator = class(TObject)
    private
      procedure SetImage(img:TImage);
      procedure SetBgColor(state:TTseIndicateStatus; color:TAlphaColor);
      function GetBgColor(state:TTseIndicateStatus):TAlphaColor;
      procedure SetTxColor(state:TTseIndicateStatus; color:TAlphaColor);
      function GetTxColor(state:TTseIndicateStatus):TAlphaColor;
      procedure SetState(state:TTseIndicateStatus);
      procedure SetText(state:TTseIndicateStatus;text:string);
      function GetText(state:TTseIndicateStatus):string;

      procedure ImageDraw;
    protected
      FImage    : TImage;
      FBitmap   : TBitmap;
      FState    : TTseIndicateStatus;
      FBgColors : Array[Ord(Low(TTseIndicateStatus))..Ord(High(TTseIndicateStatus))] of TAlphaColor;
      FTxColors : Array[Ord(Low(TTseIndicateStatus))..Ord(High(TTseIndicateStatus))] of TAlphaColor;
      FTexts    : Array[Ord(Low(TTseIndicateStatus))..Ord(High(TTseIndicateStatus))] of string;
    public
      constructor Create;
      property BgColors[state:TTseIndicateStatus] : TAlphaColor read GetBgColor write SetBgColor;
      property TxColors[state:TTseIndicateStatus] : TAlphaColor read GetTxColor write SetTxColor;
      property Texts[state:TTseIndicateStatus]    : string read GetText write SetText;
      property State : TTseIndicateStatus read FState write SetState;
    published
      property Image  : TImage read FImage write SetImage;
  end;

implementation

constructor TTscIndicator.Create;
var
  I : TTseIndicateStatus;
  bg, tx  : TAlphaColor;
  txt     : string;
begin
  for I := Low(TTseIndicateStatus) to High(TTseIndicateStatus) do
    begin
      case I of
        IND_STATUS_NONE   :
          begin
            bg  := TAlphaColorRec.White;
            tx  := TAlphaColorRec.Black;
            txt := '';
          end;
        IND_STATUS_OK     :
          begin
            bg  := TAlphaColorRec.Green;
            tx  := TAlphaColorRec.White;
            txt := 'OK';
          end;
        IND_STATUS_NG     :
          begin
            bg  := TAlphaColorRec.Red;
            tx  := TAlphaColorRec.White;
            txt := 'NG';
          end;
        IND_STATUS_WAIT   :
          begin
            bg  := TAlphaColorRec.White;
            tx  := TAlphaColorRec.Black;
            txt := 'WAIT';
          end;
        IND_STATUS_ERROR  :
          begin
            bg  := TAlphaColorRec.Red;
            tx  := TAlphaColorRec.White;
            txt := 'ERROR';
          end;
        IND_STATUS_MEAS   :
          begin
            bg  := TAlphaColorRec.White;
            tx  := TAlphaColorRec.Black;
            txt := 'MEAS';
          end;
      end;

      BgColors[I] := bg;
      TxColors[I] := tx;
      Texts[I]    := txt;
    end;
  FBitmap := TBitmap.Create;
end;

procedure TTscIndicator.SetImage(img:TImage);
begin
  FImage  := img;
  FBitmap.SetSize(Floor(FImage.Width), Floor(FImage.Height));
  FImage.Bitmap.SetSize(FBitmap.Size);
end;

procedure TTscIndicator.SetBgColor(state:TTseIndicateStatus; color:TAlphaColor);
begin
  FBgColors[Ord(state)] := color;
end;

function TTscIndicator.GetBgColor(state:TTseIndicateStatus):TAlphaColor;
begin
  Result  := FBgColors[Ord(state)];
end;

procedure TTscIndicator.SetTxColor(state:TTseIndicateStatus; color:TAlphaColor);
begin
  FTxColors[Ord(state)] := color;
end;

function TTscIndicator.GetTxColor(state:TTseIndicateStatus):TAlphaColor;
begin
  Result  := FTxColors[Ord(state)];
end;

procedure TTscIndicator.SetText(state:TTseIndicateStatus; text:string);
begin
  FTexts[Ord(state)]  := text;
end;

function TTscIndicator.GetText(state:TTseIndicateStatus):string;
begin
  Result  := FTexts[Ord(state)];
end;

procedure TTscIndicator.SetState(state:TTseIndicateStatus);
begin
  FState  := state;
  ImageDraw;
end;

procedure TTscIndicator.ImageDraw;
var
  rct : TRectF;
  I: Integer;
  twid,thgt : Single;
begin
  rct := TRectF.Create(0,0,FBitmap.Width,FBitmap.Height);
  with FBitmap.Canvas do
    begin
      BeginScene;
      Clear(BgColors[FState]);
      Fill.Color  := TxColors[FState];
      for I := 1 to 100 do
        begin
          Font.Size := I;
          twid      := TextWidth(Texts[FState]);
          thgt      := TextHeight(Texts[FState]);
          if ((FBitmap.Width *0.8) < twid) or ((FBitmap.Height *0.8) < thgt) then
            begin
              Font.Size := I-1;
              Break;
            end;
        end;
      FillText( rct,
                Texts[FState],
                False,
                1.0,
                [],
                TTextAlign.Center,
                TTextAlign.Center);
      EndScene;
    end;
  with FImage.Bitmap.Canvas do
    begin
      BeginScene;
      DrawBitmap(FBitmap, rct, rct, 1.0, True);
      EndScene;
    end;
end;

end.
