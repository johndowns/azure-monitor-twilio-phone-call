param(
    [Parameter(Mandatory=$true)]
    $ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    $ResourceGroupLocation,

    [Parameter(Mandatory=$true)]
    $TwilioAccountSid,

    [Parameter(Mandatory=$true)]
    $TwilioAuthToken,

    [Parameter(Mandatory=$true)]
    $TwilioFromNumber,

    [Parameter(Mandatory=$true)]
    $TwilioToNumber
)

# Cause all errors to halt the script.
$ErrorActionPreference = 'Stop'

Write-Host "Creating resource group $ResourceGroupName in location $ResourceGroupLocation."
New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Force

Write-Host 'Starting deployment of function app''s Bicep file.'
$functionAppBicepFilePath = Join-Path $PSScriptRoot 'function-app.bicep'
$deploymentOutputs = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $functionAppBicepFilePath -TwilioAccountSid $TwilioAccountSid -TwilioAuthToken (ConvertTo-SecureString -Force -AsPlainText $TwilioAuthToken) -TwilioFromNumber $TwilioFromNumber -TwilioToNumber $TwilioToNumber
$functionAppName = $deploymentOutputs.Outputs.functionAppName.value
$functionAppBaseUrl = $deploymentOutputs.Outputs.functionAppBaseUrl.value

# Sleep to allow time for the function app to be created.
Start-Sleep 20

Write-Host "Deploying to Azure Functions app $functionAppName."
$functionAppFolder = Join-Path $PSScriptRoot '..' 'src' 'ConvertAlertToPhoneCall'
Push-Location $functionAppFolder
func azure functionapp publish $functionAppName
Pop-Location
if ($LASTEXITCODE -ne 0) { throw $LASTEXITCODE }

Write-Host 'Starting deployment of action group''s Bicep file.'
$actionGroupBicepFilePath = Join-Path $PSScriptRoot 'action-group.bicep'
New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $actionGroupBicepFilePath -functionAppName $functionAppName

Write-Host 'Deployment is complete.'
