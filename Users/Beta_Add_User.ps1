# Erwan Quelin

$accountName = "user"
$accountPswd = "password"
$accountDescription = "Description of the User"
$role = "ReadOnly" #might be: Admin, ReadOnly, View, Anonymous, NoAccess

# Name of the CSV file to import
$csv_host = ".\hosts.csv"

##################### DO NOT EDIT BEYOND THIS LINE ###########################

# Prompt for root password
$password = read-host "Enter root password"

$esxlist = Import-Csv -Path $csv_host -Delimiter ","

foreach($esx in $esxlist){
    Connect-VIServer -Server $esx.name -User root -Password $password
    $rootFolder = Get-Folder -Name ha-folder-root
    Try{
        Get-VMHostAccount -Id $accountName -ErrorAction Stop |
        Set-VMHostAccount -Password $accountPswd -Description $accountDescription
    }
    Catch{
        $account = New-VMHostAccount -Id $accountName -Password $accountPswd -Description $accountDescription -UserAccount -GrantShellAccess
        New-VIPermission -Entity $rootFolder -Principal $account -Role $role
    }
    Disconnect-VIServer -Confirm:$false
}
