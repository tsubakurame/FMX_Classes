unit TsuD2XXEEUA;

interface
uses
  System.SysUtils,
  TsuD2XX, TsuFTDITypedefD2XX
  ;

type
  TTsrD2XXOpenInfo  = record
    private
      FArg  : AnsiString;
      FFlag : FT_OpenEx_Flags;
      procedure SetArg(ast:AnsiString);
      procedure SetFlag(flag:FT_OpenEx_Flags);
    public
      property Arg  : AnsiString read FArg write SetArg;
      property Flag : FT_OpenEx_Flags read FFlag write SetFlag;
  end;
  TTscD2XXEEUA  = class(TObject)
    private
      D2XX  : TTscD2XX;
    protected
      FOpenInfo : TTsrD2XXOpenInfo;
      procedure ReadEEUA;
      procedure DoRead(data:FT_pucData);virtual;
      procedure DoWrite(data:string);virtual;
    public
      constructor Create;
      destructor Destroy;
//      property OpenInfo : TTsrD2XXOpenInfo read FOpenInfo write FOpenInfo;
  end;

implementation

procedure TTsrD2XXOpenInfo.SetArg(ast: AnsiString);
begin
  FArg  := ast;
end;

procedure TTsrD2XXOpenInfo.SetFlag(flag: FT_OpenEx_Flags);
begin
  FFlag := flag;
end;

constructor TTscD2XXEEUA.Create;
begin
  inherited Create;
end;

destructor TTscD2XXEEUA.Destroy;
begin
  inherited Destroy;
end;

procedure TTscD2XXEEUA.ReadEEUA;
var
  FHandle : UInt32;
  BytesRead : UInt32;
  FReadData : FT_pucData;
begin
  if D2XX = nil then
    D2XX  := TTscD2XX.Create;
  if D2XX.OpenEx(PAnsiChar(FOpenInfo.Arg), FOpenInfo.Flag, FHandle) = FT_OK then
    begin
      if D2XX.EE_UARead(FHandle, FReadData,BytesRead) = FT_OK then
        begin
          DoRead(FReadData);
        end
      else
        raise Exception.Create('Read Error');
    end
  else
    raise Exception.Create('Open Error');
  D2XX.Close(FHandle);
  FreeAndNil(D2XX);
end;

procedure TTscD2XXEEUA.DoRead(data: FT_pucData);
begin

end;

procedure TTscD2XXEEUA.DoWrite(data: string);
var
  FHandle : UInt32;
  size  : UInt32;
  I: Integer;
  cl_data : string;
begin
  if D2XX = nil then D2XX := TTscD2XX.Create;
  if D2XX.OpenEx(PAnsiChar(FOpenInfo.Arg), FOpenInfo.Flag, FHandle) = FT_OK then
    begin
      D2XX.EE_UASize(FHandle, size);
      for I := 1 to size do
        cl_data := cl_data + ' ';
      D2XX.EE_UAWrite(FHandle, cl_data);
      if D2XX.EE_UAWrite(FHandle, data) <> FT_OK then
        raise Exception.Create('Write Error');
    end
  else
    raise Exception.Create('Open Error');
  D2XX.Close(FHandle);
  FreeAndNil(D2XX);
end;

end.
