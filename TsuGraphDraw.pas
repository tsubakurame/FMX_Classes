unit TsuGraphDraw;

interface
uses
  FMX.Graphics, FMX.Objects, Fmx.Types,
  System.Math, System.UITypes, System.Types, System.Classes,
  TsuStrUtils
  ;

type
  TTsrRange = record
    private
      FOnChanged  : TNotifyEvent;
      FTop        : Single;
      FBottom     : Single;
      procedure SetTop(value:Single);
      procedure SetBottom(value:Single);
      procedure SetOnChanged(callback:TNotifyEvent);
    public
      constructor Create(Top,Bottom:Single);
      property Top  : Single read FTop write SetTop;
      property Bottom : Single read FBottom write SetBottom;
      property OnChanged  : TNotifyEvent read FOnChanged write SetOnChanged;
  end;
  TTseScaleMode = (SC_MODE_AUTO, SC_MODE_MANUAL);
  TTseAxisType  = ( AX_TYPE_LINIER,
                    AX_TYPE_LINIER_CENTER_ZERO);
  TTseGraphType = ( GR_TYPE_WAVEFORM,
                    GR_TYPE_WAVEFORM_REALTIME,
                    GR_TYPE_SPECTRAM,
                    GR_TYPE_BAR);
  TTseOverRayType = ( OVR_THRESHOLD_HORZ, OVR_THRESHOLD_VERT,
                      OVR_RANGE_HORZ, OVR_RANGE_VERT,
                      OVR_ON_MOUSE_SURROUND,
                      OVR_SELECT);
  TTsdOverRayTypes  = set of TTseOverRayType;
  TTsrTextAlign = Record
    private
      FVert       : TTextAlign;
      FHorz       : TTextAlign;
      FOnChanged  : TNotifyEvent;
      procedure SetVert(value:TTextAlign);
      procedure SetHorz(value:TTextAlign);
      procedure SetOnChanged(callback:TNotifyEvent);
    public
      constructor Create(vert,horz:TTextAlign);
      property Vert : TTextAlign read FVert write SetVert;
      property Horz : TTextAlign read FHorz write SetHorz;
      property OnChanged  : TNotifyEvent read FOnChanged write SetOnChanged;
  end;
  TTscAxisOptions = class(TObject)
    private
      procedure SetAxisNum(value:UInt16);
      function GetStroke(X:Integer):TStrokeBrush;
      procedure SetStroke(X:Integer;value:TStrokeBrush);
      function GetScaleNum(X:Integer):Single;
      procedure SetScaleNum(X:Integer;value:Single);
      procedure SetUnit(value:string);
      procedure SetAftDigit(value:UInt8);
      procedure SetAxisType(value:TTseAxisType);
      procedure SetScaleMargin(value:Integer);
      procedure SetRange(value:TTsrRange);

      procedure SetOnChanged(callback:TNotifyEvent);
      procedure CallOnChanged;
    protected
      FAxisNum                : UInt16;
      FStroke                 : array of TStrokeBrush;
      FScale                  : TTseScaleMode;
      FScaleNum               : array of Single;
      FUnit                   : String;
      FRange                  : TTsrRange;
      FAfterDecimalPointDigit : UInt8;
      FTextAlign              : TTsrTextAlign;
      FOnChanged              : TNotifyEvent;
      FAxisType               : TTseAxisType;
      FScaleMargin            : Integer;
    public
      constructor Create;
      property AxisNum  : UInt16  read FAxisNum write SetAxisNum; //  OnChanged Call
      property Stroke[X:Integer]  : TStrokeBrush  read GetStroke write SetStroke;
      property ScaleNum[X:Integer]  : Single  read GetScaleNum write SetScaleNum;
      property ScaleMode  : TTseScaleMode read FScale write FScale;
      property UnitString : string read FUnit write SetUnit;  // OnChanged Call
      property Range  : TTsrRange read FRange write SetRange;
      property AfterDecimalPointDigit : UInt8 read FAfterDecimalPointDigit
                                              write SetAftDigit;  // OnChanged Call
      property TextAlign  : TTsrTextAlign read FTextAlign write FTextAlign;
      property AxisType   : TTseAxisType read FAxisType write SetAxisType;  //  OnChanged Call
      property ScaleMargin: Integer read FScaleMargin write SetScaleMargin;
      property OnChanged  : TNotifyEvent read FOnChanged write FOnChanged;
  end;
  TTsrMargins = record
    private
      FOnChanged  : TNotifyEvent;
      FTop        : UInt32;
      FBottom     : UInt32;
      FLeft       : UInt32;
      FRight      : UInt32;
      procedure SetTop(value:UInt32);
      procedure SetBottom(value:UInt32);
      procedure SetLeft(value:UInt32);
      procedure SetRight(value:UInt32);
    public
      constructor Create(Top, Bottom, Left, Right:UInt32);
      property Top    : UInt32 read FTop write SetTop;
      property Bottom : UInt32 read FBottom write SetBottom;
      property Left   : UInt32 read FLeft write SetLeft;
      property Right  : Uint32 read FRight write SetRight;
      property OnChanged  : TNotifyEvent read FOnChanged write FOnChanged;
  end;
  TTscGraphDraw = class(TObject)
    private
      procedure SetGraphImage(cmp:TImage);
      procedure SetAxisImage(cmp:TImage);
      procedure SetOverRayImage(cmp:TImage);
      procedure SetImage(var bmp:TBitmap; var img:TImage);
      procedure SetVertOpt(value:TTscAxisOptions);
      procedure SetHorzOpt(value:TTscAxisOptions);
      procedure SetAutoDraw(value:Boolean);
      procedure SetSamplingRate(value:Integer);
      procedure SetFrameRate(value:Integer);
      procedure SetSelected(value:Boolean);
      procedure SetOnResize(func:TNotifyEvent);

      procedure AutoDrawCheck(Sender:TObject);
      procedure CalcSmpPerPx(Sender:TObject);
      procedure AutoDrawAndCalc(Sender:TObject);

      procedure AxisDraw;overload;
      //procedure AxisDraw(var bmp:TBitmap; var axis:TTscAxisOptions);overload;
      //procedure AxisDrawVertical;
      procedure AxisDrawLinier;

      procedure DrawWaveForm(const data:array of Single);
      procedure DrawWaveFormRT(const data:array of Single);
      procedure DrawSpectram(const data:array of Single);
      procedure DrawBarGraph(const x,y:Single);
      //procedure AxisDrawLinierCenterZero;

      procedure AssignStroke(var bmp:TBitmap; stroke:TStrokeBrush);
      procedure DrawLineBitmap(var bmp:TBitmap; xst,xed,yst,yed:Single);

      procedure OnMouseEnter(Sender:TObject);
      procedure OnMouseLeave(Sender:TObject);
      procedure OnResized(Sender:TObject);
    protected
      FGraphBmp             : TBitmap;
      FAxisBmp              : TBitmap;
      FOverRayBmp           : TBitmap;
      FGraphImg             : TImage;
      FAxisImg              : TImage;
      FOverRayImg           : TImage;
      FAutoDraw             : Boolean;
      FMargins              : TTsrMargins;
      FVertical             : TTscAxisOptions;
      FHorizontal           : TTscAxisOptions;
      FBGColor              : TAlphaColor;
      FTextColor            : TAlphaColor;
      FGraphColor           : TAlphaColor;

      FGraphType            : TTseGraphType;
      //  FGraphTypeに応じて使用される変数
      FSamplingRate         : Integer;
      FFFTSample            : Integer;
      FSmpPerPx             : Single;
      FDataCnt              : Integer;
      FDrawCnt              : Integer;
      FBDrawPoint           : Integer;
      FDrawPoint            : Integer;
      FFrameRate            : Integer;
      FFramePerSmp          : Integer;
      FBarNumPerDiv         : Integer;
      FBarMargin            : Integer;

      FOverRayTypes         : TTsdOverRayTypes;
      //  FOverRayTypesに応じて使用される変数
      FThresholdHorz        : Single;
      FThresholdVert        : Single;
      FRangeHorz            : TTsrRange;
      FRangeVert            : TTsrRange;
      FOnMouse              : Boolean;
      FSelected             : Boolean;
      FOnResizeEnable       : Boolean;
      FOnResize             : TNotifyEvent;
    public
      constructor Create;
      procedure AddData(const buf : array of Single);overload;
      procedure AddData(const x,y : Single);overload;

      procedure AxisDrawToImage;
      procedure GraphDrawToImage;
      procedure OverRayDrawToImage;
      procedure DrawParamsClear;
      procedure GraphReset;
      procedure DrawOverRay;

      property GraphImage : TImage read FGraphImg write SetGraphImage;
      property AxisImage  : TImage read FAxisImg write SetAxisImage;
      property OverRayImage : TImage read FOverRayImg write SetOverRayImage;
      property GraphColor : TAlphaColor read FGraphColor write FGraphColor;
      //  True  ：各プロパティが変更された際に、その設定値で自動的に書き直す
      property AutoDraw   : Boolean read FAutoDraw write SetAutoDraw;
      //  AutoDrawプロパティに関連するグラフパラメータ
      //property AxisType   : TTseAxisType read FGraphType write FGraphType;
      property Margins    : TTsrMargins read FMargins write FMargins;
      property Vertical   : TTscAxisOptions read FVertical write SetVertOpt;
      property Horizontal : TTscAxisOptions read FHorizontal write SetHorzOpt;

      property GraphType  : TTseGraphType read FGraphType write FGraphType;
      //  GraphTypeに応じて使用されるプロパティ
      property SamplingRate : Integer read FSamplingRate write SetSamplingRate;
      property FrameRate  : Integer read FFrameRate write SetFrameRate;
      property FFTSample  : Integer read FFFTSample write FFFTSample;
      property BarNumPerDiv : Integer read FBarNumPerDiv write FBarNumPerDiv;
      property BarMargin  : Integer read FBarMargin write FBarMargin;

      property OverRayTypes : TTsdOverRayTypes read FOverRayTypes write FOverRayTypes;
      //  OverRayTypesに応じて使用されるプロパティ
      property ThresholdHorz  : Single read FThresholdHorz write FThresholdHorz;
      property ThresholdVert  : Single read FThresholdVert write FThresholdVert;
      property RangeHorz      : TTsrRange read FRangeHorz write FRangeHorz;
      property RangeVert      : TTsrRange read FRangeVert write FRangeVert;
      property Selected       : Boolean read FSelected write SetSelected;

      property OnResizeEnable : Boolean read FOnResizeEnable write FOnResizeEnable;
      property OnResize       : TNotifyEvent read FOnResize write SetOnResize;
  end;

