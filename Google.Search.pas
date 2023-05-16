(*
  (C)2023 Magno Lima - www.MagnumLabs.com.br - Version 1.0

  Delphi libraries for Programmable Search Engine

  This library is licensed under Creative Commons CC-0 (aka CC Zero),
  which means that this a public dedication tool, which allows creators to
  give up their copyright and put their works into the worldwide public domain.
  You're allowed to distribute, remix, adapt, and build upon the material
  in any medium or format, with no conditions.

  Feel free if there's anything you want to contribute.

  https://developers.google.com/custom-search/v1/introduction
*)

unit Google.Search;

interface

uses
   System.SysUtils, System.Types, System.Classes, System.JSON, REST.Client, REST.Types, System.IOUtils,
   System.Generics.Collections;

const
   GOOGLE_ENDPOINT = 'https://www.googleapis.com/customsearch/v1';

type
   TSearchQueries = record
      searchTerms: String;
      count: integer;
   end;

type
   TSearchItem = record
      title: String;
      htmlTitle: String;
      siteNameAuthor: String;
      link: String;
      displayLink: String;
      snippet: String;
      description: String;
      htmlSnippet: String;
      formattedUrl: String;
      fileFormat: String;
   end;

type
   TSearchResponse = record
      Queries: TSearchQueries;
      Items: TArray<TSearchItem>;
   end;

type
   TGoogleSearch = class
   private
      FRESTRequest: TRESTRequest;
      FRESTClient: TRESTClient;
      FRESTResponse: TRESTResponse;
      FStatusCode: integer;
      FOnResponse: TNotifyEvent;
      FOnError: TNotifyEvent;
      FAcceptType: String;
      FContentType: String;
      FEndpoint: String;
      FResource: String;
      FErrorMessage: String;
      FAppKey: String;
      FSearchId: String;
      FSearchFor: String;
      FSearchResponse: TSearchResponse;
      FExtraParameters: TDictionary<String, String>;
      procedure CreateRESTRespose;
      procedure CreateRESTClient;
      procedure CreateRESTRequest;
      procedure HttpClientError(Sender: TCustomRESTClient);
      procedure HttpRequestError(Sender: TCustomRESTRequest);
      procedure AfterExecute(Sender: TCustomRESTRequest);
   public
      constructor Create(const AppKey, SearchId: String);
      destructor Destroy; override;
      procedure ProcessGoogleSearch(Text: String);
      procedure Execute;
   published
      property SearchResponse: TSearchResponse read FSearchResponse;
      property OnResponse: TNotifyEvent read FOnResponse write FOnResponse;
      property SearchId: String write FSearchId;
      property AppKey: String write FAppKey;
      property SearchFor: String read FSearchFor write FSearchFor;
      property ExtraParameters: TDictionary<String, String> read FExtraParameters write FExtraParameters;
   end;

implementation

procedure TGoogleSearch.CreateRESTRespose;
begin
   FAcceptType := 'application/json';
   FContentType := 'application/json';
   //
   FRESTResponse := TRESTResponse.Create(nil);
   FRESTResponse.Name := '_restresponse';
   FRESTResponse.ContentType := FContentType;
end;

procedure TGoogleSearch.CreateRESTClient;
begin
   FRESTClient := TRESTClient.Create(nil);
   FRESTClient.AcceptCharset := 'UTF-8';
   FRESTClient.UserAgent := 'GoogleSearch';
   FRESTClient.Accept := FAcceptType;
   FRESTClient.ContentType := FContentType;
   FRESTClient.OnHTTPProtocolError := HttpClientError;
   FRESTClient.BaseURL := GOOGLE_ENDPOINT;
end;

procedure TGoogleSearch.CreateRESTRequest;
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

procedure TGoogleSearch.AfterExecute(Sender: TCustomRESTRequest);
var
   LStatusCode: integer;
begin
   LStatusCode := FRESTResponse.StatusCode;
   var
      s: string;
   s := FRESTResponse.JSONText;
   Self.ProcessGoogleSearch(FRESTResponse.Content);

   if Assigned(FOnResponse) then
      FOnResponse(Self);
end;

procedure TGoogleSearch.HttpRequestError(Sender: TCustomRESTRequest);
begin
   FStatusCode := FRESTRequest.Response.StatusCode;
   FErrorMessage := FRESTRequest.Response.ErrorMessage;
   FOnError(Self);
end;

procedure TGoogleSearch.HttpClientError(Sender: TCustomRESTClient);
begin
   FErrorMessage := FRESTRequest.Response.ErrorMessage;
   if Assigned(FOnError) then
      FOnError(Self);
