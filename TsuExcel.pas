unit TsuExcel;

interface
uses
  System.Win.ComObj, Winapi.Windows, Excel2010, Classes, System.Variants, system.Generics.Collections, Office2000, TsuStrUtils
  ;

type
  TTsrExcelPic = record
    Picture : Variant;
    path    : string;
  end;
  TTscExcel = class(TObject)
    private
      procedure SetVisible(value:Boolean);
      function GetVisible:Boolean;
      procedure AutoClose;
    protected
      FExcel    : Variant;
      FApp      : Variant;
      FBook     : Variant;
      FSheet    : Variant;
      FOpened   : Boolean;
      FPictures : TList<TTsrExcelPic>;
      FOnClose  : TExcelApplicationWorkbookBeforeClose;
    public
      constructor Create;
      destructor Destroy;
      procedure CreateNewBooks;
      procedure OpenBooks(path:string);

      procedure Value(cell:string;val:string);

      procedure PictureInsert(path:string);
      procedure PicturePosition(index:Integer;cell:string);
      procedure PictureWidth(index:Integer;range1,range2:string);
      procedure PictureHeight(index:Integer;range1,range2:string);
      function GetPictureIndex(path:string):Integer;
      procedure ShapesAddPicture(path:string; left,top,width,height:Single);
      function GetRangeTop(cell:string):Single;
      function GetRangeLeft(cell:string):Single;
      function GetRangeWidth(range1,range2:string):Single;
      function GetRangeHeight(range1,range2:string):Single;
      procedure SheetSelect(index:Integer);overload;
      procedure SheetSelect(sheet_name:string);overload;

      class function CheckCellString(cell:string):Boolean; static;

      //procedure PictureScale(index:Integer;width,height:Single);

      property Visible  : Boolean read GetVisible write SetVisible;
  end;

implementation

constructor TTscExcel.Create;
begin
  FExcel        := CreateOleObject('Excel.Application');
  FApp          := FExcel.Application;
  FPictures     := TList<TTsrExcelPic>.Create;
  FOpened       := False;
  //FApp.OnWorkbookBeforeClose := AutoClose;
end;

destructor TTscExcel.Destroy;
begin
  FSheet  := Unassigned;
  FBook   := Unassigned;
  FApp    := Unassigned;
  FExcel  := Unassigned;
  inherited Destroy;
end;

procedure TTscExcel.SetVisible(value:Boolean);
begin
  FApp.Visible  := value;
end;

function TTscExcel.GetVisible:Boolean;
begin
  Result  := FApp.Visible;
end;

procedure TTscExcel.CreateNewBooks;
begin
  if not FOpened then
    begin
      FBook         := FApp.WorkBooks.Add;
      FSheet        := FBook.ActiveSheet;
      FOpened       := True;
    end;
end;

procedure TTscExcel.OpenBooks(path:string);
begin
  if not FOpened then
    begin
      FBook         := FApp.WorkBooks.Open(path);
      FSheet        := FBook.ActiveSheet;
      FOpened       := True;
    end;
end;

procedure TTscExcel.Value(cell:string;val:string);
var
  range : Variant;
begin
  if FOpened then
    begin
      range := FSheet.Range[cell];
      range.Value := val;
    end;
end;

procedure TTscExcel.PictureInsert(path:string);
var
  rec : TTsrExcelPic;
begin
  if FOpened then
    begin
      rec.path    := path;
      rec.Picture := FSheet.Pictures.Insert(path);
      FPictures.Add(rec);
    end;
end;

procedure TTscExcel.PicturePosition(index:Integer;cell:string);
var
  range : Variant;
begin
  if FOpened then
    begin
      range := FSheet.Range[cell];
      FPictures[index].Picture.Top  := range.Top;
      FPictures[index].Picture.Left := range.Left;
    end;
end;

procedure TTscExcel.PictureWidth(index:Integer;range1,range2:string);
var
  Lrange : Variant;
begin
  if FOpened then
    begin
      Lrange := FSheet.Range[range1,range2];
      FPictures[index].Picture.Width := Lrange.Width;
    end;
end;

procedure TTscExcel.PictureHeight(index:Integer;range1,range2:string);
var
  Lrange : Variant;
begin
  if FOpened then
    begin
      Lrange := FSheet.Range[range1,range2];
      FPictures[index].Picture.Height := Lrange.Height;
    end;
end;

function TTscExcel.GetPictureIndex(path:string):Integer;
var
  I: Integer;
begin
  for I := 0 to FPictures.Count -1 do
    begin
      if FPictures[I].path = path then
        begin
          Result  := I;
          Break;
        end;
    end;
end;

procedure TTscExcel.AutoClose;
begin

end;

procedure TTscExcel.ShapesAddPicture(path:string; left,top,width,height:Single);
begin
  if FOpened then
    begin
      FSheet.Shapes.AddPicture(path, msoFalse, msoTrue, left, top, width, height);
    end;
end;

function TTscExcel.GetRangeTop(cell:string):Single;
var
  range : Variant;
begin
  if FOpened then
    begin
      range   := FSheet.Range[cell];
      Result  := range.Top;
    end;
end;

function TTscExcel.GetRangeLeft(cell:string):Single;
var
  range : Variant;
begin
  if FOpened then
    begin
      range   := FSheet.Range[cell];
      Result  := range.Left;
    end;
end;

function TTscExcel.GetRangeWidth(range1,range2:string):Single;
var
  range : Variant;
begin
  if FOpened then
    begin
      range   := FSheet.Range[range1, range2];
      Result  := range.Width;
    end;
end;

function TTscExcel.GetRangeHeight(range1,range2:string):Single;
var
  range : Variant;
begin
  if FOpened then
    begin
      range   := FSheet.Range[range1, range2];
      Result  := range.Height;
    end;
end;

class function TTscExcel.CheckCellString(cell:string):Boolean;
var
  I  :integer;
  state : Byte;
  strtyp  : TTsdStringTypes;
  beforeTypes : TTsdStringTypes;
  changecnt : Byte;
begin
  state := 0;
  strtyp  := TTsfStrType(cell);
  if (stHalfNum in strtyp) and (stHalfAlpha in strtyp) then
    begin
      beforeTypes := [stHalfAlpha];
      changecnt   := 0;
      for I := 1 to Length(cell) do
        begin
          strtyp  := TTsfStrType(cell[I]);
          if beforeTypes <> strtyp then
            begin
              Inc(changecnt);
              beforeTypes := strtyp;
            end;
        end;
      Result  := (changecnt = 1);
    end
  else
    Result  := False;
end;

procedure TTscExcel.SheetSelect(index:Integer);
begin
  FSheet  := FBook.WorkSheets[index];
end;

procedure TTscExcel.SheetSelect(sheet_name:string);
begin
  FSheet  := FBook.WorkSheets[sheet_name];
end;

end.
