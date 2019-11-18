Install-Module -Name ACMESharp

Initialize-ACMEVault -BaseUri https://acme-v01.api.letsencrypt.org/

New-ACMERegistration -Contacts mailto:madsd@microsoft.com
Update-ACMERegistration -AcceptTOS

# Get API Cert
New-ACMEIdentifier -Dns api.qedemo.com -Alias qedemoapi01

Complete-ACMEChallenge qedemoapi01 -ChallengeType dns-01 -Handler manual

Resolve-DnsName -Name _acme-challenge.api.qedemo.com -Type TXT

Submit-ACMEChallenge qedemoapi01 -ChallengeType dns-01

(Update-ACMEIdentifier qedemoapi -ChallengeType dns-01).Challenges | Where-Object {$_.Type -eq "dns-01"}

# Get Portal Cert
New-ACMEIdentifier -Dns portal.qedemo.com -Alias qedemoportal01

Complete-ACMEChallenge qedemoportal01 -ChallengeType dns-01 -Handler manual

Resolve-DnsName -Name _acme-challenge.portal.qedemo.com -Type TXT -DnsOnly

Submit-ACMEChallenge qedemoportal01 -ChallengeType dns-01

(Update-ACMEIdentifier qedemoportal01 -ChallengeType dns-01).Challenges | Where-Object {$_.Type -eq "dns-01"}

New-ACMECertificate qedemoportal01 -Generate -Alias qedemoportalcert

Submit-ACMECertificate qedemoportalcert

Update-ACMECertificate qedemoportalcert

Get-ACMECertificate qedemoportalcert -ExportPkcs12 C:\Temp\portal.qedemo.com.pfx