implementation

{$region'    TTsrRange    '}
constructor TTsrRange.Create(Top,Bottom:Single);
begin
  FTop    := Top;
  FBottom := Bottom;
end;

procedure TTSrRange.SetTop(value:Single);
begin
  FTop  := value;
  if Assigned(FOnChanged) then
    FOnChanged(nil);
end;

procedure TTsrRange.SetBottom(value:Single);
begin
  FBottom := value;
  if Assigned(FOnChanged) then
    FOnChanged(nil);
end;

procedure TTsrRange.SetOnChanged(callback:TNotifyEvent);
begin
  FOnChanged  := callback;
end;
{$endregion}

{$region'    TTsrTextAlign    '}
constructor TTsrTextAlign.Create(vert,horz:TTextAlign);
begin
  FVert := vert;
  FHorz := horz;
end;

procedure TTsrTextAlign.SetVert(value:TTextAlign);
begin
  FVert := value;
  if Assigned(FOnChanged) then
    FOnChanged(nil);
end;

procedure TTsrTextAlign.SetHorz(value:TTextAlign);
begin
  FHorz := value;
  if Assigned(FOnChanged) then
    FOnChanged(nil);
end;

procedure TTsrTextAlign.SetOnChanged(callback:TNotifyEvent);
begin
  FOnChanged  := callback;
