Connect-AzAccount -Tenant microsoft.com

Select-AzSubscription -Subscription tb-sandbox

Get-AzResource -ResourceGroupName webapp-global -ResourceType Microsoft.Web/certificates -IsCollection -ApiVersion 2018-02-01
