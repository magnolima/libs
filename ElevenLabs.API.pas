(*
  (C)2023 Magno Lima - www.MagnumLabs.com.br - Version 1.0

  Delphi libraries for using ElevenLabs API

  This library is licensed under Creative Commons CC-0 (aka CC Zero),
  which means that this a public dedication tool, which allows creators to
  give up their copyright and put their works into the worldwide public domain.
  You're allowed to distribute, remix, adapt, and build upon the material
  in any medium or format, with no conditions.

  Feel free if there's anything you want to contribute.

  https://api.elevenlabs.io/docs
*)

unit ElevenLabs.API;

interface

uses
   System.Diagnostics, System.Classes, System.SysUtils, Data.Bind.Components,
   Data.Bind.ObjectScope, REST.Client, REST.Types,
   FireDAC.Stan.Intf,
   FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error,
   REST.Response.Adapter,
   FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, System.StrUtils,
   System.Generics.Collections,
   Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, System.Types,
   System.IOUtils, System.TypInfo, System.JSON;

const
   ElevenLabsEndpoint = 'https://api.elevenlabs.io/v1';
   FILE_BUFFER = '.\output.mp3';

type
   TElevenLabsRequest = (rqNone, rqTalk, rqTTSStream, rqVoice, rqVoiceDefault, rqVoiceSettings, rqGetVoices,
     rqDeleteVoice, rqEditVoiceSettings, rqVoiceAdd, rqVoiceEdit);

type
   TElevenLabs = class
   private
      FRESTRequest: TRESTRequest;
      FAcceptType: String;
      FContentType: String;
      FEndpoint: String;
      FResource: String;
      FErrorMessage: String;
      FText: String;
      FVoiceId: String;
      FAPIKey: String;
      FBody: String;
      FFileBuffer: String;
      FSimilarity: Single;
      FSimilarityBoost: Single;
      FVoiceList: TDictionary<String, String>;
      FOnResponse: TNotifyEvent;
      FOnError: TNotifyEvent;
      FOrganization: String;
      FRequest: TElevenLabsRequest;
      FRESTClient: TRESTClient;
      FRESTResponse: TRESTResponse;
      FStatusCode: Integer;
      FFilename: String;
      FVoiceOutput: TMemoryStream;
      FVoices: TDictionary<String, String>;
      procedure SetEndPoint(const Value: String);
      procedure SetApiKey(const Value: string);
      procedure SetVoiceId(const Value: String);
      procedure CreateRESTRespose;
      procedure CreateRESTClient;
      procedure CreateRESTRequest;
      procedure HttpRequestError(Sender: TCustomRESTRequest);
      procedure HttpClientError(Sender: TCustomRESTClient);
      procedure SetAuthorization;
      procedure SetVoicesResult;
      procedure SetupParameters;
      procedure GetVoices;
      procedure setRequest(const Value: TElevenLabsRequest);
      procedure ProcessVoice;
      procedure SetVoices(const Value: TDictionary<String, String>);
   public
      constructor Create(const APIFileName: String = ''); overload;
      destructor Destroy; override;
      property ErrorMessage: String read FErrorMessage;
      procedure Talk(const VoiceId, Text: String); overload;
   published
      procedure Execute;
      procedure Stop;
      property VoiceOutput: TMemoryStream read FVoiceOutput;
      property Request: TElevenLabsRequest read FRequest write setRequest;
      procedure ExecuteAsync(pProcEndExec: TProc; pProcError: TProc<string>);
      procedure AfterExecute(Sender: TCustomRESTRequest);
      property OnResponse: TNotifyEvent read FOnResponse write FOnResponse;
      property OnError: TNotifyEvent read FOnError write FOnError;
      property StatusCode: Integer read FStatusCode;
      property Endpoint: String read FEndpoint write SetEndPoint;
      property APIKey: String read FAPIKey write SetApiKey;
      property AvailableVoices: TDictionary<String, String> read FVoiceList;
      property FileBuffer: String read FFileBuffer;
      property VoiceId: String read FVoiceId write SetVoiceId;
      procedure Talk(const Text: String); overload;
      property Voices: TDictionary<String, String> read FVoices write SetVoices;
   end;

implementation

{ TElevenLabs }

procedure TElevenLabs.CreateRESTRespose;
begin
   FAcceptType := 'application/json';
   FContentType := 'application/json';
   //
   FRESTResponse := TRESTResponse.Create(nil);
   FRESTResponse.Name := '_restresponse';
   FRESTResponse.ContentType := FContentType;
