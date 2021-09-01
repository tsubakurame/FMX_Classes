unit TsuPageControl;

interface
uses
  FMX.TabControl, FMX.StdCtrls,
  System.Generics.Collections
  ;

type
  TTscPageControl  = class(TObject)
    private
      FTabControl     : TTabControl;
      FPageHistory    : TList<Integer>;
      FPageHistoryIdx : Integer;
      FBackButton     : TSpeedButton;
      FNextButton     : TSpeedButton;
    public
      constructor Create(tab_ctl:TTabControl);
      procedure ChangePage(index: Integer);
      procedure BackPage;
  end;

implementation

constructor TTscPageControl.Create(tab_ctl:TTabControl);
begin
  FTabControl     := tab_ctl;
  FPageHistory    := TList<Integer>.Create;
  FPageHistoryIdx := 0;
  FPageHistory.Add(0);
end;

procedure TTscPageControl.ChangePage(index: Integer);
var
  val : integer;
begin
  FTabControl.TabIndex  := index;
  //Inc(FPageHistoryIdx);
  if FPageHistoryIdx = FPageHistory.Count -1 then
    begin
      FPageHistory.Add(index);
      Inc(FPageHistoryIdx);
    end
  else
    begin
      //val := FPageHistory[FPageHistoryIdx];
      Inc(FPageHistoryIdx);
      FPageHistory[FPageHistoryIdx] := index;
    end;
end;

procedure TTscPageControl.BackPage;
begin
  if FPageHistoryIdx > 0 then
    begin
      Dec(FPageHistoryIdx);
      FTabControl.TabIndex  := FPageHistory[FPageHistoryIdx];
    end;
end;

end.
