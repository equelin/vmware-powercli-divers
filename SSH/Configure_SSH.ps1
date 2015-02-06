# Erwan Quelin

# Start SSH service and remove warning
# PowerCLI Session must be connected to vCenter Server using Connect-VIServer

# SSH service policy. Must be set to "on" or "automatic"
$policy = "on"

##################### DO NOT EDIT BEYOND THIS LINE ###########################

# Prompt for vCenter IP or FQDN
$srv = read-host "Enter vCenter/host IP or FQDN"

Write-Host "Connection to the vCenter/host $srv" -ForegroundColor Green
Connect-VIServer -Server $srv

$esxHosts = get-VMHost

foreach ($esx in $esxHosts) {

    Write-Host "Configuring SSH activation policy on $esx" -ForegroundColor Green
    Get-VMHostService -VMHost $esx | where{$_.Key -eq "TSM-SSH"} | Set-VMHostService -policy $policy -Confirm:$false

    Write-Host "Start SSH service on $esx" -ForegroundColor Green
    Get-VMHostService -VMHost $esx | where{$_.Key -eq "TSM-SSH"} | Start-VMHostService -Confirm:$false

    Write-Host "Disable SSH warning on $esx" -ForegroundColor Green
    Get-AdvancedSetting -Entity $esx -Name 'UserVars.SuppressShellWarning' | Set-AdvancedSetting -Value '1' -Confirm:$false

}
Write-Host "Done!" -ForegroundColor Green

Disconnect-VIServer -Confirm:$false
