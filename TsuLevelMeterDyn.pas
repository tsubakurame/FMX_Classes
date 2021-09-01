unit TsuLevelMeterDyn;

interface

uses
  System.Math, System.UITypes, System.Classes, System.Types,
  System.Generics.Collections, System.SysUtils,
  FMX.Objects, FMX.Layouts, FMX.Types, FMX.Graphics, FMX.Controls;

type
  TTsdScaleSet  = Array of Integer;
  TTscScaleLayout = class(TObject)
  private
    FAOwner: TComponent;
    FLyParent: TLayout;
    FLyUnit: TLayout;
    FLyLine: TLayout;
    FLine: TLine;
    FText: TText;
    FOrientation: TOrientation;
    FColor        : TAlphaColor;
    procedure Init;
    procedure Resize;
    procedure SetText(txt: string);
    function GetText: string;
    procedure SetPosition(value: Double);
    function GetPosition: Double;
    procedure SetOrientation(value: TOrientation);
    procedure SetColor(color:TAlphaColor);
  public
    constructor Create(AOwner: TComponent; parent: TLayout);
    property Text: string read GetText write SetText;
    property Position: Double read GetPosition write SetPosition;
    property Orientation: TOrientation read FOrientation write SetOrientation;
    property Color  : TAlphaColor read FColor write SetColor;
  end;

  TTscLevelMeterScale = class(TObject)
  private
    FAOwner: TComponent;
    FParent: TLayout;
    FLyScale: TLayout;
    FScUnitList: TList<TTscScaleLayout>;
    FOrientation: TOrientation;
    FColor  : TAlphaColor;
    procedure SetOrientation(value: TOrientation);
    procedure Resize;
    procedure SetColor(color:TAlphaColor);
  public
    constructor Create(AOwner: TComponent; parent: TLayout);
    destructor Destroy;override;
    procedure Add;
    property UnitList: TList<TTscScaleLayout> read FScUnitList
      write FScUnitList;
    property Orientation: TOrientation read FOrientation write SetOrientation;
    property Color  : TAlphaColor read FColor write SetColor;
  end;

  TTscLevelMeterDyn = class(TObject)
  private
    FBar: TLayout;
    FAOwner: TComponent;
    FLyBar: TLayout;
    FLyScaleL, FLyScaleR: TLayout;
    FLyRed, FLyYellow, FLyGreen: TLayout;
    FRaRed, FRaYellow, FRaGreen: TRectangle;
    FRaDRed, FRaDYellow, FRaDGreen: TRectangle;
    // FScaleBarRY : TLine;
    FMax, FMin: Double;
    FRange: Double;
    FRYBorder: Double;
    FYGBorder: Double;
    FValue: Double;
    FScaleList: TTscLevelMeterScale;
    FOrientation : TOrientation;
    FScaleSet     : TTsdScaleSet;
    FScaleColor   : TAlphaColor;
    procedure BarInit;
    procedure Resize;

    procedure SetValue(value: Double);
    procedure SetOrientation(value:TOrientation);
    procedure SetScaleSet(sets  : TTsdScaleSet);
    procedure SetScaleColor(color:TAlphaColor);
  public
    constructor Create(AOwner: TComponent; bar: TLayout);
    destructor Destroy;override;

    property value: Double read FValue write SetValue;
    property Orientation: TOrientation read FOrientation write SetOrientation;
    property ScaleSet : TTsdScaleSet read FScaleSet write SetScaleSet;
    property ScaleColor : TAlphaColor read FScaleColor write SetScaleColor;
  end;

implementation

{$REGION'    TTscScaleLayout    '}

constructor TTscScaleLayout.Create(AOwner: TComponent; parent: TLayout);
begin
  FAOwner := AOwner;
  FLyParent := parent;
  FOrientation := TOrientation.Vertical;
  Init;
  Resize;
end;

procedure TTscScaleLayout.Init;
begin
  FLyUnit := TLayout.Create(FAOwner);
  FLyUnit.parent := FLyParent;

  FLyLine := TLayout.Create(FAOwner);
  FLyLine.parent := FLyUnit;

  FLine := TLine.Create(FAOwner);
  FLine.parent := FLyLine;

  FText := TText.Create(FAOwner);
  FText.parent := FLyUnit;
  FText.Align := TAlignLayout.Client;
