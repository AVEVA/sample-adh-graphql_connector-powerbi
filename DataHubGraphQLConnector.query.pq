// Use this file to write queries to test your data connector
let
    query = DataHubGraphQLConnector.Contents(null),
    result = query("{ assets { queryAsset { id } } }")
in
    result