end;

constructor TElevenLabs.Create(const APIFileName: String);
begin
   FVoices := TDictionary<String, String>.Create;
   FVoiceOutput := TMemoryStream.Create;
   FErrorMessage := '';
   FOnResponse := nil;
   FFileBuffer := FILE_BUFFER;
   CreateRESTRespose();
   CreateRESTClient();
   CreateRESTRequest();
   SetEndPoint('');

   if not APIFileName.IsEmpty then
   begin
      // test if it's a file! =)
      if FileExists(APIFileName) then
         FAPIKey := Tfile.ReadAllText(APIFileName)
      else
         FAPIKey := APIFileName;
      SetApiKey(FAPIKey);
   end;
end;

destructor TElevenLabs.Destroy;
begin
   FVoiceOutput.Free;
   FRESTResponse.Free;
   FRESTRequest.Free;
   FRESTClient.Free;
   FVoices.Free;
   inherited Destroy;
end;

procedure TElevenLabs.CreateRESTClient;
begin
   FRESTClient := TRESTClient.Create(nil);
   FRESTClient.AcceptCharset := 'UTF-8';
   FRESTClient.UserAgent := 'ElevenLabsClient';
   FRESTClient.Accept := FAcceptType;
   FRESTClient.ContentType := FContentType;
   FRESTClient.OnHTTPProtocolError := HttpClientError;
end;

procedure TElevenLabs.CreateRESTRequest;
begin
   FRESTRequest := TRESTRequest.Create(nil);
   FRESTRequest.AcceptCharset := 'UTF-8';
   FRESTRequest.Accept := FAcceptType;
   FRESTRequest.Method := TRESTRequestMethod.rmPOST;
   FRESTRequest.Params.Clear;
   FRESTRequest.Body.ClearBody;
   FRESTRequest.Response := FRESTResponse;
   FRESTRequest.Client := FRESTClient;
   FRESTRequest.OnAfterExecute := AfterExecute;
   FRESTRequest.OnHTTPProtocolError := HttpRequestError;
end;

procedure TElevenLabs.HttpRequestError(Sender: TCustomRESTRequest);
begin
   FRequest := rqNone;
   FStatusCode := FRESTRequest.Response.StatusCode;
   FErrorMessage := FRESTRequest.Response.ErrorMessage;
   FOnError(Self);
end;

procedure TElevenLabs.HttpClientError(Sender: TCustomRESTClient);
begin
   FRequest := rqNone;
   FErrorMessage := FRESTRequest.Response.ErrorMessage;
   FOnError(Self);
end;

procedure TElevenLabs.SetEndPoint(const Value: String);
var
   Endpoint: String;
begin
   if Value.IsEmpty then
      Endpoint := ElevenLabsEndpoint
   else
      Endpoint := Value;
   FEndpoint := Endpoint;
   FRESTClient.BaseURL := Endpoint;
end;

procedure TElevenLabs.setRequest(const Value: TElevenLabsRequest);
begin
   FRequest := Value;
end;

procedure TElevenLabs.SetVoiceId(const Value: String);
var
   lVoiceId: TArray<String>;
begin
   lVoiceId := Value.Split([';']);
   if Length(lVoiceId) = 2 then
      FVoiceId := lVoiceId[0]
   else
      FVoiceId := Value;
end;

procedure TElevenLabs.Stop;
begin
   FRequest := rqNone;
end;

procedure TElevenLabs.AfterExecute(Sender: TCustomRESTRequest);
var
   LStatusCode: Integer;
begin

   LStatusCode := FRESTResponse.StatusCode;

   if FStatusCode = 0 then
      FStatusCode := LStatusCode;

   if not(FStatusCode in [200, 201]) then
      Exit;

   case FRequest of
      rqNone:
         ;
      rqGetVoices:
         SetVoicesResult;
      rqTalk:
         ProcessVoice;
   end;

   if Assigned(FOnResponse) then
      FOnResponse(Self);
   FRequest := rqNone;
end;

procedure TElevenLabs.ProcessVoice;
var
   s: string;
begin
   FVoiceOutput.Clear;
   try
      s := FRESTResponse.Content;

      FVoiceOutput.Write(FRESTResponse.RawBytes, Length(FRESTResponse.RawBytes));
      FVoiceOutput.SaveToFile(FFileBuffer);
   except
      raise Exception.Create('Error creating output speech buffer');
   end;
end;

