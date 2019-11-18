#**************************************************
# Script to integrate API Management in Internal VNET with Application Gateway.
#
# The basic premise is that 
#   - Create 2 Backend Https Setting
#   - Create 2 Custom Probes 
#	- One Backend Pool 
#	- 2 Listeners - gateway.contoso.com & portal.contoso.com
#	- 2 Rules
#   - 1 FrontendIP Configuration (VIP)
#
# The script is created using https://github.com/Azure/azure-powershell/releases/download/v3.7.0-March2017/azure-powershell.3.7.0.msi 
#***************************************************

#<!-- Uncomment the below line to get detailed Logs -->
#$DebugPreference="Continue"

#Credentials
$subscriptionId = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# API Management Configuration
$organizationName = "Microsoft"
$resourceGroupName = "API-Management-in-VNET-with-Gateway-Test"
$apimGatewayHostName = "SamirAppGwApimTest.azure-api.net"
$apimPortalHostname = "SamirAppGwApimTest.portal.azure-api.net"
$apiManagementServiceName = "SamirAppGwApimTest"
$location = "South Central US"
$apiManagementAdminEmail = "sasolank@microsoft.com" 


# External Configuration (Custom API Domain)
$apiHostname = "apigwproxy.current.int-azure-api.net"
$portalHostname = "portalgw.current.int-azure-api.net"
$sslPort = 443


#Certificate <!-- This Certificate is *.current.int-azure-api.net -->
$pfxCertificatePassword = "xxxxxxxxxxxx"
$pfxCertificateFilename = $PSScriptRoot + "\PfxCert.pfx"
$cerCertificateFilename = $PSScriptRoot + "\CerCert.cer" 

#Network
$virtualNetworkAddressPrefix = "192.168.0.0/16"
$gatewaySubnetAddressPrefix = "192.168.0.0/24"
$apiManagementSubnetAddressPrefix = "192.168.8.0/24"

#Output colors
$foregroundColor = "green"
$backgroundColor = "black"

#Log 
$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
$date = (get-date).tostring("MM-dd-yyyy-HH-mm-ss")
$logFile = $PSScriptRoot + "\CreateApiManagementEnvLog-" + $date + ".txt"
Start-Transcript -path $logFile
$startTime = Get-Date
Write-Host("Start Time: " + $startTime) 
$colors = "-foregroundcolor $foregroundColor -backgroundcolor $backgroundcolor"

#Step 01
Login-AzureRmAccount
Write-Host("Step 01 [Login-AzureRmAccount] completed") $colors

#Step 02
Get-AzureRmSubscription -Subscriptionid $subscriptionId | Select-AzureRmSubscription
Write-Host("Step 02 [Get-AzureRmSubscription] completed") $colors

#Step 03
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
Write-Host("Step 03 [New-AzureRmResourceGroup] completed") $colors

#Step 04
$appgatewaysubnet = New-AzureRmVirtualNetworkSubnetConfig -Name apim01 -AddressPrefix $gatewaySubnetAddressPrefix
Write-Host("Step 04 [New-AzureRmVirtualNetworkSubnetConfig] completed") $colors

#Step 05
$apimsubnet = New-AzureRmVirtualNetworkSubnetConfig -Name apim02 -AddressPrefix $apiManagementSubnetAddressPrefix
Write-Host("Step 05 [New-AzureRmVirtualNetworkSubnetConfig] completed") $colors

#Step 06
$vnet = New-AzureRmVirtualNetwork -Name appgwvnet -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $virtualNetworkAddressPrefix -Subnet $appgatewaysubnet,$apimsubnet
Write-Host("Step 06 [New-AzureRmVirtualNetwork] completed") $colors

#Step 07
$appgatewaysubnetdata=$vnet.Subnets[0]
Write-Host("Step 07 [$appgatewaysubnetdata] completed") $colors

#Step 08
$apimsubnetdata=$vnet.Subnets[1]
Write-Host("Step 08 [$apimsubnetdata] completed") $colors

#Step 10
$apimVirtualNetwork = New-AzureRmApiManagementVirtualNetwork -Location $location -SubnetResourceId $apimsubnetdata.Id
Write-Host("Step 09 [New-AzureRmApiManagementVirtualNetwork] completed") $colors

