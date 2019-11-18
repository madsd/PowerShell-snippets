Login-AzureRmAccount -SubscriptionName "Corp Test"

Get-AzureRmAutomationVariable -ResourceGroupName test-startstop -AutomationAccountName aaa-startstop

Set-AzureRmAutomationVariable -ResourceGroupName test-startstop -AutomationAccountName aaa-startstop -Encrypted:$false `
 -Name External_Start_ResourceGroupNames -Value "test-linuxvm,test-netsec"

Set-AzureRmAutomationVariable -ResourceGroupName test-startstop -AutomationAccountName aaa-startstop -Encrypted:$false `
 -Name External_Stop_ResourceGroupNames -Value "test-linuxvm,test-netsec"

Set-AzureRmAutomationVariable -ResourceGroupName test-startstop -AutomationAccountName aaa-startstop -Encrypted:$false `
 -Name External_ExcludeVMNames -Value "centos74vm"
