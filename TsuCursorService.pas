unit TsuCursorService;

interface
uses
  Winapi.Windows,
  FMX.Platform, FMX.Types, System.UITypes;

type
  TTscWinCursorService  = class(TInterfacedObject, IFMXCursorService)
    private
      class var FPreviousPlatformService  : IFMXCursorService;
      class var FWinCursorService         : TTscWinCursorService;
      class var FCursorOverride           : TCursor;
      class procedure SetCursorOverride(const Value: TCursor);static;
    public
      class property CursorOverride : TCursor read FCursorOverride write SetCursorOverride;
      class constructor Create;
      procedure SetCursor(const ACursor: TCursor);
      function GetCursor:TCursor;
    end;

implementation

{$region'    TTscWinCursorSercice    '}
class constructor TTscWinCursorService.Create;
begin
  FWinCursorService := TTscWinCursorService.Create;
  FPreviousPlatformService  := TPlatformServices.Current.GetPlatformService(IFMXCursorService) as IFMXCursorService;
  TPlatformServices.Current.RemovePlatformService(IFMXCursorService);
  TPlatformServices.Current.AddPlatformService(IFMXCursorService, FWinCursorService);
end;

function TTscWinCursorService.GetCursor: TCursor;
begin
  Result  := FPreviousPlatformService.GetCursor;
end;

procedure TTscWinCursorService.SetCursor(const ACursor: TCursor);
begin
  if FCursorOverride = crDefault then
    FPreviousPlatformService.SetCursor(ACursor)
//    winapi.Windows.SetCursor(ACursor)
  else
    FPreviousPlatformService.SetCursor(FCursorOverride);
end;

class procedure TTscWinCursorService.SetCursorOverride(const Value: TCursor);
begin
  FCursorOverride := Value;
  TTscWinCursorService.FPreviousPlatformService.SetCursor(FCursorOverride);
end;
{$endregion}

end.
