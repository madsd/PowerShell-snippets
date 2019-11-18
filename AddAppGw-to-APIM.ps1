Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName "Corp Test"

$apimRg = "core-apim"
$apimName = "contosoapimgmt"
$vNetRg = "core-netwrk-weu-rg"
$vNetName = "core-netwk-weu-vnet"
$proxyDomainName = "api.contoso.net"
$devPortalDomainName = "portal.api.contoso.net"
$certPath = "C:\Code\api.contoso.net.pfx"
$cerFilePath = "C:\Code\api.contoso.net.cer"
$devPortalCertPath = "C:\Code\portal.api.contoso.net.pfx"
$devPortalCerFilePath = "C:\Code\portal.api.contoso.net.cer"
$certPwd = "Passw0rd1"

# Get APIM Instance
$apimService = Get-AzureRmApiManagement -ResourceGroupName $apimRg -Name $apimName

# Setup Cert for APIM Proxy
$cert = New-SelfSignedCertificate -CertStoreLocation "cert:\localmachine\my" -DnsName $proxyDomainName
$pwd = ConvertTo-SecureString -String $certPwd -Force -AsPlainText
$path = 'cert:\localMachine\my\' + $cert.thumbprint 
Export-PfxCertificate -cert $path -FilePath $certPath -Password $pwd

# Setup Cert for APIM DevPortal
$dpcert = New-SelfSignedCertificate -CertStoreLocation "cert:\localmachine\my" -DnsName $devPortalDomainName
$pwd = ConvertTo-SecureString -String $certPwd -Force -AsPlainText
$dppath = 'cert:\localMachine\my\' + $dpcert.thumbprint 
Export-PfxCertificate -cert $dppath -FilePath $devPortalCertPath -Password $pwd


$certUploadResult = Import-AzureRmApiManagementHostnameCertificate -ResourceGroupName $apimRg -Name $apimName -HostnameType "Proxy" -PfxPath $certPath -PfxPassword $certPwd -PassThru

$proxyHostnameConfig = New-AzureRmApiManagementHostnameConfiguration -CertificateThumbprint $certUploadResult.Thumbprint -Hostname $proxyDomainName
$result = Set-AzureRmApiManagementHostnames -Name $apimName -ResourceGroupName $apimRg -ProxyHostnameConfiguration $proxyHostnameConfig

# Setup AppGw
$vNet = Get-AzureRmVirtualNetwork -Name $vNetName -ResourceGroupName $vNetRg

# ADJUST WITH CORRECT SUBNET NUMBER
$gatewaySubnet = $vNet.Subnets[2] 

$publicip = New-AzureRmPublicIpAddress -ResourceGroupName $apimRg -name "AppGwpublicIP01" -location "West Europe" -AllocationMethod Dynamic
$publicip = Get-AzureRmPublicIpAddress -ResourceGroupName $apimRg -Name "AppGwpublicIP01"

$gipconfig = New-AzureRmApplicationGatewayIPConfiguration -Name "AppGwIP01" -Subnet $gatewaySubnet
$fp01 = New-AzureRmApplicationGatewayFrontendPort -Name "port01"  -Port 443
$fipconfig01 = New-AzureRmApplicationGatewayFrontendIPConfig -Name "frontend1" -PublicIPAddress $publicip
$cert = New-AzureRmApplicationGatewaySslCertificate -Name "cert01" -CertificateFile $certPath -Password $certPwd
$listener = New-AzureRmApplicationGatewayHttpListener -Name "listener01" -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $cert -
$apimprobe = New-AzureRmApplicationGatewayProbeConfig -Name "apimproxyprobe" -Protocol "Https" -HostName "api.contoso.net" -Path "/status-0123456789abcdef" -Interval 30 -Timeout 120 -UnhealthyThreshold 8
$authcert = New-AzureRmApplicationGatewayAuthenticationCertificate -Name "whitelistcert1" -CertificateFile $cerFilePath
$apimPoolSetting = New-AzureRmApplicationGatewayBackendHttpSettings -Name "apimPoolSetting" -Port 443 -Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimprobe -AuthenticationCertificates $authcert -RequestTimeout 180
$apimProxyBackendPool = New-AzureRmApplicationGatewayBackendAddressPool -Name "apimbackend" -BackendIPAddresses $apimService.StaticIPs[0]