end;
{$endregion}

{$region'    TTscAxisOptions    '}
constructor TTscAxisOptions.Create;
begin
  //FAxisNum  := 5;
  FAxisNum    := 0;
  FScale      := SC_MODE_AUTO;
  FTextAlign  := TTsrTextAlign.Create(TTextAlign.Center, TTextAlign.Center);
  FTextAlign.OnChanged  := FOnChanged;
  FRange            := TTsrRange.Create(0,0);
  FRange.OnChanged  := FOnChanged;
end;

procedure TTscAxisOptions.SetAxisNum(value:UInt16);
var
  I: Integer;
begin
  SetLength(FStroke, value);
  SetLength(FScaleNum, value);
  for I := FAxisNum to value -1 do
    begin
      if FStroke[I] = nil then FStroke[I] := TStrokeBrush.Create(TBrushKind.Solid, TAlphaColorRec.Black);
    end;
  FAxisNum  := value;
  CallOnChanged;
end;

function TTscAxisOptions.GetStroke(X:Integer):TStrokeBrush;
begin
  Result  := FStroke[X];
end;

procedure TTscAxisOptions.SetStroke(X:Integer;value:TStrokeBrush);
begin
  FStroke[X]  := value;
end;

function TTscAxisOptions.GetScaleNum(X:Integer):Single;
begin
  Result  := FScaleNum[X];
end;

procedure TTscAxisOptions.SetScaleNum(X:Integer;value:Single);
begin
  FScaleNum[X]  := value;
end;

procedure TTscAxisOptions.SetOnChanged(callback:TNotifyEvent);
begin
  FOnChanged        := callback;
  FRange.OnChanged := FOnChanged;
end;

procedure TTscAxisOptions.SetUnit(value:string);
begin
  FUnit := value;
  CallOnChanged;
end;

procedure TTscAxisOptions.SetAftDigit(value:UInt8);
begin
  FAfterDecimalPointDigit := value;
  CallOnChanged;
end;

procedure TTscAxisOptions.SetAxisType(value:TTseAxisType);
begin
  FAxisType := value;
  CallOnChanged;
end;

procedure TTscAxisOptions.SetScaleMargin(value:Integer);
begin
  FScaleMargin  := value;
  CallOnChanged;
end;