#Step 11
$apimService = New-AzureRmApiManagement -ResourceGroupName "$resourceGroupName" -Location $location -Name $apiManagementServiceName -Organization $organizationName -AdminEmail $apiManagementAdminEmail -VirtualNetwork $apimVirtualNetwork -VpnType "Internal" -Sku "Developer"
Write-Host("Step 10 [New-AzureRmApiManagement] completed") $colors

#Step 12
$certUploadResult = Import-AzureRmApiManagementHostnameCertificate -ResourceGroupName "$resourceGroupName" -Name $apiManagementServiceName -HostnameType "Proxy" -PfxPath $pfxCertificateFilename -PfxPassword $pfxCertificatePassword -PassThru
Write-Host("Step 11 [Import-AzureRmApiManagementHostnameCertificate] completed") $colors

#Step 13
$proxyHostnameConfig = New-AzureRmApiManagementHostnameConfiguration -CertificateThumbprint $certUploadResult.Thumbprint -Hostname $apiHostname
Write-Host("Step 12 [New-AzureRmApiManagementHostnameConfiguration] completed") $colors

$portalHostnameConfig = New-AzureRmApiManagementHostnameConfiguration -CertificateThumbprint $certUploadResult.Thumbprint -Hostname $portalHostname
Write-Host("Step 12 [New-AzureRmApiManagementHostnameConfiguration] completed") $colors

#Step 14
$result = Set-AzureRmApiManagementHostnames -Name $apiManagementServiceName -ResourceGroupName "$resourceGroupName" –PortalHostnameConfiguration $portalHostnameConfig -ProxyHostnameConfiguration $proxyHostnameConfig
Write-Host("Step 13 [Set-AzureRmApiManagementHostnames] completed") $colors

#Step 15
$publicip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -name publicIP01 -location $location -AllocationMethod Dynamic
Write-Host("Step 14 [New-AzureRmPublicIpAddress] completed") $colors

#Step 16
$gipconfig = New-AzureRmApplicationGatewayIPConfiguration -Name gatewayIP01 -Subnet $appgatewaysubnetdata
Write-Host("Step 15 [New-AzureRmApplicationGatewayIPConfiguration] completed") $colors

#Step 17
$fp01 = New-AzureRmApplicationGatewayFrontendPort -Name 'port01' -Port $sslPort
Write-Host("Step 16 [New-AzureRmApplicationGatewayFrontendPort] completed") $colors


#Step 18
$fipconfig01 = New-AzureRmApplicationGatewayFrontendIPConfig -Name "frontend1" -PublicIPAddress $publicip
Write-Host("Step 17 [New-AzureRmApplicationGatewayFrontendIPConfig] completed") $colors

#Step 19
# Note: Here I am using Certificate for * domain. You can can have an SSL Certificate for a particular domain
# Then you need to duplicate Step 19 and be careful to provide the relevant Certificate in Step 20 and Step 23
$cert = New-AzureRmApplicationGatewaySslCertificate -Name cert01 -CertificateFile $pfxCertificateFilename -Password $pfxCertificatePassword
Write-Host("Step 18 [New-AzureRmApplicationGatewaySslCertificate] completed") $colors

#Step 20
$apimlistener = New-AzureRmApplicationGatewayHttpListener -Name listener01 -Protocol Https -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $cert -HostName $apiHostname -RequireServerNameIndication true
Write-Host("Step 19 [New-AzureRmApplicationGatewayHttpListener] completed") $colors

$apimportallistener = New-AzureRmApplicationGatewayHttpListener -Name listener02 -Protocol Https -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $cert -HostName $portalHostname -RequireServerNameIndication true
Write-Host("Step 19 [New-AzureRmApplicationGatewayHttpListener] completed") $colors

#Step 21
$apimprobe = New-AzureRmApplicationGatewayProbeConfig -Name apimproxyprobe -Protocol Https -HostName $apimGatewayHostName -Path "/status-0123456789abcdef" -Interval 30 -Timeout 120 -UnhealthyThreshold 8
Write-Host("Step 20 [New-AzureRmApplicationGatewayProbeConfig] completed") $colors

