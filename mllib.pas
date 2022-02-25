unit MLLib;

interface

uses 
  System.Math;

interface

function DistanciaGrauToMetro(Const x1, y1, x2, y2: single; LongaDistancia: boolean = False): single;
function DecodeString(Const Text: string; StartKey, MultKey, AddKey: integer): string;
function EncodeString(Const Text: string; StartKey, MultKey, AddKey: integer): string;

implentation

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

end.
