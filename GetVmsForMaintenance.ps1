# ARM Vms
Login-AzureRmAccount

$subscriptions = Get-AzureRmSubscription

foreach ($subscription in $subscriptions)
{
    Set-AzureRmContext -SubscriptionName "Corp Test" -SubscriptionId $subscription.Id
       
    Write-Host $subscription.Name
    $vms = Get-AzureRmVM
    
    foreach ($vm in $vms)
    {
        $vmStatus = Get-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
        if ($vmStatus.MaintenanceRedeployStatus.IsCustomerInitiatedMaintenanceAllowed -eq $true)
        {
            Write-Output $vmStatus.Name
            $vmStatus.Name  | Out-File -FilePath C:\Temp\affectedvms.txt -Append:$true
        }
    }     
}

# Classic VMs
Add-AzureAccount

$classicSubscriptions = Get-AzureSubscription

foreach ($subscription in $classicSubscriptions)
{
    Write-Host $subscription.SubscriptionName
    
    Set-AzureSubscription -SubscriptionId $subscription.SubscriptionId      
    
    $classicVms = Get-AzureVM
    
    foreach ($vm in $classicVms)
    {
        $vmStatus = Get-AzureVM -ServiceName $vm.ServiceName -Name $vm.Name
        if ($vmStatus.MaintenanceStatus.IsCustomerInitiatedMaintenanceAllowed -eq $true)
        {
            Write-Output $vmStatus.Name
            $vmStatus.Name  | Out-File -FilePath C:\Temp\affectedvms.txt -Append:$true
        }
    }     
}
Install-Module Azure -Force
get-module Azure



Select-AzureSubscription -SubscriptionName "Corp Test"
$classicVmStatus = Get-AzureVM -ServiceName classicvm7617 -Name classicvm
$classicVmStatus.MaintenanceStatus


Set-AzureRmContext -subscriptionname "Arla Azure Enterprise"

Get-AzureRmVM -ResourceGroupName AZ-RG-PR-PFS-01 -Status | SELECT MaintenanceAllowed