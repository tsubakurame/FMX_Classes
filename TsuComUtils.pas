unit TsuComUtils;

interface
uses
  Windows, Winapi.ActiveX, System.Win.ComObj,
  System.SysUtils, System.Classes, System.Variants, System.RegularExpressions,
  WbemScripting_TLB,
  TsuComTypes
  ;

const
  IXCOMPORTLIST_VER = 1;

procedure TspGetComPortList(PortList: TStrings);
function TsfComPortListNameToComPortNumber(val: string): string;
function TsfComPortListNameToComPortNumberOnly(val: string): string;

implementation

procedure TspGetComPortList(PortList: TStrings);
var
  Locator: ISWbemLocator;
  Services: ISWbemServices;

  query: string;

  SerialSet: ISWbemObjectSet;
  wmi_enum: IEnumVariant;
  Value: Cardinal;

  wmi_item: OleVariant;
  i: integer;
  Count: integer;
  str: string;
  obj: TTscComItem;
  strlist: TStringList;
  port_number: string;
begin
  Locator := CreateOleObject('WbemScripting.SWbemLocator') as ISWbemLocator;
  Services := Locator.ConnectServer('.', '', '', '', '', '', 0, nil);
  query := 'Select * from Win32_PNPEntity Where (ClassGuid = ''{4D36E978-E325-11CE-BFC1-08002BE10318}'') and (Name like ''%(COM%)'')';
  SerialSet := Services.ExecQuery(query, 'WQL', wbemFlagReturnImmediately, nil);

  Count := SerialSet.Count;
  wmi_enum := SerialSet._NewEnum as IEnumVariant;
  strlist := TStringList.Create;
  try
    // =========================================
    // 列挙ループ ここから
    // -----------------------------------------
    for i := 1 to Count do
    begin
      wmi_enum.Next(1, wmi_item, Value);
      try
        if wmi_item.Manufacturer <> null then
          str := wmi_item.Manufacturer
        else
          str := '';

        obj := TTscComItem.Create;
        obj.Value := str + ' ' + wmi_item.Name;
        port_number := IntToHex(StrToInt(TsfComPortListNameToComPortNumberOnly(wmi_item.Name)), 4);
        strlist.AddObject(port_number, obj);
      finally
        VarClear(wmi_item);
      end;
    end;
    // -----------------------------------------
    // 列挙ループ ここまで
    // =========================================

    // -----------------------------------------
    // ソートして、リストに追加
    // -----------------------------------------
    strlist.Sort;
    PortList.Clear;
    for i := 0 to strlist.Count - 1 do
      begin
        PortList.Add(TTscComItem(strlist.Objects[i]).Value);
      end;

  finally
    for i := 0 to strlist.Count - 1 do
    begin
      strlist.Objects[i].Free;
    end;
    strlist.Free;
  end;
end;

{
  「(標準ポート) 通信ポート (COM1)」→「COM1」を返す
}
function TsfComPortListNameToComPortNumber(val: string): string;
var
  match: TMatch;
begin
  match := TRegEx.match(val, '\((COM\d+)\)$');
  if match.Success then
  begin
    Result := match.Groups.Item[1].Value;
  end;
end;

{
  「(標準ポート) 通信ポート (COM1)」→「1」を返す
}
function TsfComPortListNameToComPortNumberOnly(val: string): string;
var
  match: TMatch;
begin
  match := TRegEx.match(val, '\(COM(\d+)\)$');
  if match.Success then
  begin
    Result := match.Groups.Item[1].Value;
  end;
end;

end.
