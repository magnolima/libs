unit MLLib;

interface

uses 
  System.SysUtils, System.StrUtils, System.Math, IdHashMessageDigest, System.RegularExpressions
{$IF Defined(ANDROID)}
  , Androidapi.Helpers, Androidapi.JNI.GraphicsContentViewText,
  DW.MultiReceiver.Android, Androidapi.JNI.Support
{$ENDIF};

type TEnumConverter = class
  public
    class function EnumToInt<T>(const EnumValue: T): Integer;
    class function EnumToString<T>(EnumValue: T): string;
  end;

interface

function MD5OfString(Const Text: string): String;
function DistanciaGrauToMetro(Const x1, y1, x2, y2: single; LongaDistancia: boolean = False): Single;
function DecodeString(Const Text: string; StartKey, MultKey, AddKey: integer): String;
function EncodeString(Const Text: string; StartKey, MultKey, AddKey: integer): String;
function GetProgramVersion: String;
function ColorToFMXColor(const Color: TColor; const FMX: boolean = false): TColor;
{$IF Defined(MSWINDOWS)}
function HexToIntegerFast(const HexString: string): Integer;
function GetCLIOutput(CommandLine: string; Work: string = 'C:\'): string;
procedure GetCLIOutputOnce(CommandLine: string; AOutput: TStringList);
function ExtractURLFromText(const Text: String): TArray<String>;
{$ENDIF};

implentation

(* Set color... *)
function ColorToFMXColor(const Color: TColor; const FMX: boolean = false): TColor;
const
	COLOR_ALPHA = 4278190080;
var
	HexColor: String;
begin
	if FMX then
	begin
		HexColor := IntToHex(Color);
		Result := StrToInt('$FF' + Copy(HexColor, 7, 2) + Copy(HexColor, 5, 2) + Copy(HexColor, 3, 2));
	end
	else
		Result := COLOR_ALPHA + Color
end;

(* Extract the URLs found in a text - it's a bit tricky *)
function ExtractURLFromText(const Text: String): TArray<String>;
var
  FoundCollection: TMatchCollection;
  Found: TMatch;
  MyRegex: string;
begin
  SetLength(Result,0);
  //myregex := 'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)';
  MyRegex := '(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-&?=%.]+';
  FoundCollection := TRegEx.Matches(Text, MyRegex,[roIgnoreCase]);
  for Found in FoundCollection do
  begin
    SetLength(Result,Length(Result)+1);
    Result[Length(Result)-1] := Found.Value;
  end;
end;

(* Simply generantes the MD5 of a given string *)
function MD5OfString(Const Text: string): String;
begin
  with TIdHashMessageDigest5.Create do
  begin
    Result := HashStringAsHex(Text);
    Free;
  end;
end;

(* Calculates the distance in meters from degree coordinates *)
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

(* Encode a string *)
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

(* Decode that string *)
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
(* Windows only fast conversion from hexa number to integer *)
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

(* Get the software version - Windows or Android *)
function GetProgramVersion: String;
begin
  Result := '1.0.0.0'; // iOS not implemented
{$IF Defined(MSWINDOWS)}
  Result := GetWindowsProgramVersion();
{$ENDIF}
{$IF Defined(ANDROID)}
  Result := GetAndroidProgramVersion();
{$ENDIF}
end;

{$IF Defined(MSWINDOWS)}
// Obtem versao de um executável no Windows
// Exemplo: versao := GetProgramVersion( ParamStr(0) 
procedure GetWindowsProgramVersion: String;
{ by Steve Schafer }
var
   major, minor, release, build: Word
   VerInfoSize: DWORD;
   VerInfo: Pointer;
   VerValueSize: DWORD;
   VerValue: PVSFixedFileInfo;
   Dummy: DWORD;
begin
   VerInfoSize := GetFileVersionInfoSize(PChar(ParamStr(0)), Dummy);
   GetMem(VerInfo, VerInfoSize);
   GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, VerInfo);
   major := 1;
   minor := 0;
   release := 0;
   build := 0;

   if VerInfo <> nil then
   begin
      VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
      with VerValue^ do
      begin
         major := dwFileVersionMS shr 16;
         minor := dwFileVersionMS and $FFFF;
         release := dwFileVersionLS shr 16;
         build := dwFileVersionLS and $FFFF;
      end;
   end;
   Result := Format('%d.%d.%d.%d', [major, minor, release, build]);
   FreeMem(VerInfo, VerInfoSize);
end;
{$ENDIF}

/// *********** ANDROID EXCLUSIVAMENTE ********* \\\\
// Obtem versao de um pacote Android
// Exemplo: versao := GetProgramVersion();
{$IF Defined(ANDROID)}
function GetAndroidProgramVersion: String;
var
  PackageManager: JPackageManager;
  PackageInfo: JPackageInfo;
begin
  PackageManager := TAndroidHelper.Context.getPackageManager;
  PackageInfo := PackageManager.getPackageInfo(TAndroidHelper.Context.getPackageName, 0);
  Result := JStringToString(PackageInfo.versionName);
end;
{$ENDIF}

// Obtem nome do enumerador ou seu indice
class function TEnumConverter.EnumToInt<T>(const EnumValue: T): Integer;
begin
   Result := 0;
   Move(EnumValue, Result, sizeOf(EnumValue));
end;

class function TEnumConverter.EnumToString<T>(EnumValue: T): string;
begin
   Result := GetEnumName(TypeInfo(T), EnumToInt(EnumValue));
end;

{$IF Defined(MSWINDOWS)}
// Source https://stackoverflow.com/questions/9119999/getting-output-from-a-shell-dos-app-into-a-delphi-app
(* Allows execute a command line program and catch the output lines *)
function GetCLIOutput(CommandLine: string; Work: string = 'C:\'): string;
var
  SA: TSecurityAttributes;
  SI: TStartupInfo;
  PI: TProcessInformation;
  StdOutPipeRead, StdOutPipeWrite: THandle;
  WasOK: Boolean;
  Buffer: array[0..255] of AnsiChar;
  BytesRead: Cardinal;
  WorkDir: string;
  Handle: Boolean;
begin
  Result := '';
  with SA do begin
    nLength := SizeOf(SA);
    bInheritHandle := True;
    lpSecurityDescriptor := nil;
  end;
  CreatePipe(StdOutPipeRead, StdOutPipeWrite, @SA, 0);
  try
    with SI do
    begin
      FillChar(SI, SizeOf(SI), 0);
      cb := SizeOf(SI);
      dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
      wShowWindow := SW_HIDE;
      hStdInput := GetStdHandle(STD_INPUT_HANDLE); // don't redirect stdin
      hStdOutput := StdOutPipeWrite;
      hStdError := StdOutPipeWrite;
    end;
    WorkDir := Work;
    Handle := CreateProcess(nil, PChar('cmd.exe /C ' + CommandLine),
                            nil, nil, True, 0, nil,
                            PChar(WorkDir), SI, PI);
    CloseHandle(StdOutPipeWrite);
    if Handle then
      try
        repeat
          WasOK := ReadFile(StdOutPipeRead, Buffer, 255, BytesRead, nil);
          if BytesRead > 0 then
          begin
            Buffer[BytesRead] := #0;
            Result := Result + Buffer;
          end;
        until not WasOK or (BytesRead = 0);
        WaitForSingleObject(PI.hProcess, INFINITE);
      finally
        CloseHandle(PI.hThread);
        CloseHandle(PI.hProcess);
      end;
  finally
    CloseHandle(StdOutPipeRead);
  end;
end;

// Lê informações de uma vez para AOutput
(* Allows execute a command line program and catch the output lines - v2 *)
procedure GetCLIOutputOnce(CommandLine: string; AOutput: TStringList);
const
  READ_BUFFER_SIZE = 8000; // aumentado para 8K+-
var
  Security: TSecurityAttributes;
  readableEndOfPipe, writeableEndOfPipe: THandle;
  start: TStartUpInfo;
  ProcessInfo: TProcessInformation;
  Buffer: PAnsiChar;
  BytesRead: DWORD;
  AppRunning: DWORD;
begin
  Security.nLength := SizeOf(TSecurityAttributes);
  Security.bInheritHandle := true;
  Security.lpSecurityDescriptor := nil;

  if CreatePipe( { var } readableEndOfPipe, { var } writeableEndOfPipe, @Security, 0) then
  begin
    Buffer := AllocMem(READ_BUFFER_SIZE + 1);
    FillChar(start, SizeOf(start), #0);
    start.cb := SizeOf(start);

    // Set up members of the STARTUPINFO structure.
    // This structure specifies the STDIN and STDOUT handles for redirection.
    // - Redirect the output and error to the writeable end of our pipe.
    // - We must still supply a valid StdInput handle (because we used STARTF_USESTDHANDLES to swear that all three handles will be valid)
    start.dwFlags := start.dwFlags or STARTF_USESTDHANDLES;
    start.hStdInput := GetStdHandle(STD_INPUT_HANDLE);
    // we're not redirecting stdInput; but we still have to give it a valid handle
    start.hStdOutput := writeableEndOfPipe;
    // we give the writeable end of the pipe to the child process; we read from the readable end
    start.hStdError := writeableEndOfPipe;

    // We can also choose to say that the wShowWindow member contains a value.
    // In our case we want to force the console window to be hidden.
    start.dwFlags := start.dwFlags + STARTF_USESHOWWINDOW;
    start.wShowWindow := SW_HIDE;

    // Don't forget to set up members of the PROCESS_INFORMATION structure.
    ProcessInfo := Default (TProcessInformation);

    // WARNING: The unicode version of CreateProcess (CreateProcessW) can modify the command-line "DosApp" string.
    // Therefore "DosApp" cannot be a pointer to read-only memory, or an ACCESS_VIOLATION will occur.
    // We can ensure it's not read-only with the RTL function: UniqueString
    UniqueString( { var } CommandLine);

    if CreateProcess(nil, PChar(CommandLine), nil, nil, true, NORMAL_PRIORITY_CLASS, nil, nil, start, { var } ProcessInfo)
    then
    begin
      // Wait for the application to terminate, as it writes it's output to the pipe.
      // WARNING: If the console app outputs more than 2400 bytes (ReadBuffer),
      // it will block on writing to the pipe and *never* close.
      repeat
        AppRunning := WaitForSingleObject(ProcessInfo.hProcess, 100);
        // Application.ProcessMessages;
      until (AppRunning <> WAIT_TIMEOUT);

      // Read the contents of the pipe out of the readable end
      // WARNING: if the console app never writes anything to the StdOutput, then ReadFile will block and never return
      repeat
        BytesRead := 0;
        ReadFile(readableEndOfPipe, Buffer[0], READ_BUFFER_SIZE, { var } BytesRead, nil);
        Buffer[BytesRead] := #0;
        OemToAnsi(Buffer, Buffer);
        AOutput.Text := AOutput.Text + String(Buffer);
      until (BytesRead < READ_BUFFER_SIZE);
    end;
    FreeMem(Buffer);
    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
    CloseHandle(readableEndOfPipe);
    CloseHandle(writeableEndOfPipe);
  end;
end;
{$ENDIF}

end.
