# Erwan Quelin

# Add NTP server to all the ESXi listed in a CSV file


# SSH service policy. Must be set to "on" or "automatic"
$policy = "on"

# Name of the CSV file to import
$csv = ".\hosts.csv"

##################### DO NOT EDIT BEYOND THIS LINE ###########################

# Prompt for NTP Server
$serverntp = read-host "Enter NTP Server One"

# Prompt for root password
$password = read-host "Enter root password"

# Import CSV
$srvs = Import-Csv -Path $csv -Delimiter ","

foreach ($srv in $srvs) {
  $name = $srv.name

  Write-Host "Connection to $name" -ForegroundColor Green
  Connect-VIServer -Server $name -User root -Password $password

  Write-Host "*** Configuring time on $name" -ForegroundColor Green
  Get-VMHost | %{(Get-View $_.ExtensionData.configManager.DateTimeSystem).UpdateDateTime((Get-Date -format u)) }

  Write-Host "*** Configuring NTP Servers on $name" -ForegroundColor Green
  Add-VMHostNTPServer -NtpServer $serverntp -VMHost $name -Confirm:$false

  Write-Host "*** Configuring NTP Client Policy on $name" -ForegroundColor Green
  Get-VMHostService -VMHost $name | where{$_.Key -eq "ntpd"} | Set-VMHostService -policy $policy -Confirm:$false

  Write-Host "*** Restarting NTP Client on $name" -ForegroundColor Green
  Get-VMHostService -VMHost $name | where{$_.Key -eq "ntpd"} | Restart-VMHostService -Confirm:$false

  Write-Host "Disconnection of $name" -ForegroundColor Green
  Disconnect-VIServer -Confirm:$false

  Write-Host
}
Write-Host "Done!" -ForegroundColor Green