end;

constructor TGoogleSearch.Create(const AppKey, SearchId: String);
begin
   FAppKey := AppKey;
   FSearchId := SearchId;
   FExtraParameters := TDictionary<String, String>.Create;
   CreateRESTRespose();
   CreateRESTClient();
   CreateRESTRequest();
end;

destructor TGoogleSearch.Destroy;
begin
   FExtraParameters.Free;
   FRESTResponse.Free;
   FRESTRequest.Free;
   FRESTClient.Free;
   inherited Destroy;
end;

procedure TGoogleSearch.Execute;
var
   Pair: TPair<String, String>;
begin
   // https://developers.google.com/custom-search/v1/reference/rest/v1/cse/list
   FRESTRequest.Cancel;
   FillChar(FSearchResponse, SizeOf(FSearchResponse), 0);
   FRESTRequest.Params.Clear;
   FRESTRequest.Method := TRESTRequestMethod.rmGET;
   FRESTRequest.Params.AddItem('key', FAppKey);
   FRESTRequest.Params.AddItem('cx', FSearchId);
   FRESTRequest.Params.AddItem('q', FSearchFor);

   // https://developers.google.com/custom-search/v1/reference/rest/v1/cse/list
   for Pair in FExtraParameters do
      FRESTRequest.Params.AddItem(Pair.Key, Pair.Value);

   FRESTRequest.Execute;

end;

procedure TGoogleSearch.ProcessGoogleSearch(Text: String);
var
   jsonObject: TJSONObject;
   jsonArray, jsonMeta: TJSONArray;
   I, j: integer;
   description, meta: String;
begin
   TFile.WriteAllText('googlesearch.txt', Text);
   jsonObject := TJSONObject.ParseJSONValue(Text) as TJSONObject;
   FSearchResponse.Queries.count := 0;
   if jsonObject <> nil then
      try
         // Query
         jsonArray := jsonObject.Get('queries').JsonValue.GetValue<TJSONArray>('request');
         if jsonArray <> nil then
            FSearchResponse.Queries.searchTerms := jsonArray[0].GetValue<string>('searchTerms');

         // Items
         jsonArray := jsonObject.GetValue('items') as TJSONArray;

         if jsonArray <> nil then
         begin
            FSearchResponse.Queries.count := jsonArray.count; // more precise
            if jsonArray.count > 0 then
            begin
               SetLength(FSearchResponse.Items, jsonArray.count);
               for I := 0 to jsonArray.count - 1 do
               begin
                  FSearchResponse.Items[I].title := jsonArray[I].GetValue<string>('title');
                  FSearchResponse.Items[I].htmlTitle := jsonArray[I].GetValue<string>('htmlTitle');
                  FSearchResponse.Items[I].link := jsonArray[I].GetValue<string>('link');
                  FSearchResponse.Items[I].displayLink := jsonArray[I].GetValue<string>('displayLink');
                  FSearchResponse.Items[I].snippet := jsonArray[I].GetValue<string>('snippet');
                  FSearchResponse.Items[I].htmlSnippet := jsonArray[I].GetValue<string>('htmlSnippet');
                  FSearchResponse.Items[I].formattedUrl := jsonArray[I].GetValue<string>('formattedUrl');
                  jsonArray[I].TryGetValue<string>('fileFormat', FSearchResponse.Items[I].fileFormat);
                  if FSearchResponse.Items[I].title = 'Untitled' then
                     FSearchResponse.Items[I].title := FSearchResponse.Items[I].displayLink + ' (' +
                       FSearchResponse.Items[I].fileFormat + ')';

                  meta := '';
                  description := '';
                  if jsonArray[I].TryGetValue<TJSONArray>('pagemap.metatags', jsonMeta) then
                  begin
                     for j := 0 to jsonMeta.count - 1 do
                     begin
                        jsonMeta[j].TryGetValue<string>('og:description', description);
                        jsonMeta[j].TryGetValue<string>('og:site_name', meta);
                        if not meta.IsEmpty then
                           break;
                        jsonMeta[j].TryGetValue<string>('author', meta);
                        if not meta.IsEmpty then
                           break;
                     end;
                  end;
                  FSearchResponse.Items[I].description := description;
                  if not meta.IsEmpty then
                     FSearchResponse.Items[I].siteNameAuthor := meta
                  else if FSearchResponse.Items[I].displayLink <> FSearchResponse.Items[I].title then
                  begin
                     FSearchResponse.Items[I].siteNameAuthor := FSearchResponse.Items[I].displayLink
                  end;

               end;

            end;
         end;
      finally
         jsonObject.Free;
      end;
end;

end.