procedure TElevenLabs.SetAuthorization;
begin
   FRESTRequest.Params.Clear;
   FRESTRequest.Params.AddHeader('xi-api-key', FAPIKey);
   FRESTRequest.Params.AddHeader('accept', 'audio/mpeg');
   FRESTRequest.Params.ParameterByName('xi-api-key').Options := [poDoNotEncode];
end;

procedure TElevenLabs.SetApiKey(const Value: string);
begin
   FAPIKey := Value;
end;

procedure TElevenLabs.Execute;
begin
   case FRequest of
      rqGetVoices:
         GetVoices;
      rqTalk:
         FRESTRequest.Execute;
   end;
end;

procedure TElevenLabs.ExecuteAsync(pProcEndExec: TProc; pProcError: TProc<string>);
begin
   TThread.CreateAnonymousThread(
      procedure
      begin
         case FRequest of
            rqGetVoices:
               GetVoices;
            rqTalk:
               FRESTRequest.Execute;
         end;
         try
            try
               Execute;
            except
               on E: Exception do
               begin
                  if Assigned(pProcError) then
                     TThread.Synchronize(nil,
                        procedure
                        begin
                           pProcError(E.Message);
                        end);
               end;
            end;
         finally
            if Assigned(pProcEndExec) then
               TThread.Synchronize(nil,
                  procedure
                  begin
                     pProcEndExec;
                  end);
         end;
      end).Start;
end;

procedure TElevenLabs.GetVoices;
begin
   SetAuthorization();
   FRESTRequest.ClearBody;
   FRESTRequest.Method := TRESTRequestMethod.rmGET;
   FRESTRequest.Resource := '/voices';
   FBody := '';
   FRESTRequest.Body.Add(FBody, TRESTContentType.ctAPPLICATION_JSON);
   FRESTRequest.Execute;
end;

procedure TElevenLabs.Talk(const VoiceId, Text: String);
begin
   SetVoiceId(VoiceId);
   Talk(Text);
end;

procedure TElevenLabs.Talk(const Text: String);
begin
   SetAuthorization();
   FText := Text;
   FRESTRequest.ClearBody;
   FRESTRequest.Method := TRESTRequestMethod.rmPOST;
   FRESTRequest.Resource := '/text-to-speech/' + FVoiceId;
   SetupParameters();
   FRESTRequest.Body.Add(FBody, TRESTContentType.ctAPPLICATION_JSON);
   FRESTRequest.ExecuteAsync();
end;

procedure TElevenLabs.SetupParameters;
var
   AJSONObject, VoiceSettings: TJSONObject;
   JSONArray: TJSONArray;
   Value, Stop: String;
begin
   AJSONObject := TJSONObject.Create;
   VoiceSettings := TJSONObject.Create;
   JSONArray := nil;
   try
      AJSONObject.AddPair(TJSONPair.Create('text', FText));
      VoiceSettings.AddPair(TJSONPair.Create('stability', TJSONNumber.Create(FSimilarity)));
      VoiceSettings.AddPair(TJSONPair.Create('similarity_boost', TJSONNumber.Create(FSimilarityBoost)));
      AJSONObject.AddPair(TJSONPair.Create('voice_settings', VoiceSettings));

      FBody := UTF8ToString(AJSONObject.ToJSON);

   finally
      AJSONObject.Free;
      AJSONObject := nil;
      JSONArray := nil;
   end;

end;

procedure TElevenLabs.SetVoices(const Value: TDictionary<String, String>);
begin
   FVoices := Value;
end;

procedure TElevenLabs.SetVoicesResult;
var
   jsonStr: string;
   jsonObj, voiceObj: TJSONObject;
   voicesArr: TJSONArray;
   i: Integer;
begin

   voiceObj := TJSONObject.Create;
   voicesArr := TJSONArray.Create;
   jsonObj := TJSONObject.ParseJSONValue(FRESTResponse.Content) as TJSONObject;

   FVoices.Clear;
   try
      voicesArr := jsonObj.GetValue('voices') as TJSONArray;
      for i := 0 to voicesArr.Count - 1 do
      begin
         voiceObj := voicesArr.Items[i] as TJSONObject;
         jsonStr := voiceObj.GetValue('preview_url').Value;
         FVoices.Add(voiceObj.GetValue('name').Value, voiceObj.GetValue('voice_id').Value + ';' + jsonStr);
      end;
   finally
      voicesArr := nil;
      jsonObj.Free;
      voiceObj := nil;
   end;
end;

end.