$apimportalprobe = New-AzureRmApplicationGatewayProbeConfig -Name apimportalprobe -Protocol Https -HostName $apimPortalHostname -Path "/signin" -Interval 60 -Timeout 300 -UnhealthyThreshold 8
Write-Host("Step 20 [New-AzureRmApplicationGatewayProbeConfig] completed") $colors

#Step 22
$authcert = New-AzureRmApplicationGatewayAuthenticationCertificate -Name 'whitelistcert1' -CertificateFile $cerCertificateFilename
Write-Host("Step 21 [New-AzureRmApplicationGatewayAuthenticationCertificate] completed") $colors

#Step 23
$apimPoolSetting = New-AzureRmApplicationGatewayBackendHttpSettings -Name "apimPoolSetting" -Port $sslPort -Protocol Https -CookieBasedAffinity Disabled -Probe $apimprobe -AuthenticationCertificates $authcert -RequestTimeout 180
Write-Host("Step 22 [New-AzureRmApplicationGatewayBackendHttpSettings] completed") $colors

$apimPoolPortalSetting = New-AzureRmApplicationGatewayBackendHttpSettings -Name "apimPoolPortalSetting" -Port $sslPort -Protocol Https -CookieBasedAffinity Disabled -Probe $apimportalprobe -AuthenticationCertificates $authcert -RequestTimeout 180
Write-Host("Step 22 [New-AzureRmApplicationGatewayBackendHttpSettings] completed") $colors

#Step 24
$apimProxyBackendPool = New-AzureRmApplicationGatewayBackendAddressPool -Name apimbackend -BackendIPAddresses $apimService.StaticIPs[0]
Write-Host("Step 23 [New-AzureRmApplicationGatewayBackendAddressPool] completed") $colors


#Step 25
$rule01 = New-AzureRmApplicationGatewayRequestRoutingRule -Name "rule1" -RuleType Basic -HttpListener $apimlistener -BackendAddressPool $apimProxyBackendPool -BackendHttpSettings $apimPoolSetting
Write-Host("Step 26 [New-AzureRmApplicationGatewayRequestRoutingRule] completed") $colors

$rule02 = New-AzureRmApplicationGatewayRequestRoutingRule -Name "rule2" -RuleType Basic -HttpListener $apimportallistener -BackendAddressPool $apimProxyBackendPool -BackendHttpSettings $apimPoolPortalSetting
Write-Host("Step 26 [New-AzureRmApplicationGatewayRequestRoutingRule] completed") $colors

#Step 26
$sku = New-AzureRmApplicationGatewaySku -Name WAF_Medium -Tier WAF -Capacity 2
Write-Host("Step 27 [New-AzureRmApplicationGatewaySku] completed") $colors

#Step 27
$appgw = New-AzureRmApplicationGateway -Name appgwtest -ResourceGroupName $resourceGroupName -Location $location -BackendAddressPools $apimProxyBackendPool -BackendHttpSettingsCollection $apimPoolSetting, $apimPoolPortalSetting -FrontendIpConfigurations $fipconfig01 -GatewayIpConfigurations $gipconfig -FrontendPorts $fp01 -HttpListeners $apimlistener, $apimportallistener -RequestRoutingRules $rule01, $rule02 -Sku $sku -SslCertificates $cert -AuthenticationCertificates $authcert -Probes $apimprobe, $apimportalprobe
Write-Host("Step 29 [New-AzureRmApplicationGateway] completed") $colors

#Step 28
Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Name publicIP01
Write-Host("Step 30 [Get-AzureRmPublicIpAddress] completed") $colors

#Step 29
Write-Host("Step 31 You need to create CNAME record for custom api domain($apiHostname & $portalHostName) to the Frontend Public IP of Application Gateway, which will be something like ***********.cloudapp.net ") $colors

#Done
Write-Host("Done") $colors
$endTime = Get-Date
$elapsedTime = New-Timespan –Start $startTime –End $endTime

Write-Host("End Time: " + $endTime) $colors
Write-Host("Elapsed Time: " + $elapsedTime) $colors
Write-Host "Press any key to continue ..." $colors

Stop-Transcript

$gw = Get-AzureRmApplicationGateway -Name apimAppGw -ResourceGroupName core-apim

Install-Module AzureRm