end;

procedure TTscScaleLayout.SetText(txt: string);
begin
  FText.Text := txt;
end;

function TTscScaleLayout.GetText: string;
begin
  Result := FText.Text;
end;

procedure TTscScaleLayout.SetPosition(value: Double);
begin
  case FOrientation of
    TOrientation.Horizontal : FLyUnit.Position.X := value - (FLyUnit.Width / 2);
    TOrientation.Vertical   : FLyUnit.Position.Y := value - (FLyUnit.Height / 2);
  end;
end;

function TTscScaleLayout.GetPosition: Double;
begin
  case FOrientation of
    TOrientation.Horizontal : Result := FLyUnit.Position.X + (FLyUnit.Width / 2);
    TOrientation.Vertical   : Result := FLyUnit.Position.Y + (FLyUnit.Height / 2);
  end;
end;

procedure TTscScaleLayout.SetOrientation(value: TOrientation);
begin
  FOrientation := value;
  Resize;
end;

procedure TTscScaleLayout.SetColor(color:TAlphaColor);
begin
  FColor  := color;
  FText.Color := color;
  FLine.Stroke.Color  := color;
end;

procedure TTscScaleLayout.Resize;
begin
  case FOrientation of
    TOrientation.Horizontal:
      begin
        FLyUnit.Align := TAlignLayout.Vertical;
        FLyUnit.Width := 20;
        FLyLine.Align := TAlignLayout.Top;
        FLyLine.Height := 5;
        FLine.Align := TAlignLayout.Right;
        FLine.Width := (FLyLine.Width / 2);
        FLine.LineType := TLineType.Left;
        FText.HorzTextAlign := TTextAlign.Center;
        FText.VertTextAlign := TTextAlign.Leading;
      end;
    TOrientation.Vertical:
      begin
        FLyUnit.Align := TAlignLayout.Horizontal;
        FLyUnit.Height := 20;
        FLyLine.Align := TAlignLayout.Right;
        FLyLine.Width := 5;
        FLine.Align := TAlignLayout.Bottom;
        FLine.Height := (FLyLine.Height / 2);
        FLine.LineType := TLineType.Top;
        FText.HorzTextAlign := TTextAlign.Trailing;
        FText.VertTextAlign := TTextAlign.Center;
      end;
  end;
end;
{$ENDREGION}
{$REGION'    TTscLevelMeterScale    '}

constructor TTscLevelMeterScale.Create(AOwner: TComponent; parent: TLayout);
begin
  FAOwner := AOwner;
  FParent := parent;
  FScUnitList := TList<TTscScaleLayout>.Create;
  FLyScale := TLayout.Create(FAOwner);
  FLyScale.parent := FParent;
  FOrientation := TOrientation.Vertical;
  Resize;
end;

destructor TTscLevelMeterScale.Destroy;
var
  I: Integer;
begin
  for I := 0 to FScUnitList.Count -1 do
    FScUnitList[I].Free;
  FScUnitList.Free;
  inherited Destroy;
end;

procedure TTscLevelMeterScale.Add;
begin
  FScUnitList.Add(TTscScaleLayout.Create(FAOwner, FLyScale));
end;

procedure TTscLevelMeterScale.Resize;
begin
  case FOrientation of
    TOrientation.Horizontal:
      begin
        FLyScale.Align := TAlignLayout.Bottom;
        FLyScale.Height := 30;
      end;
    TOrientation.Vertical:
      begin
        FLyScale.Align := TAlignLayout.Left;
        FLyScale.Width := 30;
      end;
  end;
end;

procedure TTscLevelMeterScale.SetOrientation(value: TOrientation);
var
  I: Integer;
begin
  FOrientation := value;
  for I := 0 to FScUnitList.Count -1 do
    begin
      FScUnitList.Items[I].Orientation  := value;
    end;
  Resize;
end;

procedure TTscLevelMeterScale.SetColor(color:TAlphaColor);
var
  I: Integer;
begin
  FColor  := color;
  for I := 0 to FScUnitList.Count -1 do
    begin
      FScUnitList.Items[I].Color  := color;
    end;
end;
{$ENDREGION}

