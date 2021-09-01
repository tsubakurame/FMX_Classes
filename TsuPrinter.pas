unit TsuPrinter;

interface
uses
  System.SysUtils, System.UITypes, System.Types, System.UIConsts, System.Classes,
  System.Math, System.Generics.Collections,
  FMX.Printer, FMX.Graphics, FMX.StdCtrls, FMX.Objects, Fmx.ExtCtrls, FMX.ListBox
  ;

type
  TTsdPrintPreviewEvents  = procedure(Sender:TObject) of object;
  TTsdDrawMethod          = procedure of object;
  TTscPrinterCtrl = class(TObject)
    private
      FPrinter            : TPrinter;
      FPrintImage         : TBitmap;
      FPrintButton        : TButton;
      FPrintSpeedButton   : TSpeedButton;
      //FPrintPreview       : TImage;
      FPrintPreview       : TImageViewer;
      FOnPreview          : TTsdPrintPreviewEvents;
      FDrawEvent          : TTsdDrawMethod;
      FDrawEventList      : TList<TTsdDrawMethod>;
      PageSetupDialog     : TPageSetupDialog;
      PrinterDialog       : TPrintDialog;
      FOrientation        : TPrinterOrientation;
      procedure SetPrintButton(btn:TObject);
      function GetPrintButton:TObject;
      procedure SetOrientation(val:TPrinterOrientation);
      function GetOrientation:TPrinterOrientation;

      procedure SetCanvas;
      procedure OnPrintClick(Sender:TObject);
      procedure PrintPreviewResize;
      procedure SetPrintPreview;

      procedure DrawBitmap(method:TTsdDrawMethod);
      procedure PrintImageClear;
    public
      constructor Create(AOwner:TComponent);
      destructor Destroy;override;
      procedure Preview;
      procedure PreviewOnlyChangeImage;
      procedure SetPrinterList(list:TComboBox);
      procedure PageSetupDialogExecute;
      procedure PrinterDialogExecute;
      procedure ChangeActivePrinter(Device:string);overload;
      procedure ChangeActivePrinter(index:Integer);overload;
    published
      property PrintOutButton : TObject read getPrintButton write SetPrintButton;
      property PrintImage     : TBitmap read FPrintImage write FPrintImage;
      property Orientation    : TPrinterOrientation read GetOrientation write SetOrientation;
      //property PrintPreview   : TImage read FPrintPreview write FPrintPreview;
      property PrintPreview   : TImageViewer read FPrintPreview write FPrintPreview;
      property OnPreview      : TTsdPrintPreviewEvents read FOnPreview write FOnPreview;
      property DrawEvent      : TTsdDrawMethod read FDrawEvent write FDrawEvent;
      property DrawEventSubs  : TList<TTsdDrawMethod> read FDrawEventList write FDrawEventList;
      //property
      //property  PrintOutButton  : TObject read
  end;

implementation

{$region'    Public Method    '}
constructor TTscPrinterCtrl.Create(AOwner:TComponent);
begin
  //Inherited Create(Self);
  {$WARN CONSTRUCTING_ABSTRACT OFF}
//  FPrinter        := TPrinter.Create;
  {$WARN CONSTRUCTING_ABSTRACT ON}
  FPrintImage     := TBitmap.Create;
  FDrawEventList  := TList<TTsdDrawMethod>.Create;
  PageSetupDialog := TPageSetupDialog.Create(AOwner);
  PrinterDialog   := TPrintDialog.Create(AOwner);
  FOrientation    := TPrinterOrientation.poPortrait;
  SetCanvas;
  inherited Create;
end;

destructor TTscPrinterCtrl.Destroy;
begin
//  FPrinter.Free;
//  FreeAndNil(FPrinter);
//  FPrinter.Free;
//  FPrinter.Abort;
//  FPrinter.Free;
  FPrintImage.Free;
  FDrawEventList.Free;
//  PageSetupDialog.Free;
//  PrinterDialog.Free;
  inherited Destroy;
end;

procedure TTscPrinterCtrl.Preview;
begin
  SetCanvas;
  PrintPreviewResize;
  DrawBitmap(PrintImageClear);
  if Assigned(FOnPreview) then
    FOnPreview(Self);
  if Assigned(FDrawEvent) then
    DrawBitmap(FDrawEvent);
  PreviewOnlyChangeImage;
end;

procedure TTscPrinterCtrl.PreviewOnlyChangeImage;
var
  I: Integer;
begin
  for I := 0 to FDrawEventList.Count -1 do
    DrawBitmap(FDrawEventList[I]);
  SetPrintPreview;
end;

procedure TTscPrinterCtrl.SetPrinterList(list:TComboBox);
var
  I : Integer;
begin
  for I := 0 to FPrinter.Count -1 do
    begin
      list.Items.Add(FPrinter.Printers[I].Device);
      if FPrinter.ActivePrinter.Device = FPrinter.Printers[I].Device then
        list.ItemIndex  := I;
    end;