$dummyBackendSetting = New-AzureRmApplicationGatewayBackendHttpSettings -Name "dummySetting01" -Port 80 -Protocol Http -CookieBasedAffinity Disabled
$dummyBackendPool = New-AzureRmApplicationGatewayBackendAddressPool -Name "dummyBackendPool" -BackendFqdns "dummybackend.com"
$dummyPathRule = New-AzureRmApplicationGatewayPathRuleConfig -Name "nonexistentapis" -Paths "/*" -BackendAddressPool $dummyBackendPool -BackendHttpSettings $dummyBackendSetting
$echoapiRule = New-AzureRmApplicationGatewayPathRuleConfig -Name "externalapis" -Paths "/calc/*" -BackendAddressPool $apimProxyBackendPool -BackendHttpSettings $apimPoolSetting
$urlPathMap = New-AzureRmApplicationGatewayUrlPathMapConfig -Name "urlpathmap" -PathRules $echoapiRule, $dummyPathRule -DefaultBackendAddressPool $dummyBackendPool -DefaultBackendHttpSettings $dummyBackendSetting
$rule01 = New-AzureRmApplicationGatewayRequestRoutingRule -Name "rule1" -RuleType PathBasedRouting -HttpListener $listener -UrlPathMap $urlPathMap
$sku = New-AzureRmApplicationGatewaySku -Name "WAF_Medium" -Tier "WAF" -Capacity 1
$config = New-AzureRmApplicationGatewayWebApplicationFirewallConfiguration -Enabled $true -FirewallMode "Prevention"
$appgw = New-AzureRmApplicationGateway -Name "apimAppGw" -ResourceGroupName $apimRg  -Location "West Europe" -BackendAddressPools $apimProxyBackendPool, $dummyBackendPool -BackendHttpSettingsCollection $apimPoolSetting, $dummyBackendSetting  -FrontendIpConfigurations $fipconfig01 -GatewayIpConfigurations $gipconfig -FrontendPorts $fp01 -HttpListeners $listener -UrlPathMaps $urlPathMap -RequestRoutingRules $rule01 -Sku $sku -WebApplicationFirewallConfig $config -SslCertificates $cert -AuthenticationCertificates $authcert -Probes $apimprobe

# ********************************

Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName "Subscription Name..."

$apimRg = "[RG Name]"
$portalHostname = "portal.api.contoso.net"



$appgw = Get-AzureRmApplicationGateway -Name apimAppGw -ResourceGroupName $apimRg

$fp01 = Get-AzureRmApplicationGatewayFrontendPort -ApplicationGateway $appgw -Name port01

$fipconfig01 = Get-AzureRmApplicationGatewayFrontendIPConfig -ApplicationGateway $appgw -Name frontend1

$cert = Get-AzureRmApplicationGatewaySslCertificate -ApplicationGateway $appgw -Name cert01

Add-AzureRmApplicationGatewayHttpListener -ApplicationGateway $appgw -Name listener02 -Protocol Https -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $cert -HostName $portalHostname -RequireServerNameIndication true
$apimportallistener = Get-AzureRmApplicationGatewayHttpListener -ApplicationGateway $appgw -Name listener02


$apimProxyBackendPool = Get-AzureRmApplicationGatewayBackendAddressPool -ApplicationGateway $appgw -Name apimbackend

Add-AzureRmApplicationGatewayProbeConfig -ApplicationGateway $appgw -Name apimportalprobe -Protocol Https -HostName $portalHostname -Path "/signin" -Interval 60 -Timeout 300 -UnhealthyThreshold 8
$apimportalprobe = Get-AzureRmApplicationGatewayProbeConfig -ApplicationGateway $appgw -Name apimportalprobe

$authcert = Get-AzureRmApplicationGatewayAuthenticationCertificate -ApplicationGateway $appgw -Name PortalCert

Add-AzureRmApplicationGatewayBackendHttpSettings -ApplicationGateway $appgw -Name "apimPoolPortalSetting" -Port $sslPort -Protocol Https -CookieBasedAffinity Disabled -Probe $apimportalprobe -AuthenticationCertificates $authcert -RequestTimeout 180
$apimPoolPortalSetting = Get-AzureRmApplicationGatewayBackendHttpSettings -ApplicationGateway $appgw -Name "apimPoolPortalSetting"


Add-AzureRmApplicationGatewayRequestRoutingRule -Name "rule2" -RuleType Basic -HttpListener $apimportallistener -BackendAddressPool $apimProxyBackendPool -BackendHttpSettings $apimPoolPortalSetting -ApplicationGateway $appgw

Set-AzureRmApplicationGateway -ApplicationGateway $appgw