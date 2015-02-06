# Erwan Quelin

# Configure HA cluster advanced settings :
# das.isolationaddress[x] = PingeableIP
# das.usedefaultisolationaddress = false



##################### DO NOT EDIT BEYOND THIS LINE ###########################


# Prompt for vCenter IP or FQDN
$vcenter = read-host "Enter vCenter IP or FQDN"

# Prompt for cluster name
$cluster = read-host "Enter cluster name"

Write-Host "Connection to the vCenter $vcenter" -ForegroundColor Green
Connect-VIServer -Server $vcenter

$cluster = Get-Cluster -Name $cluster

Write-Host "Adding das.isolationaddress[x] IPs" -ForegroundColor Green
New-AdvancedSetting -Entity $cluster -Type ClusterHA -Name 'das.isolationaddress1' -Value 192.168.0.1 -Confirm:$false
New-AdvancedSetting -Entity $cluster -Type ClusterHA -Name 'das.isolationaddress2' -Value 192.168.0.2 -Confirm:$false
New-AdvancedSetting -Entity $cluster -Type ClusterHA -Name 'das.isolationaddress3' -Value 192.168.0.3 -Confirm:$false
New-AdvancedSetting -Entity $cluster -Type ClusterHA -Name 'das.isolationaddress4' -Value 192.168.0.4 -Confirm:$false

Write-Host "Setting the numbers of heartbeat datastore to use" -ForegroundColor Green
New-AdvancedSetting -Entity $cluster -Type ClusterHA -Name 'das.heartbeatDsPerHost' -Value 4 -Confirm:$false

Write-Host "Desactivating das.usedefaultisolationaddress" -ForegroundColor Green
New-AdvancedSetting -Entity $cluster -Type ClusterHA -Name 'das.usedefaultisolationaddress' -Value false -Confirm:$false

Write-Host "Disabling and enabling HA" -ForegroundColor Green
Set-Cluster -Cluster $cluster -HAEnabled:$false -Confirm:$false
Set-Cluster -Cluster $cluster -HAEnabled:$true -Confirm:$false

Disconnect-VIServer -Confirm:$false