procedure TTscAxisOptions.SetRange(value: TTsrRange);
begin
  FRange  := value;
  CallOnChanged;
end;

procedure TTscAxisOptions.CallOnChanged;
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;
{$endregion}

{$region'    TTscMargins    '}

constructor TTsrMargins.Create(Top, Bottom, Left, Right:UInt32);
begin
  FTop    := Top;
  FBottom := Bottom;
  FLeft   := Left;
  FRight  := Right;
end;

procedure TTsrMargins.SetTop(value:UInt32);
begin
  FTop  := value;
  if Assigned(FOnChanged) then
    FOnChanged(nil);
end;

procedure TTsrMargins.SetBottom(value:UInt32);
begin
  FBottom  := value;
  if Assigned(FOnChanged) then
    FOnChanged(nil);
end;

procedure TTsrMargins.SetLeft(value:UInt32);
begin
  FLeft  := value;
  if Assigned(FOnChanged) then
    FOnChanged(nil);
end;

procedure TTsrMargins.SetRight(value:UInt32);
begin
  FRight  := value;
  if Assigned(FOnChanged) then
    FOnChanged(nil);
end;
{$endregion}

{$region'    TTscGraphDraw    '}
constructor TTscGraphDraw.Create;
begin
  FGraphBmp := TBitmap.Create;
  FAxisBmp  := TBitmap.Create;
  FOverRayBmp := TBitmap.Create;
  FGraphImg := nil;
  FAxisImg  := nil;
  FOverRayImg := nil;
  FAutoDraw := False;

  FVertical := TTscAxisOptions.Create;
  FHorizontal := TTscAxisOptions.Create;

  FVertical.TextAlign.Horz  := TTextAlign.Center;
  FVertical.TextAlign.Vert  := TTextAlign.Leading;

  FHorizontal.TextAlign.Horz:= TTextAlign.Trailing;
  FHorizontal.TextAlign.Vert:= TTextAlign.Leading;

  FHorizontal.OnChanged := AutoDrawCheck;
  FVertical.OnChanged   := AutoDrawCheck;

  FMargins  := TTsrMargins.Create(0,0,0,0);
  FMargins.OnChanged := AutoDrawAndCalc;

  FBGColor  := TAlphaColorRec.White;
  FTextColor:= TAlphaColorRec.Black;

  FOnMouse  := False;
  FSelected := False;
  DrawParamsClear;
end;

{$region'    プロパティメソッド    '}
procedure TTscGraphDraw.SetGraphImage(cmp:TImage);
begin
  FGraphImg  := cmp;
  FGraphImg.OnResize  := OnResized;
  SetImage(FGraphBmp, FGraphImg);
end;

procedure TTscGraphDraw.SetAxisImage(cmp:TImage);
begin
  FAxisImg  := cmp;
  SetImage(FAxisBmp, FAxisImg);
  AutoDrawCheck(Self);
end;

procedure TTscGraphDraw.SetOverRayImage(cmp:TImage);
begin
  FOverRayImg := cmp;
  SetImage(FOverRayBmp, FOverRayImg);
  FOverRayImg.OnMouseEnter  := OnMouseEnter;
  FOverRayImg.OnMouseLeave  := OnMouseLeave;
end;

procedure TTscGraphDraw.SetVertOpt(value:TTscAxisOptions);
begin
  FVertical := value;
  //AutoDrawCheck;
end;

procedure TTscGraphDraw.SetHorzOpt(value:TTscAxisOptions);
begin
  FHorizontal := value;
  //AutoDrawCheck;
end;

procedure TTscGraphDraw.SetAutoDraw(value:Boolean);
begin
  FAutoDraw := value;
  AutoDrawCheck(Self);
end;

procedure TTscGraphDraw.SetSamplingRate(value:Integer);
begin
  FSamplingRate := value;
  CalcSmpPerPx(Self);
end;

procedure TTscGraphDraw.SetFrameRate(value:Integer);
begin
  FFrameRate  := value;
  FFramePerSmp  := Floor((FGraphBmp.Width -Margins.Left -Margins.Right) / (Vertical.Range.Top - Vertical.Range.Bottom) / 1000 * FFrameRate);
end;

procedure TTscGraphDraw.SetSelected(value:Boolean);
begin
  if FSelected <> value then
    begin
      FSelected := value;
      DrawOverRay;
    end;
end;

procedure TTscGraphDraw.SetOnResize(func:TNotifyEvent);
begin
  if Assigned(func) then
    FOnResizeEnable := True
  else
    FOnResizeEnable := False;
  FOnResize := func;
end;
{$endregion}

procedure TTscGraphDraw.CalcSmpPerPx(Sender:TObject);
begin
  FSmpPerPx   := FSamplingRate*FVertical.Range.Top / (FGraphBmp.Width - FMargins.Left -FMargins.Right);
end;

