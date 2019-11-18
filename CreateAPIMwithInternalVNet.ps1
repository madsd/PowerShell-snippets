Login-AzureRmAccount -SubscriptionName "Intern Azure Test"

$virtualNetwork = New-AzureRmApiManagementVirtualNetwork -Location "West Europe" -SubnetResourceId "/subscriptions/d0469004-9991-46ea-9790-f4236fc4d622/resourceGroups/core-netwrk-weu-rg/providers/Microsoft.Network/virtualNetworks/core-netwk-weu-vnet/subnets/test-apim-subnet"
New-AzureRmApiManagement -ResourceGroupName "test-misc-rg" -Name "madsdapivnettest" -Location "West Europe" -Organization "Turnbitz" -AdminEmail "madsd@microsoft.com" -Sku Developer -VpnType Internal -VirtualNetwork $virtualNetwork


Login-AzureRmAccount -SubscriptionName "DSB ExpressRoute"

$virtualNetwork = New-AzureRmApiManagementVirtualNetwork -Location "North Europe" -SubnetResourceId "/subscriptions/56ea457a-5fd5-4e35-92d0-828802cd0e9f/resourceGroups/DSB-ExpressRouteResourceGroup/providers/Microsoft.Network/virtualNetworks/DSB-AzureVNET/subnets/DSB-AzureSubnetEMM"
New-AzureRmApiManagement -ResourceGroupName "MobileTest" -Name "MobileApimTest" -Location "North Europe" -Organization "DSB" -AdminEmail "KEHK@dsb.dk" -Sku Developer -VpnType Internal -VirtualNetwork $virtualNetwork
