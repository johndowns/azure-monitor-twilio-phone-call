param functionAppName string

param functionName string = 'ConvertAlertToPhoneCall'

var actionGroupName = 'ConvertAlertToPhoneCall'

resource functionApp 'Microsoft.Web/sites@2022-03-01' existing = {
  name: functionAppName
}
resource actionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    groupShortName: 'Alerts'
    enabled: true
    azureFunctionReceivers: [
      {
        name: 'ConvertAlertToPhoneCall'
        functionName: functionName
        functionAppResourceId: functionApp.id
        httpTriggerUrl: 'https://${functionApp.properties.defaultHostName}/api/${functionName}'
        useCommonAlertSchema: true
      }
    ]
  }
}
