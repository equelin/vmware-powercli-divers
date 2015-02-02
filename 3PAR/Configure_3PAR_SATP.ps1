# Erwan Quelin

# Configure ESXi with best practices for 3PAR array
# PowerCLI Session must be connected to vCenter Server using Connect-VIServer

#Variables


##################### DO NOT EDIT BEYOND THIS LINE ###########################

$esxHosts = get-VMHost

foreach ($esx in $esxHosts) {
  $esxcli = get-vmhost $esx | Get-EsxCli
  Write-Host "$esx - Configuring SATP for HP 3PAR SAN array" -ForegroundColor Green
  $esxcli.storage.nmp.satp.rule.add($null,"tpgs_on","HP 3PAR Custom iSCSI/FC/FCoE ALUA Rule",$null,$null,$null,"VV",$null,"VMW_PSP_RR","iops=1","VMW_SATP_ALUA",$null,$null,"3PARdata")
  $esxcli.storage.nmp.satp.rule.list() | where {$_.description -like "*3par*"}
}
Write-Host "Done!" -ForegroundColor Green
