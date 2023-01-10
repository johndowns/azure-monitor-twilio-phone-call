param location string = resourceGroup().location

param functionsStorageAccountName string = 'fnstor${uniqueString(resourceGroup().id)}'

param functionAppName string = 'fn${uniqueString(resourceGroup().id)}'

param twilioAccountSid string

@secure()
param twilioAuthToken string

param twilioFromNumber string

param twilioToNumber string

var applicationInsightsName = 'ConvertAlertToPhoneCall'
var functionAppServicePlanName = 'FunctionPlan'

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource functionsStorageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: functionsStorageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource functionAppServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: functionAppServicePlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: functionAppServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsDashboard'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionsStorageAccount.name};AccountKey=${functionsStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionsStorageAccount.name};AccountKey=${functionsStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'AzureWebJobsSecretStorageType'
          value: 'Files'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionsStorageAccount.name};AccountKey=${functionsStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower('name')
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'TwilioAccountSid'
          value: twilioAccountSid
        }
        {
          name: 'TwilioAuthToken'
          value: twilioAuthToken
        }
        {
          name: 'TwilioFromNumber'
          value: twilioFromNumber
        }
        {
          name: 'TwilioToNumber'
          value: twilioToNumber
        }
      ]
      ipSecurityRestrictions: [
        {
          tag: 'ServiceTag'
          ipAddress: 'ActionGroup'
          action: 'Allow'
          priority: 100
          name: 'Allow traffic from Azure Monitor'
        }
      ]
    }
  }
}

output functionAppName string = functionApp.name
