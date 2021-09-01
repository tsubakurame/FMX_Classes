unit TsuAppData;

interface
uses
  System.IOUtils,
  TsuPathUtilsFMX;

type
  TTscAppData = class(TObject)
    private
      FAppName    : string;
      FMakerName  : string;
      FAppVersion : string;
      FAppTitle   : string;
      FAppDataPath: string;
      FDefaultSavePath  : string;
      procedure CreatePath(ApName:string = ''; MkName:string = '');
      procedure SetAppName(value:string);
      procedure SetMakerName(value:string);
    public
      constructor Create(ApName:string = ''; MkName:string = '');
      property AppName  : string read FAppName write SetAppName;
      property MakerName: string read FMakerName write SetMakerName;
      property AppDataPath  : string read FAppDataPath;
      property DefaultSavePath  : string read FDefaultSavePath;
  end;

implementation

constructor TTscAppData.Create(ApName:string = ''; MkName:string = '');
begin
  CreatePath(ApName, MkName);
end;

procedure TTscAppData.CreatePath(ApName:string = ''; MkName:string = '');
begin
  if ApName <> '' then
    FAppName  := ApName
  else
    FAppName  := TPath.GetFileNameWithoutExtension(ParamStr(0));

  if MkName <> '' then
    FMakerName  := MkName
  else
    FMakerName  := 'FRIENTECH';

  TspGetHomeDirectory(FAppDataPath, FAppName, FMakerName);
  TspGetDefaultSaveDirectory(FDefaultSavePath, FAppName, FMakerName);
end;

procedure TTscAppData.SetAppName(value:string);
begin
  CreatePath(value, FMakerName);
end;

procedure TTscAppData.SetMakerName(value:string);
begin
  CreatePath(FAppName, value);
end;

end.
