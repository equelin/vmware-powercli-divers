# Erwan Quelin

# Configure queue for each host added to a vCenter
#'Disk.QFullSampleSize'
#'Disk.QFullThreshold'

$QFullSampleSize = 32
$QFullThreshold = 4

##################### DO NOT EDIT BEYOND THIS LINE ###########################


# Prompt for vCenter IP or FQDN
$vcenter = read-host "Enter vCenter/host IP or FQDN"

Write-Host "Connection to the vCenter/host $vcenter" -ForegroundColor Green
Connect-VIServer -Server $vcenter

$esxHosts = get-VMHost

foreach ($esx in $esxHosts) {

  Write-Host "Configuring $($esx.name)" -ForegroundColor Green
  $esx | Set-VMHostAdvancedConfiguration -NameValue @{'Disk.QFullSampleSize'= $QFullSampleSize;'Disk.QFullThreshold'= $QFullThreshold}

  write-host
}

Write-Host "Disconnection of $vcenter" -ForegroundColor Green
Disconnect-VIServer -Confirm:$false