constructor TTscLevelMeterDyn.Create(AOwner: TComponent; bar: TLayout);
begin
  FBar := bar;
  FAOwner := AOwner;
  FMax := 0;
  FMin := -60;
  FRange := FMax - FMin;
  FRYBorder := -6;
  FYGBorder := -20;
  FOrientation := TOrientation.Vertical;
  BarInit;
  Resize;
end;

destructor TTscLevelMeterDyn.Destroy;
begin
  FScaleList.Free;
  inherited Destroy;
end;

procedure TTscLevelMeterDyn.BarInit;
begin
  FLyBar := TLayout.Create(FAOwner);
  FLyBar.parent := FBar;
  FLyBar.Align := TAlignLayout.Client;

  FLyRed := TLayout.Create(FAOwner);
  FLyRed.parent := FLyBar;
  FLyRed.ClipChildren := True;

  FLyYellow := TLayout.Create(FAOwner);
  FLyYellow.parent := FLyBar;
  FLyYellow.ClipChildren := True;

  FLyGreen := TLayout.Create(FAOwner);
  FLyGreen.parent := FLyBar;
  FLyGreen.Align := TAlignLayout.Client;
  FLyGreen.ClipChildren := True;

  FRaRed := TRectangle.Create(FAOwner);
  FRaRed.parent := FLyRed;
  FRaRed.Stroke.Kind := TBrushKind.None;
  FRaRed.Fill.Kind := TBrushKind.Solid;
  FRaRed.Fill.Color := TAlphaColorRec.Red;

  FRaDRed := TRectangle.Create(FAOwner);
  FRaDRed.parent := FLyRed;
  FRaDRed.Align := TAlignLayout.Client;
  FRaDRed.Stroke.Kind := TBrushKind.None;
  FRaDRed.Fill.Kind := TBrushKind.Solid;
  FRaDRed.Fill.Color := $AA8B0000;

  FRaYellow := TRectangle.Create(FAOwner);
  FRaYellow.parent := FLyYellow;
  FRaYellow.Stroke.Kind := TBrushKind.None;
  FRaYellow.Fill.Kind := TBrushKind.Solid;
  FRaYellow.Fill.Color := TAlphaColorRec.Yellow;

  FRaDYellow := TRectangle.Create(FAOwner);
  FRaDYellow.parent := FLyYellow;
  FRaDYellow.Align := TAlignLayout.Client;
  FRaDYellow.Stroke.Kind := TBrushKind.None;
  FRaDYellow.Fill.Kind := TBrushKind.Solid;
  FRaDYellow.Fill.Color := $AABDB76B;

  FRaGreen := TRectangle.Create(FAOwner);
  FRaGreen.parent := FLyGreen;
  FRaGreen.Stroke.Kind := TBrushKind.None;
  FRaGreen.Fill.Kind := TBrushKind.Solid;
  FRaGreen.Fill.Color := TAlphaColorRec.Lawngreen;

  FRaDGreen := TRectangle.Create(FAOwner);
  FRaDGreen.parent := FLyGreen;
  FRaDGreen.Align := TAlignLayout.Client;
  FRaDGreen.Stroke.Kind := TBrushKind.None;
  FRaDGreen.Fill.Kind := TBrushKind.Solid;
  FRaDGreen.Fill.Color := $AA006400;

  FScaleList := TTscLevelMeterScale.Create(FAOwner, FBar);
//
//  FScaleList.Add;
//  FScaleList.UnitList.Items[1].Text := '-6';
//  FScaleList.UnitList.Items[1].Position :=
//    (FLyBar.Height * (ABS(-6) / FRange)) + 10;
//
//  FScaleList.Add;
//  FScaleList.UnitList.Items[2].Text := '-20';
//  FScaleList.UnitList.Items[2].Position :=
//    (FLyBar.Height * (ABS(-20) / FRange)) + 10;
end;

procedure TTscLevelMeterDyn.Resize;
var
  I: Integer;
  bounds  : TBounds;
