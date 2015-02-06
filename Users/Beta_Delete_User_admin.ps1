# Erwan Quelin


# Name of the CSV file to import
$csv_host = ".\hosts.csv"

##################### DO NOT EDIT BEYOND THIS LINE ###########################

# Prompt for root password
$user = read-host "Enter admin username"

# Prompt for root password
$password = read-host "Enter admin password"

# Prompt for root password
$accountName = read-host "Enter username to delete on hosts"

$esxlist = Import-Csv -Path $csv_host -Delimiter ","

foreach($esx in $esxlist){
    Connect-VIServer -Server $esx.name -User $user -Password $password
    $rootFolder = Get-Folder -Name ha-folder-root
    If (Get-VMHostAccount -Id $accountName -ErrorAction SilentlyContinue) {
      Write-Host "Deleting user account $accountName" -ForegroundColor Green
      Remove-VMHostAccount -HostAccount $accountName
    } else {
      Write-Host "User $accountName does not exist on host..." -ForegroundColor Yellow
    }

    Disconnect-VIServer -Confirm:$false
}
