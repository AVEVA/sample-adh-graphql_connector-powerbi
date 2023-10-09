// Use this file to write queries to test your data connector
let
    namespace_id = "PLACEHOLDER_TEST_ONLY", 
    result = DataHubGraphQLConnector.Contents(namespace_id)
in
    result