begin
  case FOrientation of
    TOrientation.Horizontal :
      begin
        bounds                := TBounds.Create(TRectF.Create(10,0,10,0));
        FLyBar.Margins        := bounds;
        FLyRed.Align          := TAlignLayout.Right;
        FLyRed.Position.X     := FLyBar.Width;
        FLyYellow.Align       := TAlignLayout.Right;
        FRaRed.Align          := TAlignLayout.Left;
        FRaYellow.Align       := TAlignLayout.Left;
        FRaGreen.Align        := TAlignLayout.Left;
        FLyRed.Width          := FLyBar.Width * ((FMax - FRYBorder) / (FMax - FMin));
        FLyYellow.Width       := (FLyBar.Width * ((FMax - FYGBorder) / (FMax - FMin))) - FLyRed.Width;
        //FScaleList.UnitList.Items[0].Position := FBar.Width - 10 - (FLyBar.Width * (ABS(0) / FRange));
        for I := 0 to FScaleList.UnitList.Count -1 do
          FScaleList.UnitList.Items[I].Position := FBar.Width - 10 - (FLyBar.Width * (ABS(FScaleSet[I]) / FRange));
        bounds.Free;
      end;
    TOrientation.Vertical   :
      begin
        bounds                := TBounds.Create(TRectF.Create(0,10,0,10));
        FLyBar.Margins        := bounds;
        FLyRed.Align          := TAlignLayout.Top;
        FLyRed.Position.Y     := 0;
        FLyYellow.Align       := TAlignLayout.Top;
        FRaRed.Align          := TAlignLayout.Bottom;
        FRaYellow.Align       := TAlignLayout.Bottom;
        FRaGreen.Align        := TAlignLayout.Bottom;
        FLyRed.Height         := FLyBar.Height * ((FMax - FRYBorder) / (FMax - FMin));
        FLyYellow.Height      := (FLyBar.Height * ((FMax - FYGBorder) / (FMax - FMin))) - FLyRed.Height;
        for I := 0 to FScaleList.UnitList.Count -1 do
          FScaleList.UnitList.Items[I].Position := (FLyBar.Height * (ABS(FScaleSet[I]) / FRange)) + 10;
        bounds.Free;
      end;
  end;
  SetValue(FValue);
end;

procedure TTscLevelMeterDyn.SetValue(value: Double);
var
  Max_RY: Double;
  RY_YG: Double;
  YG_Min: Double;
begin
  Max_RY  := FMax - FRYBorder;
  RY_YG   := FRYBorder - FYGBorder;
  YG_Min  := FYGBorder - FMin;
  FValue  := value;

  case FOrientation of
    TOrientation.Horizontal :
      begin
        if value < FRYBorder then
          FRaRed.Width := 0
        else
          FRaRed.Width := FLyRed.Width * ((Max_RY + value) / (Max_RY));

        if value < FYGBorder then
          FRaYellow.Width := 0
        else
          FRaYellow.Width := FLyYellow.Width *
            (RY_YG + value - FRYBorder) / RY_YG;

        FRaGreen.Width := FLyGreen.Width * (YG_Min + value - FYGBorder) / YG_Min;
      end;
    TOrientation.Vertical   :
      begin
        if value < FRYBorder then
          FRaRed.Height := 0
        else
          FRaRed.Height := FLyRed.Height * ((Max_RY + value) / (Max_RY));

        if value < FYGBorder then
          FRaYellow.Height := 0
        else
          FRaYellow.Height := FLyYellow.Height *
            (RY_YG + value - FRYBorder) / RY_YG;

        FRaGreen.Height := FLyGreen.Height * (YG_Min + value - FYGBorder) / YG_Min;
      end;
  end;
end;

procedure TTscLevelMeterDyn.SetOrientation(value:TOrientation);
begin
  FOrientation := value;
  FScaleList.Orientation  := value;
  Resize;
end;

procedure TTscLevelMeterDyn.SetScaleSet(sets:TTsdScaleSet);
var
  i : Integer;
begin
  FScaleSet := sets;
  FScaleList.UnitList.Clear;
  for i in FScaleSet do
    begin
      FScaleList.Add;
      FScaleList.UnitList.Items[FScaleList.UnitList.Count-1].Text := IntToStr(i);
    end;
  Resize;
end;

procedure TTscLevelMeterDyn.SetScaleColor(color:TAlphaColor);
begin
  FScaleColor := color;
  FScaleList.Color  := color;
end;

end.
