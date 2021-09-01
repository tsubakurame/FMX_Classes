unit TsuCalendar;

interface
uses
  System.DateUtils, System.SysUtils, System.TypInfo,
  FMX.Grid, FMX.StdCtrls, FMX.ScrollBox,
  TsuTypes
  ;

type
  TTscCalendar  = class(TObject)
    private
      FStringGrid : TStringGrid;
      FIncMonthButton : TButton;
      FDecMonthButton : TButton;
      FDateLabel      : TLabel;
      FToday          : TDateTime;
      FNowViewDate    : TDateTime;
      procedure SetView(date:TDateTime);
    public
      constructor Create(grid:TStringGrid; IncBt, DecBt:TButton; DateLb:TLabel);
  end;

implementation
uses
  Winapi.Windows;

constructor TTscCalendar.Create(grid:TStringGrid; IncBt, DecBt:TButton; DateLb:TLabel);
begin
  FStringGrid     := grid;
  FIncMonthButton := IncBt;
  FDecMonthButton := DecBt;
  FDateLabel      := DateLb;

  FToday  := Now;

  FNowViewDate  := StartOfAMonth(YearOf(FToday), MonthOf(FToday));
  SetView(FNowViewDate);
end;

procedure TTscCalendar.SetView(date:TDateTime);
var
  I : Integer;
  r,  c : Integer;
  scrl  : TScrollBar;
begin
  FStringGrid.ClearContent;
  FStringGrid.ShowScrollBars  := False;
  FStringGrid.ReadOnly  := True;
  for I := 0 to 6 do
    begin
      FStringGrid.AddObject(TStringColumn.Create(FStringGrid));
      FStringGrid.Columns[I].Header := GetEnumName(TypeInfo(TTseWeek), I);
      FStringGrid.Columns[I].Width  := (FStringGrid.Width -14) / 7;
    end;
  FStringGrid.RowCount  := 5;

  r := 0;
  for I := 1 to DayOf(EndOfTheMonth(date)) do
    begin
      c := DayOfTheWeek(date) mod 7;
      OutputDebugString(PChar(IntToStr(r)+','+IntToStr(c)));
      FStringGrid.Cells[c, r]  := IntToStr(DayOf(date));
      if c = 6 then
        inc(r);
      date := IncDay(date);
    end;
end;

end.
