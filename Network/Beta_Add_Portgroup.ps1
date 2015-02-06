# Erwan Quelin

# Name of the vSwitch
$vSwitch = "vSwitch2"

# Name of the CSV file to import
$csv_portgroup = ".\portgroups.csv"

# Name of the CSV file to import
$csv_host = ".\hosts.csv"

##################### DO NOT EDIT BEYOND THIS LINE ###########################

# Prompt for root password
$password = read-host "Enter root password"

# Import CSV
$networks = Import-Csv -Path $csv_portgroup -Delimiter ","
$srvs = Import-Csv -Path $csv_host -Delimiter ","


foreach ($srv in $srvs) {
  $name_host = $srv.name

  Write-Host "Connection to $name_host" -ForegroundColor Green
  Connect-VIServer -Server $name_host -User root -Password $password

  foreach ($network in $networks) {
    $name = $network.name
    $vlan = $network.vlan

    write-host "Verification if portgroup $name already exist"

    #Test if portgroup exist, create it if needed
    If ((Get-VMHost | Get-VirtualPortGroup -Name $name -ErrorAction SilentlyContinue)-eq $null){
      write-host "Portgroup $name does not exist, creation..." -ForegroundColor yellow
      Get-VMHost | Get-VirtualSwitch -Name $vSwitch | New-VirtualPortGroup -Name $name -VLanId $vlan
    } else {
      write-host "Portgroup $name already created, verifying VLAN ID" -ForegroundColor Green

      #Test VLAN Id, modify if mismatch
      If ((Get-VMHost | Get-VirtualPortGroup -Name $name -ErrorAction SilentlyContinue | ? {$_.Vlanid -eq $vlan})-eq $null){
        write-host "VLAN ID mismatch, changing it..." -ForegroundColor yellow
        Get-VMHost | Get-VirtualPortGroup -Name $name | Set-VirtualPortGroup -VLanId $vlan
      } else {
        write-host "Portgroup $name already created with the correct VLAN ID $vlan" -ForegroundColor Green
      }
    }

    write-host
  }
  Write-Host "Disconnection of $name_host" -ForegroundColor Green
  Disconnect-VIServer -Confirm:$false

  Write-Host
}
