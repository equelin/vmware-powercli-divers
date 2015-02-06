# Erwan Quelin

# Start SSH service on all hosts




##################### DO NOT EDIT BEYOND THIS LINE ###########################

# Prompt for vCenter IP or FQDN
$srv = read-host "Enter vCenter/host IP or FQDN"

Write-Host "Connection to the vCenter/host $srv" -ForegroundColor Green
Connect-VIServer -Server $srv

$esxlist = get-VMHost

foreach ($esx in $esxlist) {

  Write-Host "Stop SSH service on $esx" -ForegroundColor Green
  Get-VMHostService -VMHost $esx | where{$_.Key -eq "TSM-SSH"} | Stop-VMHostService -Confirm:$false

}
Write-Host "Done!" -ForegroundColor Green

Disconnect-VIServer -Confirm:$false
