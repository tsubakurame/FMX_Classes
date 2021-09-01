unit TsuIniFileUtils;

interface

{$region'    Update    '}
//==============================================================================
  {$Region'    2021  02  16    '}{
    OpenIniFile メソッド
    TypesがIVT_COMBOBOX_INDEXとIVT_CHECKBOX_CHECKEDで、
    コンポーネントにOnChangedイベントが指定されていた場合、
    イベントを発生させるように変更
  }{$endregion}
//==============================================================================
{$endregion}

uses
  System.IOUtils, System.IniFiles, System.Classes, System.SysUtils, System.Generics.Collections,
  System.Variants,
  FMX.ListBox, FMX.StdCtrls, FMX.TabControl, FMX.NumberBox, FMX.Edit,
  TsuAppData
  ;

type
  PBoolean  = ^Boolean;
  TTseIniFileValueType = ( IVT_STRING,
                          IVT_INTEGER,
                          IVT_FLOAT,
                          IVT_BOOL,
                          IVT_COMBOBOX_INDEX,
                          IVT_CHECKBOX_CHECKED,
                          IVT_TABCONTROL_INDEX,
                          IVT_LABEL_TEXT,
                          IVT_NUMBERBOX_VALUE,
                          IVT_EDIT_TEXT,
                          IVT_COMBOBOX_TEXT);
  TTsrIniFileStructure = record
      Section   : string;
      Key       : string;
      Value     : string;
      Default   : string;
      Types     : TTseIniFileValueType;
      PReferrer : Pointer;
  end;
  TTsdIniFileDataList  = TList<TTsrIniFileStructure>;
  PTComboBox  = ^TComboBox;
  PTCheckBox  = ^TCheckBox;
  PTTabControl= ^TTabControl;
  PTLabel     = ^TLabel;
  PTNumberBox = ^TNumberBox;
  PTEdit      = ^TEdit;
  TTscIniFile = class(TObject)
    private
      FFilePath : string;
      FDataList : TTsdIniFileDataList;
      FAppData  : TTscAppData;
      procedure DefaultPathAndName(var DirPath, FileName:string);
      function GetIniDataListIndex(section, key:string):Integer;
    public
      constructor Create;
      destructor Destroy;override;

      procedure OpenIniFile(DirPath:string; FileName:string);
      procedure SaveIniFile(DirPath:string; FileName:string);
      procedure WriteIniValue(section, key:string);overload;
      procedure WriteIniValue;overload;
      procedure DataListAdd(data : TTsrIniFileStructure);overload;
      procedure DataListAdd(Section, Key:string; Default:Variant; PReferrer:Pointer; Types:TTseIniFileValueType);overload;
      procedure DataListClear;
      function GetData(section, key:string):Variant;

      property FilePath : string read FFilePath;
      property DataList : TTsdIniFileDataList read FDataList;
      property AppData  : TTscAppData read FAppData write FAppData;
  end;

implementation

constructor TTscIniFile.Create;
begin
  inherited Create;
  FDataList := TTsdIniFileDataList.Create;
end;

destructor TTscIniFile.Destroy;
begin
  inherited Destroy;
  FDataList.Free;
end;

procedure TTscIniFile.OpenIniFile(DirPath:string; FileName:string);
var
  IniFile : TMemIniFile;
  I, M       : Integer;
  flag    : Boolean;
  data    : TTsrIniFileStructure;
begin
  DefaultPathAndName(DirPath, FileName);
  //if FileExists(TPath.Combine(DirPath,FileName)) then
    begin
      IniFile := TMemIniFile.Create(TPath.Combine(DirPath, FileName));
      try
        for I := 0 to FDataList.Count -1 do
          begin
            data        := FDataList[I];
            with data do
              begin
                data.Value  := IniFile.ReadString(Section, Key, Default);
                case Types of
                  IVT_STRING          : PString(PReferrer)^               := Value;
                  IVT_COMBOBOX_INDEX  :
                    begin
                      PTComboBox(PReferrer)^.ItemIndex  := StrToInt(Value);
                      if Assigned(PTComboBox(PReferrer)^.OnChange) then
                        PTComboBox(PReferrer)^.OnChange(PTComboBox(PReferrer)^);
                    end;
                  IVT_CHECKBOX_CHECKED:
                    begin
                      PTCheckBox(PReferrer)^.IsChecked  := StrToBool(Value);
                      if Assigned(PTCheckBox(PReferrer)^.OnChange) then
                        PTCheckBox(PReferrer)^.OnChange(PTCheckBox(PReferrer)^);
                    end;
                  IVT_TABCONTROL_INDEX: PTTabControl(PReferrer)^.TabIndex := StrToInt(Value);
                  IVT_LABEL_TEXT      : PTLabel(PReferrer)^.Text          := Value;
                  IVT_NUMBERBOX_VALUE : PTNumberBox(PReferrer)^.Value     := StrToFloat(Value);
                  IVT_EDIT_TEXT       : PTEdit(PReferrer)^.Text           := Value;
                  IVT_COMBOBOX_TEXT   : {$region'    ComboBox Text    '}
                    begin
                      for M := 0 to PTComboBox(PReferrer)^.Count -1 do
                        begin
                          if PTComboBox(PReferrer)^.Items[M] = Value then
                            begin
                              PTComboBox(PReferrer)^.ItemIndex  := M;
                              flag  := True;
                              Break;
                            end
                          else flag := False;
                        end;
                      if flag then
                        begin
                          if Assigned(PTComboBox(PReferrer)^.OnChange) then
                            PTComboBox(PReferrer)^.OnChange(PTComboBox(PReferrer)^);
                        end
                      else
                        PTComboBox(PReferrer)^.ItemIndex := -1
                    end;
                    {$endregion}
                  IVT_BOOL            : PBoolean(PReferrer)^              := StrToBool(Value);
                end;
              end;
            FDataList[I] := data;
          end;
      finally
        IniFile.Free;
      end;
    end;
