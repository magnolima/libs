# MLLib
Just some useful functions. The MLLib contains, so far, these functions:

- MD5OfString(Const Text: string): String;
  Generates the MD5 hash from a string
  
- DistanceInMetersFromCoordinates(Const x1, y1, x2, y2: single; isLongDistance: boolean = False): Single;
 Given a pair of coordinates (degrees), calcute it distance. Set isLongDistace as True if the expected result is more than 100km
 
- DecodeString(Const Text: string; StartKey, MultKey, AddKey: integer): String;
  Simple string decoder using bit wise operation
  
- EncodeString(Const Text: string; StartKey, MultKey, AddKey: integer): String;
  Simple string encoder using bit wise operation
  
- GetProgramVersion: String;
  Retrive application version (Windows/Android)
  
- ColorToFMXColor(const Color: TColor; const FMX: boolean = false): TColor;
  Converts a TColor to FMXColor pattern
  
- RoundUp(const Value: Double; const Decimals: Integer): Double;
  Round a float number to its top 

- HexToIntegerFast(const HexString: string): Integer;
  Fast Hexadecimal to Integer conversion (Windows only)
  
- GetCLIOutput(CommandLine: string; Work: string = 'C:\'): string;
  Intercept command a line execution outputing to string
  
- GetCLIOutputOnce(CommandLine: string; AOutput: TStringList);
  Intercept command a line execution outputing to string, runs once
  
- ExtractURLFromText(const Text: String): TArray<String>;
  Extract URL from a text into a array of string
  
- LogD(const Msg: String): Integer;
  True log.d() for using Android

# Google.Search

A Simple REST lib to use with the Programmable Google Search (https://developers.google.com/custom-search/)

  To use it, you'll need to create an application at the Google control panel and have a app id key, also create a search engine and get its id.
  
  Simple, non-runnable, example:
  ```
  var
    GoogleSearch: TGoogleSearch;

  procedure OnCreate();
  begin
     GoogleSearch: TGoogleSearch.Create(<APP_KEY>, <ENGINE_ID>);
     GoogleSearch.OnResponse := OnGoogleResponse;
  end;
  
  procedure GoogleSearch(Text: String);
  begin
     GoogleSearch.SearchFor := Text;
     GoogleSearch.ExtraParameters.Clear;
     GoogleSearch.ExtraParameters.Add('dateRestrict', 'w8');
     GoogleSearch.ExtraParameters.Add('gsc.sort', 'date');
     GoogleSearch.Execute;
  end;
  
  procedure onGoogleResponse(Sender: TObject);
  var
    Text := '';
    Item: TSearchItem;
  begin
     Text := '';
     for Item in GoogleSearch.SearchResponse.Items do
        Text := Text + Item.title + #13 + Item.snippet + #13 + Item.description + #13 + Item.displayLink + #13#13; 
     
    Memo1.Text := Text;
  end;
  ```
