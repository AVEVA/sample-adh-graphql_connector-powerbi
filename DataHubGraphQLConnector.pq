// This file contains your Data Connector logic
[Version = "1.0.0"]
section DataHubGraphQLConnector;

// Note: Client ID should be an Authorization Code Client with the below redirect_uri and logout_uri
client_id = TryRetrieveParameterFromAppsettings("ClientId");

// ADH values
resource = TryRetrieveParameterFromAppsettings("Resource");
authorize_uri = Text.Combine({resource, "/identity/connect/authorize"});
token_uri = Text.Combine({resource, "/identity/connect/token"});
scope = "ocsapi";

// OAuth values for PowerBI
redirect_uri = "https://oauth.powerbi.com/views/oauthredirect.html";
logout_uri = "https://login.microsoftonline.com/logout.srf";

// Authorization Code + PKCE verifier/challenge
code_verifier = Base64Encode(GenerateRandomBytes(32));
// Note: Crypto and CryptoAlgorithm are not documented and can only be used inside Custom Data Connectors
code_challenge = Base64Encode(
    Crypto.CreateHash(CryptoAlgorithm.SHA256, Text.ToBinary(code_verifier, TextEncoding.Ascii))
);

// Crypto functions for Authorization Code + PKCE
GenerateRandomBytes = (count as number) =>
    let
        RandomBit = () => Number.Round(Number.RandomBetween(0, 255)),
        list = List.Generate(
            () => [x = RandomBit(), y = {}], each List.Count([y]) < count, each [x = RandomBit(), y = [y] & {x}],
            each
                [x]
        ),
        binary = Binary.FromList(list)
    in
        binary;

Base64Encode = (str as binary) =>
    let
        unescaped = Binary.ToText(str, BinaryEncoding.Base64),
        text = Text.Replace(Text.Replace(Text.Replace(unescaped, "+", "-"), "/", "_"), "=", "")
    in
        text;
// Login modal window dimensions
windowWidth = 720;
windowHeight = 1024;

[DataSource.Kind = "DataHubGraphQLConnector", Publish = "DataHubGraphQLConnector.Publish"]
shared DataHubGraphQLConnector.Contents = Value.ReplaceType(GraphQLQuery, GraphQLQueryType);

GraphQLQueryType = type function (
    namespaceId as (
        type text meta [
            Documentation.FieldCaption = "Namespace Id",
            Documentation.FieldDescription = "The Id of the Namespace to query"
        ]
    )
) as binary meta [
    Documentation.Name = "AVEVA Data Hub GraphQL"
];

GraphQLQuery = (namespaceId as text) as function =>
    let
        url = resource & "/api/v1/Tenants/" & GetTenantId() & "/Namespaces/" & namespaceId,
        result = Json.Document(Web.Contents(url)),
        self = result[Self],
        query = GraphQL(self)
    in
        query;

// Data Source Kind description
DataHubGraphQLConnector = [
    TestConnection = (dataSourcePath) => {"DataHubGraphQLConnector.Contents", dataSourcePath},
    Authentication = [
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin,
            Refresh = Refresh,
            Logout = Logout
        ]
    ]
];