end;

procedure TTscIniFile.SaveIniFile(DirPath:string; FileName:string);
var
  IniFile : TMemIniFile;
  I       : Integer;
begin
  DefaultPathAndName(DirPath, FileName);
  IniFile := TMemIniFile.Create(TPath.Combine(DirPath, FileName));
  try
    for I := 0 to FDataList.Count -1 do
      begin
        with FDataList[I] do
          begin
            IniFile.WriteString(Section, Key, Value);
          end;
      end;
    IniFile.UpdateFile;
  finally
    IniFile.Free;
  end;
end;

procedure TTscIniFile.WriteIniValue(section, key:string);
var
  idx   : Integer;
  data  : TTsrIniFileStructure;
begin
  idx   := GetIniDataListIndex(section, key);
  data  := FDataList[idx];
  case data.Types of
    IVT_STRING          : data.Value  := PString(data.PReferrer)^;
    IVT_INTEGER         : data.Value  := IntToStr(PInteger(data.PReferrer)^);
    IVT_COMBOBOX_INDEX  : data.Value  := IntToStr(PTComboBox(data.PReferrer)^.ItemIndex);
    IVT_CHECKBOX_CHECKED: data.Value  := BoolToStr(PTCheckBox(data.PReferrer)^.IsChecked);
    IVT_TABCONTROL_INDEX: data.Value  := IntToStr(PTTabControl(data.PReferrer)^.TabIndex);
    IVT_LABEL_TEXT      : data.Value  := PTLabel(data.PReferrer)^.Text;
    IVT_NUMBERBOX_VALUE : data.Value  := FloatToStr(PTNumberBox(data.PReferrer)^.Value);
    IVT_EDIT_TEXT       : data.Value  := PTEdit(data.PReferrer)^.Text;
    IVT_COMBOBOX_TEXT   : data.Value  := PTComboBox(data.PReferrer)^.Items[PTComboBox(data.PReferrer)^.ItemIndex];
    IVT_BOOL            : data.Value  := BoolToStr(PBoolean(data.PReferrer)^);
  end;
  FDataList[idx]  := data;
end;

procedure TTscIniFile.WriteIniValue;
var
  I: Integer;
begin
  for I := 0 to FDataList.Count -1 do
    begin
      with FDataList[I] do
        begin
          WriteIniValue(Section, Key);
        end;
    end;
end;

procedure TTscIniFile.DefaultPathAndName(var DirPath, FileName:string);
var
  AppName : string;
begin
  if DirPath = ''   then
    begin
      DirPath   := TPath.GetHomePath;
      if Assigned(FAppData) then
        begin
          AppName   := FAppData.AppName;
          DirPath   := DirPath + '\' + FAppData.MakerName + '\' + AppName;
        end
      else
        begin
          AppName   := TPath.GetFileNameWithoutExtension(ParamStr(0));
          DirPath   := DirPath + '\FRIENTECH\' +AppName;
        end;
      if not DirectoryExists(DirPath) then
        ForceDirectories(DirPath);
    end;
  if FileName = ''  then FileName := AppName + '.ini'
  else
    begin
      if LowerCase(TPath.GetExtension(FileName)) <> '.ini' then
        FileName  := FileName + '.ini';
    end;
end;

procedure TTscIniFile.DataListAdd(data: TTsrIniFileStructure);
var
  I: Integer;
  cash  : TTsrIniFileStructure;
begin
  if not FDataList.BinarySearch(data,I) then
    FDataList.Add(data);
end;

procedure TTscIniFile.DataListAdd(Section, Key:string; Default:Variant; PReferrer:Pointer; Types:TTseIniFileValueType);
var
  data  : TTsrIniFileStructure;
begin
  data.Section  := Section;
  data.Key      := Key;
  data.Types    := Types;
  case Types of
    IVT_STRING,
    IVT_LABEL_TEXT,
    IVT_EDIT_TEXT         : data.Default  := Default;
    IVT_INTEGER,
    IVT_COMBOBOX_INDEX,
    IVT_TABCONTROL_INDEX  : data.Default  := IntToStr(Default);
    IVT_CHECKBOX_CHECKED  : data.Default  := BoolToStr(Default);
    IVT_NUMBERBOX_VALUE   : data.Default  := FloatToStr(Default);
  end;
  data.PReferrer:= PReferrer;
  DataListAdd(data);
end;

procedure TTscIniFile.DataListClear;
begin
  FDataList.Clear;
end;

function TTscIniFile.GetData(section, key:string):Variant;
begin
  case FDataList[GetIniDataListIndex(section,key)].Types of
    IVT_STRING,
    IVT_LABEL_TEXT  :
      begin
        Result  := FDataList[GetIniDataListIndex(section,key)].Value;
      end;
  end;
end;

function TTscIniFile.GetIniDataListIndex(section, key:string):Integer;
var
  I : Integer;
begin
  for I := 0 to FDataList.Count -1 do
    begin
      if (FDataList[I].Section = section) and (FDataList[I].Key = key) then
        begin
          Result  := I;
          Break;
        end;
    end;
end;

end.
