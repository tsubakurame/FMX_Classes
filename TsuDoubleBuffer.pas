unit TsuDoubleBuffer;

interface
uses
  System.Generics.Collections, System.SysUtils, System.SyncObjs
  ;

type
  TTsdDoubleGUID  = Array[0..1] of TGUID;
  TTsdDoubleString  = Array[0..1] of string;
  TTsdDoubleEvent   = Array[0..1] of TEvent;
  TTscDoubleBuffer<T> = class(TEnumerable<T>)
    private
      procedure SetBufferLength(length:Integer);
      procedure IncLine(var line:Byte);
    protected
      FWriteGUID      : TTsdDoubleGUID;
      FReadGUID       : TTsdDoubleGUID;
      FWriteGUID_Str  : TTsdDoubleString;
      FReadGUID_Str   : TTsdDoubleString;
      FWriteEvent     : TTsdDoubleEvent;
      FReadEvent      : TTsdDoubleEvent;
      FBuffer         : Array[0..1] of Array of T;
      FBufferLength   : integer;
      FCSection       : TCriticalSection;
      FWriteLine      : Byte;
      FReadLine       : Byte;
    public
      constructor Create;
      procedure Write(data:Array of T);
      procedure Read(var data:Array of T);
    public
      property WriteGUID      : TTsdDoubleGUID read FWriteGUID;
      property ReadGUID       : TTsdDoubleGUID read FReadGUID;
      property WriteGUID_Str  : TTsdDoubleString read FWriteGUID_Str;
      property ReadGUID_Str   : TTsdDoubleString read FReadGUID_Str;
      property BufferLength   : Integer read FBufferLength write SetBufferLength;
      property ReadLine       : Byte read FReadLine;
      property WriteLine      : Byte read FWriteLine;
  end;

implementation

constructor TTscDoubleBuffer<T>.Create;
var
  I: Integer;
begin
  for I := 0 to 1 do
    begin
      CreateGUID(FWriteGUID[I]);
      FWriteGUID_Str[I] := GUIDToString(FWriteGUID[I]);
      FWriteEvent[I]    := TEvent.Create(nil, False, False, FWriteGUID_Str[I]);

      CreateGUID(FReadGUID[I]);
      FReadGUID_Str[I]  := GUIDToString(FReadGUID[I]);
      FReadEvent[I]     := TEvent.Create(nil, False, False, FReadGUID_Str[I]);
    end;
  SetBufferLength(1024);
  FCSection   := TCriticalSection.Create;
  FReadLine   := 0;
  FWriteLine  := 0;
end;

procedure TTscDoubleBuffer<T>.SetBufferLength(length:Integer);
var
  I: Integer;
begin
  if length > 0 then
    begin
      FBufferLength := length;
      for I := 0 to 1 do
        begin
          SetLength(FBuffer[I], FBufferLength);
        end;
    end
  else
    raise Exception.Create('Please specify an integer of 1 or more for Length.');
end;

procedure TTscDoubleBuffer<T>.IncLine(var line:Byte);
begin
  if line = 0 then line := 1
  else line := 0;
end;

procedure TTscDoubleBuffer<T>.Write(data:Array of T);
var
  I: Integer;
begin
  FCSection.Enter;
  try
    if FBufferLength = Length(data) then
      begin
        for I := 0 to FBufferLength-1 do
          FBuffer[FWriteLine][I]  := data[I];
        FReadEvent[FWriteLine].SetEvent;
        IncLine(FWriteLine);
      end
    else raise Exception.Create('Buffer length mismatch');

  finally
    FCSection.Leave;
  end;

end;

procedure TTscDoubleBuffer<T>.Read(var data:Array of T);
var
  I: Integer;
begin
  FCSection.Enter;
  try
    if FBufferLength = Length(data) then
      begin
        for I := 0 to FBufferLength -1 do
          data[I] := FBuffer[FReadLine][I];
        FWriteEvent[FReadLine].SetEvent;
        IncLine(FReadLine);
      end
    else raise Exception.Create('Buffer length mismatch');
  finally
    FCSection.Leave;
  end;
end;

end.