procedure TTscGraphDraw.AutoDrawCheck(Sender:TObject);
begin
  if FAutoDraw then
    begin
      if FAxisImg <> nil then
        begin
          AxisDraw;
          AxisDrawToImage;
        end;
    end;
end;

procedure TTscGraphDraw.AutoDrawAndCalc(Sender:TObject);
begin
  CalcSmpPerPx(Sender);
  AutoDrawCheck(Sender);
end;

procedure TTscGraphDraw.AxisDrawToImage;
var
  rct : TRectF;
begin
  with FAxisImg.Bitmap.Canvas do
    begin
      try
        BeginScene;
        rct := TRect.Create(  0, 0,
                              FAxisBmp.Width,
                              FAxisBmp.Height);
        DrawBitmap(FAxisBmp, rct, rct, 1.0);
      finally
        EndScene;
      end;
    end;
end;

procedure TTscGraphDraw.GraphDrawToImage;
var
  rct : TRectF;
begin
  with FGraphImg.Bitmap.Canvas do
    begin
      try
        BeginScene;
        case FGraphType of
          GR_TYPE_WAVEFORM_REALTIME :
            begin
              rct := TRect.Create(  FBDrawPoint+Margins.Left, 0,
                                    FDrawPoint+Margins.Left,
                                    FGraphBmp.Height);
            end;
          GR_TYPE_WAVEFORM,
          GR_TYPE_SPECTRAM,
          GR_TYPE_BAR  :
            begin
              Clear(0);
              rct := TRect.Create(  0, 0, FGraphBmp.Width, FGraphBmp.Height);
            end;
        end;
        FBDrawPoint := FDrawPoint;
        DrawBitmap(FGraphBmp, rct, rct, 1.0);
      finally
        EndScene;
      end;
    end;
end;

procedure TTscGraphDraw.OverRayDrawToImage;
var
  rct : TRectF;
begin
  with FOverRayImg.Bitmap.Canvas do
    begin
      try
        BeginScene;
        Clear(0);
        rct := TRect.Create(  0, 0,
                              FOverRayBmp.Width,
                              FOverRayBmp.Height);
        DrawBitmap(FOverRayBmp, rct, rct, 1.0);
      finally
        EndScene;
      end;
    end;
end;

procedure TTscGraphDraw.SetImage(var bmp:TBitmap; var img:TImage);
begin
  bmp.SetSize(Floor(img.Width), Floor(img.Height));
  img.Bitmap.SetSize(bmp.Size);
end;

procedure TTscGraphDraw.AssignStroke(var bmp:TBitmap; stroke:TStrokeBrush);
begin
  with bmp.Canvas.Stroke do
    begin
      Dash        := stroke.Dash;
      Thickness   := stroke.Thickness;
      Color       := stroke.Color;
      Kind        := stroke.Kind;
    end;
end;

procedure TTscGraphDraw.DrawLineBitmap(var bmp:TBitmap; xst,xed,yst,yed:Single);
begin
  bmp.Canvas.DrawLine(TPointF.Create(xst, yst), TPointF.Create(xed, yed), 1.0);
end;

procedure TTscGraphDraw.AxisDraw;
begin
  {
  case FGraphType of
    GTYPE_LINIER              : AxisDrawLinier;
    GTYPE_LINIER_CENTER_ZERO  : AxisDrawLinier;
  end;
  }
  //AxisDrawVertical;
  AxisDrawLinier;
end;

procedure TTscGraphDraw.AxisDrawLinier;
var
  X, Y: Integer;
  x_st, x_ed, y_st, y_ed  : Single;
  sc_val  : Single;
  text  : string;
  t_width, t_height : Single;
  t_rect  : TRectF;
  range   : Single;
