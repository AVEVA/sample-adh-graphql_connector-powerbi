// Use this file to write queries to test your data connector
let
    query = DataHubGraphQLConnector.Contents(""),
    result = query("{ assets { queryAsset { id } } }")
in
    result