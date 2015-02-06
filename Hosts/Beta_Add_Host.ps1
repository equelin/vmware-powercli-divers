# Erwan Quelin

# Name of the datacenter
$Datacenter = "DATACENTER"

# Name of the CSV file to import
$csv = ".\hosts.csv"


##################### DO NOT EDIT BEYOND THIS LINE ###########################

# Prompt for root password
$password = read-host "Enter root password"

# Import CSV
$srvs = Import-Csv -Path $csv -Delimiter ","

foreach ($srv in $srvs) {
  $name = $srv.name

  write-host "Verification if host $name is already managed by the vCenter" -ForegroundColor Green

  #Test
  If ((Get-VMHost -Name $name -ErrorAction SilentlyContinue)-eq $null){
    write-host "$name does not exist in the vCenter, add it:" -ForegroundColor Green
    Add-VMHost $name -Location (Get-Datacenter $Datacenter) -User root -Password $password -RunAsync -force:$true
  } else {
    write-host "$name does exist in the vCenter, skip it..." -ForegroundColor yellow
  }
  write-host
}