begin
  with FAxisBmp.Canvas do
    begin
      BeginScene;
      Clear(FBGColor);
      //Clear(0);

      for X := 0 to FHorizontal.AxisNum -1 do
        begin
          range := FHorizontal.Range.Top - FHorizontal.Range.Bottom;
          AssignStroke(FAxisBmp, FHorizontal.Stroke[X]);
          case Horizontal.ScaleMode of
            SC_MODE_AUTO:
              begin
                sc_val  := (range / (FHorizontal.AxisNum-1) *(FHorizontal.AxisNum -1 -X));
              end;
            SC_MODE_MANUAL: ;
          end;
          x_st  := FMargins.Left;
          x_ed  := FAxisBmp.Width - Margins.Right;
          y_st  := (FAxisBmp.Height -Margins.Top -Margins.Bottom) / (range) * (range -sc_val) +Margins.Top;
          y_ed  := y_st;
          //sc_val  := FHorizontal.Range.Top -sc_val;
          sc_val  := sc_val + FHorizontal.Range.Bottom;
          text  := TsfFloatToStrTrunc(sc_val, FHorizontal.AfterDecimalPointDigit)+FHorizontal.UnitString;
          t_height := TextHeight(text) / 2;
          t_rect  := TRectF.Create(0, y_st -t_height, Margins.Left -FHorizontal.ScaleMargin, y_st +t_height);
          DrawLineBitmap(FAxisBmp, x_st, x_ed, y_st, y_ed);
          Fill.Color  := FTextColor;
          FillText(t_rect, text, True, 1.0, [], FHorizontal.TextAlign.Horz, FHorizontal.TextAlign.Vert);
        end;

      for Y := 0 to FVertical.AxisNum-1 do
        begin
          AssignStroke(FAxisBmp, FVertical.Stroke[Y]);
          range := FVertical.Range.Top - FVertical.Range.Bottom;
          case Vertical.ScaleMode of
            SC_MODE_AUTO    :
              begin
                sc_val  := (range) / (FVertical.AxisNum-1) *Y;
              end;
            SC_MODE_MANUAL  : ;
          end;
          x_st  := Floor((FAxisBmp.Width -Margins.Left -Margins.Right) / range *sc_val +(Margins.Left));
          x_ed  := x_st;
          y_st  := Margins.Top;
          y_ed  := FAxisBmp.Height -(Margins.Bottom);
          text  := TsfFloatToStrTrunc(sc_val, FVertical.AfterDecimalPointDigit)+FVertical.UnitString;
          t_width := TextWidth(text) / 2;
          t_rect  := TRectF.Create(x_st -t_width, y_ed+FVertical.ScaleMargin, x_st+t_width, FAxisBmp.Height);
          DrawLineBitmap(FAxisBmp, x_st, x_ed, y_st, y_ed);
          Fill.Color  := FTextColor;
          FillText(t_rect, text, True, 1.0, [], FVertical.TextAlign.Horz, FVertical.TextAlign.Vert);
        end;

      EndScene;
    end;
  {$IFDEF DEBUG}
  FAxisBmp.SaveToFile('Axis.bmp');
  {$ENDIF}
end;

procedure TTscGraphDraw.AddData(const buf : array of Single);
begin
  case FGraphType of
    GR_TYPE_WAVEFORM          : DrawWaveForm(buf);
    GR_TYPE_WAVEFORM_REALTIME : DrawWaveFormRT(buf);
    GR_TYPE_SPECTRAM          : DrawSpectram(buf);
  end;
end;

procedure TTscGraphDraw.AddData(const x: Single; const y: Single);
begin
  case FGraphType of
    GR_TYPE_WAVEFORM: ;
    GR_TYPE_WAVEFORM_REALTIME: ;
    GR_TYPE_SPECTRAM: ;
    GR_TYPE_BAR     : DrawBarGraph(x,y);
  end;
end;

procedure TTscGraphDraw.DrawWaveForm(const data:array of Single);
var
  pt_per_px : Single;
  I: Integer;
  max,min : Single;
  draw_cnt  : Integer;
  xst,yst,xed,yed : Single;
  wid, hgt : Integer;
  range : Single;
begin
  FGraphBmp.Canvas.BeginScene;
  FGraphBmp.Canvas.Clear(0);
  pt_per_px := Length(data) / FGraphBmp.Width;
  max := MinSingle;
  min := MaxSingle;
  draw_cnt  := 1;
  hgt := FGraphBmp.Height -FMargins.Top -FMargins.Bottom;
  range := FHorizontal.Range.Top -FHorizontal.Range.Bottom;
  for I := 0 to Length(data)-1 do
    begin
      if max < data[I] then max := data[I];
      if min > data[I] then min := data[I];
      if I = Floor(pt_per_px*draw_cnt) then
        begin
          FGraphBmp.Canvas.Stroke.Color := FGraphColor;
          xst := draw_cnt +FMargins.Left;
          xed := xst;
          yst := hgt - ((max -FHorizontal.Range.Bottom) / range * hgt) +FMargins.Top;
          yed := hgt - ((min -FHorizontal.Range.Bottom) / range * hgt) +FMargins.Top;
          DrawLineBitmap(FGraphBmp,xst,xed,yst,yed);
          inc(draw_cnt);
          max := MinSingle;
          min := MaxSingle;
        end;
    end;
  FGraphBmp.Canvas.EndScene;
  FGraphBmp.SaveToFile('gp.bmp');
  GraphDrawToImage;
end;

procedure TTscGraphDraw.DrawWaveFormRT(const data:array of Single);
var
  xst,yst,xed,yed : Single;
  wid, hgt : Integer;
  range : Single;
  I : Integer;
  FMax,FMin             : Single;
