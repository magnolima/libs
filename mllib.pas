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
function HexToIntegerFast(const HexString: string): Integer;
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

/// *********** WINDOWS EXCLUSIVAMENTE ********* \\\\
{$IF Defined(MSWINDOWS)}

// Converção de hexadecimal para inteiro utilizando
// chamadas MMX para alta performance
function HexToIntegerFast(const HexString: string): Integer;
const
  ASCIINines: Int64 = $3939393939393939;
  Nines: Int64 = $0909090909090909;
  LowNibbles: Int64 = $0F0F0F0F0F0F0F0F;
  AlternateBytes: Int64 = $00FF00FF00FF00FF;
  asm
    { On entry:
    eax = pointer to HexString }
    { Blank string? }
    or eax,eax
    jz @Done
    { Get the string length }
    mov ecx, [eax - 4]
    { Set up mmx registers }
    movq mm2, ASCIINines
    movq mm3, Nines
    movq mm4, LowNibbles
    movq mm5, AlternateBytes
    { Get up to 8 characters into mm0. We can safely read a qword here since
    the
    first character of a string is preceded by two dwords (the length and the
    reference count). Since the maximum length of a string for this function
    is
    8 characters, there will also be 3 #0 characters preceding the first
    character of the string. }
    movq mm0, [eax + ecx - 8]
    { Add 9 to all characters>57 ('9') }
    movq mm1, mm0
    pcmpgtb mm1, mm2
    pand mm1, mm3
    paddb mm0, mm1
    { Extract only the low nibbles }
    pand mm0, mm4
    { Shift the nibbles into position }
    movq mm1, mm0
    psllq mm1, 4
    psrlq mm0, 8
    { Bitwise Or so that we have the nibbles in the order ...4534231201 }
    por mm0, mm1
    { Keep only every second byte ...45xx23xx01 }
    pand mm0, mm5
    { Now we need to extract every second byte into a dword ...452301 }
    packuswb mm0, mm0
    { Get the result in eax }
    movd eax, mm0
    { Exit mmx machine state }
    emms
    { Valid number of characters? ->If more than 8 we zero the result }
    sub ecx, 9
    sbb edx, edx
    and eax, edx
    { Are there at least 5 characters, i.e. should we keep the high word? }
    add ecx, 4
    sbb edx, edx
    and ax, dx
    { Swap bytes into their correct positions }
    bswap eax
  @Done:

end;

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

/// *********** ANDROID EXCLUSIVAMENTE ********* \\\\
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