end;

procedure TTscPrinterCtrl.PageSetupDialogExecute;
begin
  if PageSetupDialog.Execute then begin end;
end;

procedure TTscPrinterCtrl.PrinterDialogExecute;
begin
  if PrinterDialog.Execute then begin end;  
end;

procedure TTscPrinterCtrl.ChangeActivePrinter(Device:string);
var
  I: Integer;
begin
  for I := 0 to FPrinter.Count -1 do
    begin
      if FPrinter.Printers[I].Device = Device then
        begin
          FPrinter.ActivePrinter  := FPrinter.Printers[I];
          FPrinter.Orientation    := FOrientation;
          Preview;
        end;
    end;
end;

procedure TTscPrinterCtrl.ChangeActivePrinter(index:Integer);
begin
  if index < FPrinter.Count then
    begin
      FPrinter.ActivePrinter  := FPrinter.Printers[index];
      FPrinter.Orientation    := FOrientation;
      Preview;
    end;
end;
{$endregion}

{$region'    Private Method   '}
procedure TTscPrinterCtrl.SetCanvas;
begin
  FPrinter    := FMX.Printer.Printer;
  FPrinter.ActivePrinter.SelectDPI(600,600);
  FPrintImage.SetSize(TSize.Create(FPrinter.PageWidth, FPrinter.PageHeight));
end;

procedure TTscPrinterCtrl.OnPrintClick(Sender:TObject);
var
  SrcRect, DestRect : TRect;
begin
  FPrinter.Canvas.Fill.Color  := claBlack;
  FPrinter.Canvas.Fill.Kind   := TBrushKind.Solid;
  FPrinter.BeginDoc;
  SrcRect   := TRect.Create(0, 0, Printer.PageWidth, Printer.PageHeight);
  DestRect  := TRect.Create(0, 0, PrintImage.Width, PrintImage.Height);
  FPrinter.Canvas.DrawBitmap(PrintImage, SrcRect , DestRect, 1);
  FPrinter.EndDoc;
end;

procedure TTscPrinterCtrl.PrintPreviewResize;
begin
  if Assigned(FPrintPreview) then
    begin
      FPrintPreview.Bitmap.SetSize(FPrintImage.Size);
      FPrintPreview.BitmapScale := (FPrintPreview.Height -20) / FPrintPreview.Bitmap.Height
    end;
end;

procedure TTscPrinterCtrl.SetPrintPreview;
begin
  if Assigned(FPrintPreview) then
    begin
      with FPrintPreview.Bitmap.Canvas do
        begin
          BeginScene;
          //FPrintImage.SaveToFile('print.bmp');
          DrawBitmap( FPrintImage,
                      TRect.Create(0, 0,  PrintImage.Width,           PrintImage.Height),
                      TRect.Create(0, 0,  FPrintPreview.Bitmap.Width, FPrintPreview.Bitmap.Height),
                      1);
          EndScene;
        end;
    end;
end;

procedure TTscPrinterCtrl.DrawBitmap(method:TTsdDrawMethod);
begin
  FPrintImage.Canvas.BeginScene;
  method;
  FPrintImage.Canvas.EndScene;
end;

procedure TTscPrinterCtrl.PrintImageClear;
begin
  with FPrintImage.Canvas do
    begin
      Fill.Color  := claWhite;
      FillRect(TRect.Create(0,  0,  FPrintImage.Width,  FPrintImage.Height),  0,  0,  [], 1);
    end;
end;
{$endregion}

{$region'    Property Method    '}
procedure TTscPrinterCtrl.SetPrintButton(btn:TObject);
begin
  if btn.ClassName = 'TButton' then
    begin
      FPrintButton          := TButton(btn);
      FPrintButton.OnClick  := OnPrintClick;
      FPrintSpeedButton     := nil;
    end
  else if btn.ClassName = 'TSpeedButton' then
    begin
      FPrintSpeedButton := TSpeedButton(btn);
      FPrintSpeedButton.OnClick := OnPrintClick;
      FPrintButton      := nil;
    end
  else
    raise Exception.Create('This property Type is TButton or TSpeedButton only.');
end;

function TTscPrinterCtrl.GetPrintButton:TObject;
begin
  if FPrintButton <> nil then
    Result  := TObject(FPrintButton)
  else if FPrintSpeedButton <> nil then
    Result  := TObject(FPrintSpeedButton)
  else
    Result  := nil;
end;

procedure TTscPrinterCtrl.SetOrientation(val:TPrinterOrientation);
begin
  FPrinter.Orientation  := val;
  FOrientation          := val;
  SetCanvas;
end;

function TTscPrinterCtrl.GetOrientation:TPrinterOrientation;
begin
  Result  := FPrinter.Orientation;
end;
{$endregion}

end.