begin
  for I := 0 to Length(data) do
    begin
      if FMax < data[I] then FMax  := data[I];
      if FMin > data[I] then FMin  := data[I];
      Inc(FDataCnt);
      if FDataCnt = Floor(FSmpPerPx*FDrawCnt) then
        begin
          //  描画する
          with FGraphBmp.Canvas do
            begin
              BeginScene;
              Stroke.Color  := FGraphColor;
              wid := FGraphBmp.Width -FMargins.Left -FMargins.Right;
              hgt := FGraphBmp.Height -FMargins.Top -FMargins.Bottom;
              range := FHorizontal.Range.Top -FHorizontal.Range.Bottom;
              FDrawPoint  := (FDrawCnt mod wid);
              xst := FDrawPoint + FMargins.Left;
              xed := xst;
              yst := hgt - ((FMax -FHorizontal.Range.Bottom) / range * hgt) +FMargins.Top;
              yed := hgt - ((FMin -FHorizontal.Range.Bottom) / range * hgt) +FMargins.Top;
              DrawLineBitmap(FGraphBmp,xst,xed,yst,yed);
              EndScene;
            end;
          if (FDrawPoint - FBDrawPoint) >= FFramePerSmp then
            GraphDrawToImage;

          Inc(FDrawCnt);
          FMax  := MinSingle;
          FMin  := MaxSingle;
        end;
    end;
end;

procedure TTscGraphDraw.DrawSpectram(const data:array of Single);
var
  wid : Integer;
  I: Integer;
  range : Single;
  freq  : Single;
  idx   : Integer;
  reso  : Single;
  value : Single;
  y     : Integer;
  max, min : Single;
  hgt   : Integer;
  b_x, b_y  : Integer;
begin
  wid     := FGraphBmp.Width -Margins.Left -Margins.Right;
  hgt     := FGraphBmp.Height -Margins.Top -Margins.Bottom;
  range   := FVertical.Range.Top -FVertical.Range.Bottom;
  reso    := FSamplingRate / FFFTSample;
  max     := FHorizontal.Range.Top;
  min     := FHorizontal.Range.Bottom;

  FGraphBmp.Canvas.BeginScene;
  FGraphBmp.Canvas.Stroke.Color := FGraphColor;
  FGraphBmp.Canvas.Clear(0);
  for I := 0 to wid -1 do
    begin
      freq  := (range / wid) * I;
      idx   := Round(freq / reso);
      if not (idx > FFTSample div 2) then
        value := data[idx];
      y      := Floor(((max - value) / (max - min))*hgt);
      if y >= hgt then y := hgt;
      if I <> 0 then
        begin
          DrawLineBitmap( FGraphBmp,
                          I-1+Margins.Left,
                          I+Margins.Left,
                          b_y+Margins.Top,
                          y+Margins.Top);
        end;
      b_y := y;
    end;
  FGraphBmp.Canvas.EndScene;
  //FGraphBmp.SaveToFile('graph.bmp');
  GraphDrawToImage;
end;

procedure TTscGraphDraw.DrawBarGraph(const x: Single; const y: Single);
var
  xpos  : Single;
  ypos  : Single;
  wid,hgt   : Integer;
  barwid  : Integer;
  clr_rct, bar_rct : TRectF;
begin
  FGraphBmp.Canvas.BeginScene;
  wid   := FGraphBmp.Width -Margins.Left -Margins.Right;
  hgt   := FGraphBmp.Height -Margins.Top -Margins.Left;
  barwid:= Floor(wid / (FBarNumPerDiv * FVertical.AxisNum-1));
  xpos  := wid * ((x-FVertical.Range.Bottom) / (FVertical.Range.Top-FVertical.Range.Bottom));
  ypos  := hgt - hgt * ((y-FHorizontal.Range.Bottom) / (FHorizontal.Range.Top-FHorizontal.Range.Bottom));
  if ypos > hgt then ypos := hgt;  
  FGraphBmp.Canvas.Fill.Color := 0;
  FGraphBmp.Canvas.FillRect(TRectF.Create(xpos,
                                          0,
                                          xpos+barwid,
                                          FGraphBmp.Height),0,0,[],1);
  bar_rct := TRectF.Create( xpos+FMargins.Left,
                            ypos+FMargins.Top,
                            xpos+barwid+FMargins.Left,
                            hgt+FMargins.Top);
  FGraphBmp.Canvas.Fill.Color := TAlphaColorRec.White;
  FGraphBmp.Canvas.FillRect(bar_rct, 0,0,[],1);
  FGraphBmp.Canvas.DrawRect(bar_rct,0,0,[],1);
  FGraphBmp.Canvas.EndScene;
  GraphDrawToImage;
end;

procedure TTscGraphDraw.DrawParamsClear;
begin
  FDrawCnt  := 1;
  FDataCnt  := 0;
  //FMax  := MinSingle;
  //FMin  := MaxSingle;
  FDrawPoint  := 0;
  FBDrawPoint := 0;
end;

