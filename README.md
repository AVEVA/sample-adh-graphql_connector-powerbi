# AVEVA Data Hub Sample Graph QL Power BI Connector

**Version:** 1.0.0

The Sample AVEVA Data Hub Graph QL Connector for Power BI Desktop is used to get event data from the ADH API into Power BI Desktop. The connector uses the OAuth Authorization Code with PKCE flow to connect to the API and get an access token.

## Power BI Deployment Requirement

1. [Power BI Desktop](https://powerbi.microsoft.com/en-us/desktop/)

## Build Requirements

1. [Visual Studio Code](https://code.visualstudio.com/)
1. [Power Query SDK](https://marketplace.visualstudio.com/items?itemName=PowerQuery.vscode-powerquery-sdk)
1. Register an Authorization Code Client in ADH and ensure that the registered client:
   - Contains `https://oauth.powerbi.com/views/oauthredirect.html` in the list of Allowed Redirect URLs
   - Contains `https://login.microsoftonline.com/logout.srf` in the list of Allowed Logout Redirect URLs
   - Contains `https://oauth.powerbi.com` in the list of Allowed CORS Origins
   - Use this Client ID when configuring the project in the [Building the Connector](#building-the-connector) section of this guide.

## Building the Sample Connector

1. Open the sample in Visual Studio Code
1. Rename `appsettings.placeholder.json` to `appsettings.json`
1. Update the ClientId parameter in `appsettings.json` with the client generated in the [Build Requirements](#build-requirements) section
1. Optionally update the Resource parameter in `appsettings.json` if you are using a different region or non-production enivornment
1. Build the project following [Microsoft's build and deploy documentaion](https://learn.microsoft.com/en-us/power-query/install-sdk#build-and-deploy)

## Deploying the Sample Connector

1. Open Power BI Desktop, and navigate to File > Options and Settings > Options
1. Navigate to Security, and under Data Extensions select the option "(Not Recommended) Allow any extension to load without validation or warning"
1. Click OK, acknowledge any warnings
1. In your user's `Documents` folder, create a folder `Power BI Desktop` with a subfolder `Custom Connectors`
1. Copy the `.mez` file from either `/bin/AnyCPU/Debug` or `/bin/AnyCPU/Release` (depending on settings) into the new `Custom Connectors` folder
1. Restart Power BI Desktop, and the connector should be available

Note: For more information refer to [Microsoft's distribution documentation](https://learn.microsoft.com/en-us/power-query/install-sdk#distribution-of-data-connectors)

## Using the Sample Connector

1. Generate a graph QL query within AVEVA Data Hub using the [GraphQL console](https://docs.aveva.com/bundle/aveva-data-hub/page/1263333.html) to be used later.
1. From Power BI Desktop, open Home > Get Data > More
1. The connector should be available as "Sample AVEVA™ Data Hub QraphQL Events (Beta)" in the category "Online Services"
1. Select it and click "Connect"
1. If using the connector for the first time, you may get another warning regarding untrusted connectors
1. When prompted for the Namespace Id, enter your Namespace Id
1. Click OK, and you will be prompted to login if you have not already, using an organizational account
1. Once logged in, the Power Query Editor should open and you will have the option to supply the previously generated GraphQL query
1. Click Invoke

When using the Power Query Advanced Editor, the function `DataHubGraphQLConnector.Contents` can be used where the input parameter is your Namespace Id.

## Using the Results

After you have made a query you should be left with a result that looks something like this:

![Power Query Editor Result](images/Power%20Query%20Editor%20Result.png)

To get the result in a format that is useable by Power BI you will need to expand the results. This can be done by clicking the expand icon ![Expand Icon](/images/Expand%20Icon.png) then clicking `Done` or `Expand to New Rows`. This may need to be repeated a few times to fully expand the results.

Once the data is expanded, if necessary, right click on column headers and use the "Change Type" options to assign the proper types, as all fields are treated as strings by default.

At this point, the data should be consumable in a Power BI Dashboard!

## Tests

1. Open Visual Studio Code whith the Power Query SDK installed
1. Open the sample folder
1. Set a credential. See [Microsoft's documentation](https://learn.microsoft.com/en-us/power-query/power-query-sdk-vs-code#set-credential) for more information.
1. Evaluate `DataHubGraphQLConnector.query.pq`. See [Microsoft's documentation](https://learn.microsoft.com/en-us/power-query/power-query-sdk-vs-code#evaluate-a-query-and-the-results-panel) for more information.

---

For the main ADH samples page [ReadMe](https://github.com/osisoft/OSI-Samples-OCS)  
For the main AVEVA samples page [ReadMe](https://github.com/osisoft/OSI-Samples)
