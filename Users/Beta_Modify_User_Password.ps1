# Erwan Quelin
# Modify the password of a specified user to a list of ESXi servers. List is providing in a csv file

# Name of the CSV file to import
$csv_host = ".\hosts.csv"

##################### DO NOT EDIT BEYOND THIS LINE ###########################

# Prompt for username
$user = read-host "Enter admin username"

# Prompt for user password
$password = read-host "Enter admin password"

# Prompt for username who will be modified
$accountName = read-host "Enter username to modify password"

# Prompt for new user password
$accountPassword = read-host "Enter new password for $accountName"

$esxlist = Import-Csv -Path $csv_host -Delimiter ","

foreach($esx in $esxlist){
    Connect-VIServer -Server $esx.name -User $user -Password $password
    $rootFolder = Get-Folder -Name ha-folder-root
    If (Get-VMHostAccount -Id $accountName -ErrorAction SilentlyContinue) {
      Write-Host "Modifying password for $accountName" -ForegroundColor Green
      Set-VMHostAccount -UserAccount $accountName -Password $accountPassword
    } else {
      Write-Host "User $accountName does not exist on host..." -ForegroundColor Yellow
    }

    Disconnect-VIServer -Confirm:$false
}