// Data Source UI publishing description
DataHubGraphQLConnector.Publish = [
    Beta = true,
    Category = "Online Services",
    ButtonText = {Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp")},
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = DataHubConnector.Icons,
    SourceTypeImage = DataHubConnector.Icons
];

DataHubConnector.Icons = [
    Icon16 = {
        Extension.Contents("DataHubGraphQLConnector16.png"),
        Extension.Contents("DataHubGraphQLConnector20.png"),
        Extension.Contents("DataHubGraphQLConnector24.png"),
        Extension.Contents("DataHubGraphQLConnector32.png")
    },
    Icon32 = {
        Extension.Contents("DataHubGraphQLConnector32.png"),
        Extension.Contents("DataHubGraphQLConnector40.png"),
        Extension.Contents("DataHubGraphQLConnector48.png"),
        Extension.Contents("DataHubGraphQLConnector64.png")
    }
];

// Retrieves the tenant ID from the access token, which is in Json Web Token (JWT) format.
// JWTs have three segments separated by periods ("."): a header, a payload, and a signature.
// Claims are found in the payload segment, which is a JSON object that has been Base64 encoded.
// The access token we recieve will have a "tid" claim which contains the tenant ID.
GetTenantId = () as text =>
    let
        // Adds padding to a possibly invalid base64 string to create a valid base64 string.
        AddBase64Padding = (base64Input as text) as text =>
            let
                base64LengthDivisor = 4,
                base64PaddingCharacter = "=",
                inputLength = Text.Length(base64Input),
                charactersThatRequirePadding = Number.Mod(inputLength, base64LengthDivisor),
                result =
                    if charactersThatRequirePadding = 0 then
                        base64Input
                    else
                        Text.PadEnd(
                            base64Input,
                            inputLength + (base64LengthDivisor - charactersThatRequirePadding),
                            base64PaddingCharacter
                        )
            in
                result,
        jwt = Extension.CurrentCredential()[access_token],
        segments = Text.Split(jwt, "."),
        encodedPayload = segments{1},
        paddedPayload = AddBase64Padding(encodedPayload),
        tenantId =
            try
                let
                    decodedPayload = Text.FromBinary(
                        Binary.FromText(paddedPayload, BinaryEncoding.Base64), TextEncoding.Utf8
                    ),
                    result = Json.Document(decodedPayload)[tid]
                in
                    result
            otherwise
                error
                    Error.Record(
                        Extension.LoadString("ErrorFailedToRetrieveTenantIdReason"),
                        Extension.LoadString("ErrorFailedToRetrieveTenantIdMessage")
                    )
    in
        tenantId;

// Helper functions for OAuth2: StartLogin, FinishLogin, Refresh, Logout
// Authorization Request, see https://www.oauth.com/oauth2-servers/pkce/authorization-request/
StartLogin = (dataSourcePath, state, display) =>
    let
        authorizeUrl = authorize_uri
            & "?"
            & Uri.BuildQueryString(
                [
                    client_id = client_id,
                    redirect_uri = redirect_uri,
                    state = state,
                    scope = scope,
                    response_type = "code",
                    code_challenge = code_challenge,
                    code_challenge_method = "S256"
                ]
            )
    in
        [
            LoginUri = authorizeUrl,
            CallbackUri = redirect_uri,
            WindowHeight = windowWidth,
            WindowWidth = windowHeight,
            Context = null
        ];

// Extracts access_token from callbackUri
FinishLogin = (context, callbackUri, state) =>
    let
        // Parse the callbackUri and extract the Query string
        parts = Uri.Parts(callbackUri)[Query],
        // If the query string contains an "error" field, raise an error
        // Otherwise call TokenMethod to exchange our code for an access_token
        result =
            if Record.HasFields(parts, {"error", "error_description"}) then
                error Error.Record(parts[error], parts[error_description], parts)
            else
                TokenMethod("authorization_code", "code", parts[code])
    in
        result;

Refresh = (dataSourcePath, refreshToken) => GetAccessToken("refresh_token", refreshToken);
Logout = (accessToken) => logout_uri;

// Retrieves an access_token used to communicate with the OCS API using either an authorization code or refresh token
GetAccessToken = (grantType, grantValue, optional codeVerifier) =>
    let
        // If the code_verifier is null, then don't include it in the query string
        // since this request is using a refresh_token which doesn't require PKCE values
        verifier = if (codeVerifier <> null) then [code_verifier = codeVerifier] else [],
        // Determines the value used to retrieve a new access token, which depends on the grant_type
        codeOrTokenField =
            if (grantType = "authorization_code") then
                [code = grantValue]
            else
                [refresh_token = grantValue],
        queryString = verifier
            & codeOrTokenField
            & [
                grant_type = grantType,
                redirect_uri = redirect_uri,
                client_id = client_id
            ],
        tokenResponse = Web.Contents(
            token_uri,
            [
                Content = Text.ToBinary(Uri.BuildQueryString(queryString)),
                Headers = [
                    #"Content-type" = "application/x-www-form-urlencoded",
                    #"Accept" = "application/json"
                ]
            ]
        ),
        body = Json.Document(tokenResponse),
        result =
            if (Record.HasFields(body, {"error", "error_description"})) then
                error Error.Record(body[error], body[error_description], body)
            else
                body
    in
        result;

// Authorization Code Exchange, see https://www.oauth.com/oauth2-servers/pkce/authorization-code-exchange/
TokenMethod = (grantType, tokenField, code) =>
    let
        queryString = [
            grant_type = "authorization_code",
            redirect_uri = redirect_uri,
            client_id = client_id,
            code_verifier = code_verifier
        ],
        queryWithCode = Record.AddField(queryString, tokenField, code),
        tokenResponse = Web.Contents(
            token_uri,
            [
                Content = Text.ToBinary(Uri.BuildQueryString(queryWithCode)),
                Headers = [
                    #"Content-type" = "application/x-www-form-urlencoded",
                    #"Accept" = "application/json"
                ],
                ManualStatusHandling = {400}
            ]
        ),
        body = Json.Document(tokenResponse),
        result =
            if (Record.HasFields(body, {"error", "error_description"})) then
                error Error.Record(body[error], body[error_description], body)
            else
                body
    in
        result;

// Retrieves the value of a parameter in the appsettings json file
TryRetrieveParameterFromAppsettings = (parameter as text) =>
    let
        result =
            try
                Record.Field(Json.Document(Extension.Contents("appsettings.json")), parameter)
            otherwise
                error
                    Error.Record(
                        Extension.LoadString("ErrorInvalidParameterReason"),
                        Extension.LoadString("ErrorInvalidParameterMessage") & parameter
                    )
    in
        result;

Extension.LoadFunction = (name as text) =>
    let
        binary = Extension.Contents(name), asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);

// Import functions from other files
GraphQL = Extension.LoadFunction("GraphQL.pqm");
