unit TsuGraphicsFMX;

interface
uses
  FMX.Graphics
  ;

type
  TTscBitmap  = class(TBitmap)
    public
      procedure DebugSaveToFile(path:string);
  end;

implementation

procedure TTscBitmap.DebugSaveToFile(path:string);
begin
  {$IFDEF DEBUG}
  SaveToFile(path);
  {$ENDIF}
end;

end.
