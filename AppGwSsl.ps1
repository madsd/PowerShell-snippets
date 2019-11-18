Login-AzureRmAccount -Subscription "Corp Test"

# FQDN of the web app
$webappFQDN = "<enter your webapp FQDN i.e mywebsite.azurewebsites.net>"

# Retrieve an existing application gateway
 $gw = Get-AzureRmApplicationGateway -Name webAppGw -ResourceGroupName basic-web

# Define the status codes to match for the probe
$match=New-AzureRmApplicationGatewayProbeHealthResponseMatch -StatusCode 200-399

# Add a new probe to the application gateway
Add-AzureRmApplicationGatewayProbeConfig -name AzWebAppSslProbe -ApplicationGateway $gw -Protocol Https -Path / -Interval 30 -Timeout 120 -UnhealthyThreshold 3 -PickHostNameFromBackendHttpSettings -Match $match

# Retrieve the newly added probe
 $probe = Get-AzureRmApplicationGatewayProbeConfig -name AzWebAppSslProbe -ApplicationGateway $gw 

$fp = New-AzureRmApplicationGatewayFrontendPort -Name 'SslPort'  -Port 443
$fipconfig = Get-AzureRmApplicationGatewayFrontendIPConfig -ApplicationGateway $gw -Name appGatewayFrontendIP
$password = ConvertTo-SecureString "Passw0rd1" -AsPlainText -Force
$cert = New-AzureRmApplicationGatewaySSLCertificate -Name turnbitzSslCert -CertificateFile "C:\Users\madsd\AppData\Local\lxss\root\star_turnbitz.dk.pfx" -Password $password

$listener = New-AzureRmApplicationGatewayHttpListener -Name httpsListener -Protocol Https -FrontendIPConfiguration $fipconfig -FrontendPort $fp -SSLCertificate $cert
 $listener = Get-AzureRmApplicationGatewayHttpListener -Name httpsListener -ApplicationGateway $gw
 Add-AzureRmApplicationGatewayAuthenticationCertificate -Name 'SslAuthCert' -CertificateFile "C:\Code\star_turnbitz.dk.cer" -ApplicationGateway $gw
 $authcert = Get-AzureRmApplicationGatewayAuthenticationCertificate -Name 'SslAuthCert' -ApplicationGateway $gw

# Configure an existing backend http settings 
$poolSetting = New-AzureRmApplicationGatewayBackendHttpSettings -Name appGatewayBackendHttpsSettings -PickHostNameFromBackendAddress -Port 443 -Protocol Https -CookieBasedAffinity Disabled -RequestTimeout 30 -Probe $probe -AuthenticationCertificates $authcert

 Add-AzureRmApplicationGatewayBackendHttpSettings -Name appGatewayBackendHttpsSettings -PickHostNameFromBackendAddress -Port 443 -Protocol Https -CookieBasedAffinity Disabled -RequestTimeout 30 -Probe $probe -AuthenticationCertificates $authcert -ApplicationGateway $gw
 $poolSetting = Get-AzureRmApplicationGatewayBackendHttpSettings -Name appGatewayBackendHttpsSettings -ApplicationGateway $gw
 $pool = Get-AzureRmApplicationGatewayBackendAddressPool -ApplicationGateway $gw -Name appGatewayBackendPool

$rule = New-AzureRmApplicationGatewayRequestRoutingRule -Name 'sslRule' -RuleType basic -BackendHttpSettings $poolSetting -HttpListener $listener -BackendAddressPool $pool

# Add the web app to the backend pool
Set-AzureRmApplicationGatewayBackendAddressPool -Name appGatewayBackendPool -ApplicationGateway $gw -BackendFqdns $webappFQDN

 $rule = Add-AzureRmApplicationGatewayRequestRoutingRule -ApplicationGateway $gw -Name 'sslRule' -RuleType basic -BackendHttpSettings $poolSetting -HttpListener $listener -BackendAddressPool $pool

# Update the application gateway
Set-AzureRmApplicationGateway -ApplicationGateway $gw