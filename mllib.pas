unit MLLib;

interface

uses 
  System.SysUtils, System.StrUtils, System.Math, IdHashMessageDigest
{$IF Defined(ANDROID)}
  , Androidapi.Helpers, Androidapi.JNI.GraphicsContentViewText,
  DW.MultiReceiver.Android, Androidapi.JNI.Support
{$ENDIF};

interface

function MD5OfString(Const Text: string): String;
function DistanciaGrauToMetro(Const x1, y1, x2, y2: single; LongaDistancia: boolean = False): Single;
function DecodeString(Const Text: string; StartKey, MultKey, AddKey: integer): String;
function EncodeString(Const Text: string; StartKey, MultKey, AddKey: integer): String;
{$IF Defined(ANDROID)}
function GetProgramVersion: String;
{$ENDIF};
{$IF Defined(MSWINDOWS)}
function GetProgramVersion(const FileName: TFileName): String;
{$ENDIF};

implentation

function MD5OfString(Const Text: string): String;
begin
  with TIdHashMessageDigest5.Create do
  begin
    Result := HashStringAsHex(Text);
    Free;
  end;
end;

function DistanciaGrauToMetro(Const x1, y1, x2, y2: single; LongaDistancia: boolean = False): single;
var
  fGrauRadiano, fLatitudeRadiano, fDistancia: double;
begin

  if LongaDistancia then
  begin
    Result := round((2 * Pi * 6366.71 / 360) * 2 * arcsin(sqrt(power(sin(((x1 - x2) / 2) * (2 * Pi) / 360), 2) + cos(x1 * (2 * Pi) / 360) *
      cos(x2 * (2 * Pi) / 360) * power(sin(((y1 - y2) / 2) * (2 * Pi) / 360), 2))) * (360 / (2 * Pi)) * 1000);
    Exit;
  end;

  fGrauRadiano := 0.017453292519943295769236907684886;
  fLatitudeRadiano := fGrauRadiano * ((y1 + y2) / 2);
  fDistancia := sqrt(power((x1 - x2), 2) + power((y1 - y2), 2)) * cos(fLatitudeRadiano) * 111319.49166666666666666666666667;
  Result := round(fDistancia);
end;

function EncodeString(Const Text: string; StartKey, MultKey, AddKey: integer): string;
var
  i: Word;
begin
  Result := '';
  for i := Low(Text) to High(Text) do
  begin
    Result := Result + WideChar(Ord(Text[i]) xor (StartKey shr 8));
    StartKey := (Ord(Result[i]) + StartKey) * MultKey + AddKey;
  end;
end;

function DecodeString(Const Text: string; StartKey, MultKey, AddKey: integer): string;
var
  i: Word;
begin
  Result := '';
  for i := Low(Text) to High(Text) do
  begin
    Result := Result + WideChar(Ord(Text[i]) xor (StartKey shr 8));
    StartKey := (Ord(Text[i]) + StartKey) * MultKey + AddKey;
  end;
end;

{$IF Defined(MSWINDOWS)}
// Obtem versao de um executável no Windows
// Exemplo: versao := GetProgramVersion( ParamStr(0) )
function GetProgramVersion(const FileName: TFileName): String;
var
  VerInfoSize: Cardinal;
  VerValueSize: Cardinal;
  Dummy: Cardinal;
  PVerInfo: Pointer;
  PVerValue: PVSFixedFileInfo;
begin
  Result := '';
  VerInfoSize := GetFileVersionInfoSize(PChar(FileName), Dummy);
  GetMem(PVerInfo, VerInfoSize);
  try
    if GetFileVersionInfo(PChar(FileName), 0, VerInfoSize, PVerInfo) then
      if VerQueryValue(PVerInfo, '\', Pointer(PVerValue), VerValueSize) then
        with PVerValue^ do
          Result := Format('%d.%d.%d.%d', [HiWord(dwFileVersionMS), // Major
            LoWord(dwFileVersionMS), // Minor
            HiWord(dwFileVersionLS), // Release
            LoWord(dwFileVersionLS)]); // Build
  finally
    FreeMem(PVerInfo, VerInfoSize);
  end;
end;
{$ENDIF}

{$IF Defined(ANDROID)}
// Obtem versao de um pacote Android
// Exemplo: versao := GetProgramVersion();
function GetProgramVersion: String;
var
  PackageManager: JPackageManager;
  PackageInfo: JPackageInfo;
begin
  PackageManager := TAndroidHelper.Context.getPackageManager;
  PackageInfo := PackageManager.getPackageInfo(TAndroidHelper.Context.getPackageName, 0);
  Result := JStringToString(PackageInfo.versionName);
end;
{$ENDIF}

end.
