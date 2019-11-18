Resolve-DnsName www.microsoft.com

Login-AzureRmAccount -SubscriptionName "Intern Azure Prod"

Set-AzureRmContext -SubscriptionName "Intern Azure Test"

Get-AzureRmOperationalInsightsWorkspace -ResourceGroupName mms-weu

gcm -Noun *OperationalInsight*

$workspaceResourceId = "/subscriptions/0a56b3b5-ba17-4825-9876-3706ec8fdab7/resourcegroups/mms-weu/providers/microsoft.operationalinsights/workspaces/madsd"

foreach ($nsg in Get-AzureRmNetworkSecurityGroup)
{
    Write-Host $nsg.Id
    #Get-AzureRmDiagnosticSetting -ResourceId $nsg.Id
    Set-AzureRmDiagnosticSetting -ResourceId $nsg.Id -WorkspaceId $workspaceResourceId -Enabled $true
}

Get-AzureRmDiagnosticSetting -ResourceId

Set-AzureRmDiagnosticSetting -ResourceId $nsg.ResourceId  -WorkspaceId $workspaceId -Enabled $true