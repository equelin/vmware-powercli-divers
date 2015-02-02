# Erwan Quelin

# Discover FCOE device on vmnic

# Names of the vmnic
$vmnic = @("vmnic2","vmnic3")

##################### DO NOT EDIT BEYOND THIS LINE ###########################

# Prompt for vCenter IP or FQDN
$srv = read-host "Enter vCenter/host IP or FQDN"

Write-Host "Connection to the vCenter/host $srv" -ForegroundColor Green
Connect-VIServer -Server $srv

$esxHosts = get-VMHost

foreach ($esx in $esxHosts) {
  $esxcli = get-vmhost $esx | Get-EsxCli
  foreach ($nic in $vmnic) {
      Write-Host "$esx - Discovering FCOE device on $nic" -ForegroundColor Green
      $esxcli.fcoe.nic.discover($nic)
  }
}
Write-Host "Done!" -ForegroundColor Green

Write-Host "Disconnection of $srv" -ForegroundColor Green
Disconnect-VIServer -Confirm:$false
