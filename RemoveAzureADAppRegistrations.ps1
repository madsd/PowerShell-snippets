Install-Module -Name AzureADPreview

$tenantId = "[Tenant id]"
$creds = Get-Credential

Connect-AzureAD -TenantId $tenantId -Credential $creds
$vstsAppId = "499b84ac-1321-427f-aa17-267ca6975798"
$vstsObjectId = $null # Clear the object if the script is run multiple times
$vstsObjectId = (Get-AzureADServicePrincipal | ? AppId -eq $vstsAppId | SELECT objectId).objectId
if ($vstsObjectId -ne $null)
{
    Remove-AzureADServicePrincipal -ObjectId $vstsObjectId
    Write-Host "VSTS App Registration deleted" -ForegroundColor Yellow
}
else
{
    Write-Host "VSTS App Registration not found"
}


# Generic App
Get-AzureADServicePrincipal
Get-AzureADApplication

$genericObjectId = "[Insert Object Id]"
if ($genericObjectId -ne $null)
{
    #Remove-AzureADServicePrincipal -ObjectId $genericObjectId
    #Remove-AzureADApplication -ObjectId $genericObjectId
    Write-Host "Generic App Registration deleted" -ForegroundColor Yellow
}
else
{
    Write-Host "Generic App Registration not found"
}
