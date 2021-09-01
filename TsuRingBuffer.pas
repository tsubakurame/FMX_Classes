unit TsuRingBuffer;

interface
uses
  System.Generics.Collections
  ;

type
  TTscRingBuffer<T>  = class(TEnumerable<T>)
    private
      procedure PointerInc(var pt:UInt16);
    protected
      FData   : TArray<T>;
      FLength : UInt16;
      FWritePointer : UInt16;
      FReadPointer  : UInt16;
      FLocked       : Boolean;
    public
      constructor Create(length:UInt16);
      procedure Write(value:T);overload;
      procedure Write(buffer:TArray<T>);overload;
      procedure ReadBuffer(var buf: TArray<T>);
      procedure ReadOld(var value: T);overload;
      function ReadOld:T;overload;
    published
      property Locked : Boolean read FLocked write FLocked;
  end;

implementation

constructor TTscRingBuffer<T>.Create(length:UInt16);
begin
  FLength       := length;
  FWritePointer := 0;
  FReadPointer  := 0;
  FLocked       := False;
  SetLength(FData, FLength);
end;

procedure TTscRingBuffer<T>.Write(value:T);
begin
  FData[FWritePointer]  := value;
  PointerInc(FWritePointer);
end;

procedure TTscRingBuffer<T>.Write(buffer:TArray<T>);
var
  I: Integer;
begin
  for I := 0 to Length(buffer) -1 do
    Write(buffer[I]);
end;

procedure TTscRingBuffer<T>.PointerInc(var pt:UInt16);
begin
  Inc(pt);
  if pt = FLength then pt := 0;
end;

procedure TTscRingBuffer<T>.ReadBuffer(var buf:TArray<T>);
var
  I: Integer;
  read_pt : UInt16;
begin
  SetLength(buf, FLength);
  read_pt := FWritePointer;
  for I := 0 to FLength -1 do
    begin
      buf[I]  := Fdata[read_pt];
      PointerInc(read_pt);
    end;
end;

procedure TTscRingBuffer<T>.ReadOld(var value:T);
begin
  value := Fdata[FWritePointer];
end;

function TTscRingBuffer<T>.ReadOld:T;
begin
  Result  := Fdata[FWritePointer];
end;

end.
