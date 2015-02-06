# Erwan Quelin

# Configure syslog for each host added to a vCenter
#'Config.HostAgent.log.level'='info'
#'Vpx.Vpxa.config.log.level'='info';
#'Syslog.global.logHost'='tcp://192.168.0.1:514'

$SyslogServer = 'tcp://192.168.0.1:514'

##################### DO NOT EDIT BEYOND THIS LINE ###########################


# Prompt for vCenter IP or FQDN
$vcenter = read-host "Enter vCenter/host IP or FQDN"

Write-Host "Connection to the vCenter $vcenter" -ForegroundColor Green
Connect-VIServer -Server $vcenter

$VMlist = get-VM

foreach ($VM in $VMlist) {
  $name = $VM.name

  Write-Host "Verifying $name" -ForegroundColor Green
  $esx | Set-VMHostAdvancedConfiguration -NameValue @{'Config.HostAgent.log.level'='info';'Vpx.Vpxa.config.log.level'='info';'Syslog.global.logHost'= $SyslogServer}

  Write-Host "*** Configuring firewall exception on $name" -ForegroundColor Green
  Get-VMHostFirewallException -VMhost $name -name syslog | Set-VMHostFirewallException -Enabled $true

  write-host
}

Write-Host "Disconnection of $vcenter" -ForegroundColor Green
Disconnect-VIServer -Confirm:$false
