Uninstall-Module AzureRM.Sql -AllVersions
Install-Module AzureAD -Force

Get-InstalledModule -Name VstsTaskSdk

$AllModules = @()

  'Creating list of dependencies...'
  $target = Get-InstalledModule 
  $target | ForEach-Object {
    $AllModules += New-Object -TypeName psobject -Property @{name=$_.Name; version=$_.Version}
  }
  $AllModules += New-Object -TypeName psobject -Property @{name=$TargetModule; version=$Version}

  foreach ($module in $AllModules) {
    Write-Host ('Uninstalling {0} version {1}' -f $module.name,$module.version)
    try {
      Uninstall-Module -Name $module.name -AllVersions -Force:$Force -ErrorAction Stop
    } catch {
      Write-Host ("`t" + $_.Exception.Message)
    }
  }