procedure TTscGraphDraw.GraphReset;
begin
  FGraphBmp.Canvas.BeginScene;
  FGraphBmp.Canvas.Clear(0);
  FGraphBmp.Canvas.EndScene;
  FGraphImg.Bitmap.Canvas.BeginScene;
  FGraphImg.Bitmap.Canvas.Clear(0);
  FGraphImg.Bitmap.Canvas.EndScene;
end;

procedure TTscGraphDraw.DrawOverRay;
var
  I: TTseOverRayType;
  hgt : Integer;
  wid : Integer;
  max, min : Single;
  y : Integer;
  xst,xed,yst,yed : Single;
  rct : TRectF;
begin
  FOverRayBmp.Canvas.BeginScene;
  FOverRayBmp.Canvas.Clear(0);
  hgt := FOverRayBmp.Height -FMargins.Top -FMargins.Bottom;
  wid := FOverRayBmp.Width -FMargins.Left -FMargins.Right;
  for I := Low(TTseOverRayType) to High(TTSeOverRayType) do
    begin
      if I in FOverRayTypes then
        begin
          case I of
            OVR_THRESHOLD_HORZ  : {$region'    横軸閾値描画    '}
              begin
                max := FHorizontal.Range.Top;
                min := FHorizontal.Range.Bottom;
                y      := Floor(((max - FThresholdHorz) / (max - min))*hgt);
                FOverRayBmp.Canvas.Stroke.Color := TAlphaColorRec.Red;
                FOverRayBmp.Canvas.Stroke.Dash  := TStrokeDash.Dash;
                FOverRayBmp.Canvas.DrawLine(TPointF.Create(FMargins.Left, y+Margins.Top),
                                            TPointF.Create(FOverRayBmp.Width -Margins.Right, y+Margins.Top),
                                            1.0);
              end;{$endregion}
            OVR_THRESHOLD_VERT  : ;
            OVR_RANGE_HORZ      : ;
            OVR_RANGE_VERT      : {$region'    縦軸領域描画    '}
              begin
                max := FVertical.Range.Top;
                min := FVertical.Range.Bottom;
                FOverRayBmp.Canvas.Fill.Color := TAlphaColorRec.Red;
                xst := ((wid / (FVertical.Range.Top -FVertical.Range.Bottom)) * FRangeVert.Bottom)+Margins.Left;
                xed := ((wid / (FVertical.Range.Top -FVertical.Range.Bottom)) * FRangeVert.Top)+Margins.Left;
                yst := FMargins.Top;
                yed := FOverRayBmp.Height -FMargins.Bottom;
                rct := TRectF.Create(xst, yst, xed, yed);
                FOverRayBmp.Canvas.FillRect(rct,0,0,[],0.3);
              end;{$endregion}
            OVR_ON_MOUSE_SURROUND :
              begin
                if FOnMouse then
                  begin
                    FOverRayBmp.Canvas.Stroke.Color := TAlphaColorRec.Green;
                    FOverRayBmp.Canvas.Stroke.Thickness := 5;
                    FOverRayBmp.Canvas.DrawRect(TRectF.Create(0,0,FOverRayBmp.Width,FOverRayBmp.Height),
                                                0,0,AllCorners,1.0);
                  end;
              end;
            OVR_SELECT  :
              begin
                if FSelected then
                  begin
                    FOverRayBmp.Canvas.Stroke.Color := TAlphaColorRec.Red;
                    FOverRayBmp.Canvas.Stroke.Thickness := 5;
                    FOverRayBmp.Canvas.DrawRect(TRectF.Create(0,0,FOverRayBmp.Width,FOverRayBmp.Height),
                                                0,0,AllCorners,1.0);
                  end;
              end;
          end;
        end;
    end;
  FOverRayBmp.Canvas.EndScene;
  //FOverRayBmp.SaveToFile('ovr.bmp');
  OverRayDrawToImage;
end;

procedure TTscGraphDraw.OnMouseEnter(Sender:TObject);
begin
  if OVR_ON_MOUSE_SURROUND in FOverRayTypes then
    begin
      FOnMouse  := True;
      DrawOverRay;
    end;
end;

procedure TTscGraphDraw.OnMouseLeave(Sender:TObject);
begin
  if OVR_ON_MOUSE_SURROUND in FOverRayTypes then
    begin
      FOnMouse  := False;
      DrawOverRay;
    end;
end;

procedure TTscGraphDraw.OnResized(Sender:TObject);
begin
  if FOnResizeEnable then
    begin
      if Assigned(FGraphImg) then
        SetImage(FGraphBmp, FGraphImg);
      if Assigned(FAxisImg) then
        SetImage(FAxisBmp, FAxisImg);
      AutoDrawCheck(Self);
      if Assigned(FOnResize) then
        FOnResize(Self);
    end;
end;
{$endregion}

end.
