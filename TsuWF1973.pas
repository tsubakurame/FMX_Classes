unit TsuWF1973;

interface
uses
  System.Classes, System.SysUtils,
  TsuVISA
  ;

type
  TTscWF1973  = class(TObject)
    private
      FGPIB : TTscVISA;
    public
      constructor Create;
      procedure Open(adr:string);
  end;

implementation

constructor TTscWF1973.Create;
begin
  FGPIB := TTscVISA.Create;
end;

procedure TTscWF1973.Open(adr: string);
begin
//  FGPIB.Open('GPIB0::'+adr+'::INSTR');
  FGPIB.Open('GPIB0::2::INSTR');
end;

end.
