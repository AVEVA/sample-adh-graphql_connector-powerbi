# AVEVA Data Hub Sample Graph QL Power BI Connector

**Version:** 1.0.0

The Sample AVEVA Data Hub Graph QL Connector for Power BI Desktop is used to get event data from the ADH API into Power BI Desktop. The connector uses the OAuth Authorization Code with PKCE flow to connect to the API and get an access token.

## Power BI Deployment Requirement

1. [Power BI Desktop](https://powerbi.microsoft.com/en-us/desktop/)

## Build Requirements

1. [Visual Studio Code](https://code.visualstudio.com/)
1. [Power Query SDK](https://marketplace.visualstudio.com/items?itemName=PowerQuery.vscode-powerquery-sdk)
1. If not using the built in Power BI Client, register an Authorization Code Client in ADH and ensure that the registered client:
   - Contains `https://oauth.powerbi.com/views/oauthredirect.html` in the list of Allowed Redirect URLs
   - Contains `https://login.microsoftonline.com/logout.srf` in the list of Allowed Logout Redirect URLs
   - Contains `https://oauth.powerbi.com` in the list of Allowed CORS Origins
   - Use this Client ID when configuring the project in the [Building the Connector](#building-the-connector) section of this guide.

## Building the Sample Connector

1. Open the sample in Visual Studio Code
1. Rename `appsettings.placeholder.json` to `appsettings.json`
1. Optionally update the ClientId parameter in `appsettings.json` with the client generated in the [Build Requirements](#build-requirements) section
1. Optionally update the Resource parameter in `appsettings.json` if you are using a different region or non-production enivornment
1. Build the project following (Microsoft's build and deploy documentaion)[https://learn.microsoft.com/en-us/power-query/install-sdk#build-and-deploy]

## Deploying the Sample Connector

1. Open Power BI Desktop, and navigate to File > Options and Settings > Options
1. Navigate to Security, and under Data Extensions select the option "(Not Recommended) Allow any extension to load without validation or warning"
1. Click OK, acknowledge any warnings
1. In your user's `Documents` folder, create a folder `Power BI Desktop` with a subfolder `Custom Connectors`
1. Copy the `.mez` file from either `/bin/AnyCPU/Debug` or `/bin/AnyCPU/Release` (depending on settings) into the new `Custom Connectors` folder
1. Restart Power BI Desktop, and the connector should be available

Note: For more information refer to (Microsoft's distribution documentation)[https://learn.microsoft.com/en-us/power-query/install-sdk#distribution-of-data-connectors]

## Using the Sample Connector

1. From Power BI Desktop, open Home > Get Data > More
1. The connector should be available as "Sample AVEVA™ Data Hub QraphQL Events (Beta)" in the category "Online Services"
1. Select it and click "Connect"
1. If using the connector for the first time, you may get another warning regarding untrusted connectors
1. When prompted for the Namespace Id, enter your Namespace Id
1. Click OK, and you will be prompted to login if you have not already, using an organizational account
1. Once logged in, the Power Query Editor should open with the results.

When using the Power Query Advanced Editor, the function `DataHubGraphQLConnector.Contents` can be used where the input parameter is your Namespace Id.

## Using the Results

The query will look something like:

```C#
let
    Source = DataHubGraphQLConnector.Contents("PLACEHOLDER_NAMESPACE_ID")
in
    Source
```

However, the results will be displayed as binary content, which is not directly consumable by Power BI. The binary first needs to be parsed. Data from AVEVA Data Hub is usually returned as JSON, but some endpoints can also return CSV format. Generally, if the parameter `form=csv` or `form=csvh` is being used, the content is returned in CSV format, otherwise the content is in JSON format. Not all endpoints support the `form` parameter.

To parse the binary content, right click on it, and select either "CSV" or "JSON".

If your content is CSV, the data should be ready to use. If the column headers are using default names like Column1, make sure you are using `form=csvh` (CSV with headers) instead of `form=csv`. Power BI should parse the headers from `csvh` format into column headers automatically.

If your content is in JSON, you will now see a list of "Record" objects that are still not easily consumable. To convert the results to a table, right click the `List` header and select `To Table`, accepting the default options.

This does little better, the data is then displayed as a list of "Record" objects under the header "Column1." However, now there is an icon with two arrows in that column header. Click that button, and then select what fields to use in the table, and expand out the data.

Once the data is expanded, if necessary, right click on column headers and use the "Change Type" options to assign the proper types, as all fields are treated as strings by default.

At this point, the data should be consumable in a Power BI Dashboard! The final query will look something like:

```C#
let
    Source = ADHConnector_Sample.Contents("https://uswe.datahub.connect.aveva.com/", "api/v1/Tenants/{tenantid}/Namespaces/"),
    Converted = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    Expanded = Table.ExpandRecordColumn(Converted, "Column1", {"Id", "Region", "Self", "Description", "State"}, {"Column1.Id", "Column1.Region", "Column1.Self", "Column1.Description", "Column1.State"})
in
    Expanded
```

## Tests

Included is an automated test that runs the Appium WebDriver to make sure that the ADH Connector sample works. To run this test, you must fill in the [AppSettings.json](ADHConnectorTest/appsettings.placeholder.json) with the ADH URL and a tenant ID that allows login via Personal Microsoft Accounts. You must also fill in the email address and password of a Microsoft Account to use for login.

This test will attempt to clear saved credentials, open the connector, and log in to AVEVA Data Hub using the provided credentials, then query the namespaces in that tenant. If this is successful, the test will pass.

Since the test uses Appium WebDriver, updates to Power BI Desktop or other differences in the UI automation fields may prevent the test from passing in environments other than the internal AVEVA test agent. To resolve issues like this, use [inspect](https://docs.microsoft.com/en-us/windows/win32/winauto/inspect-objects) to validate the names and automation IDs used by the test.

To run the test from the command line on the machine with Power BI Desktop, run:

```shell
dotnet restore
dotnet test
```

**Note:** When running an Appium WebDriver test you should not move the mouse on that computer, or have anything else that can change the mouse movement or window focus during the test. Doing so can cause the test to fail.

---

For the main ADH samples page [ReadMe](https://github.com/osisoft/OSI-Samples-OCS)  
For the main AVEVA samples page [ReadMe](https://github.com/osisoft/OSI-Samples)
