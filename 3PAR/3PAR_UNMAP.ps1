# Erwan Quelin

# Run UNMAP (Space reclamation) on 3PAR datastores on a specified host

$vendor = '3PARdata'

##################### DO NOT EDIT BEYOND THIS LINE ###########################


# UNMAP operation can be long, remove timeout
$timeout = Set-PowerCLIConfiguration -WebOperationTimeoutSeconds -1 -Scope Session -Confirm:$false

# Ignore Certificates Warning while connecting to host
$certificate = Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false

# Prompt for ESXi IP or FQDN
$esxi = read-host "Enter host IP or FQDN"

#Connection to the host
Connect-VIServer -Server $esxi

write-host

$esxcli = get-vmhost -Name $esxi | Get-EsxCli

foreach ($datastore in Get-Datastore) {

  Write-Host "Processing Datastore $($datastore.name) :" -ForegroundColor Green
  Write-Host "Verifying if the datastore is on a 3PAR SAN array........ " -ForegroundColor Green  -nonewline

  $lun = Get-ScsiLun -Datastore $datastore.name

  if ($lun.Vendor -eq $vendor) {
    Write-Host "[OK]" -ForegroundColor cyan
    Write-Host "Verifying if the datastore support VAAI UNMAP primitiv........ " -ForegroundColor Green  -nonewline
    Try
    {
      $vaai = $esxcli.storage.core.device.vaai.status.get($lun.CanonicalName)
    }
    Catch
    {
      Write-Host "Error while verifying primitiv support on $($datastore.name)" -ForegroundColor red
    }

    if ($vaai.ZeroStatus -eq 'supported') {

      [int]$FreeSpace = $datastore.FreeSpaceMB

      Write-Host "[OK]" -ForegroundColor cyan
      Write-Host "Verifying if the datastore as enough free space " -ForegroundColor Green -nonewline
      Write-Host "Free Space: $FreeSpace MB " -ForegroundColor yellow -nonewline

      if ($FreeSpace -ge 1024) {

        $asyncUnmapFileSize = [math]::Round($FreeSpace / 10)

        Write-Host "[OK]" -ForegroundColor cyan
        Write-Host "Reclaiming free space on datastore $($datastore.name) with an asyncUnmapFile size of $asyncUnmapFileSize MB" -ForegroundColor Green

        Try
        {
          $result = $esxcli.storage.vmfs.unmap($asyncUnmapFileSize, $datastore.name, $null)
        }
        Catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViError]
        {
          Write-Host "Error while reclaiming space on $($datastore.name) :" -ForegroundColor red
          Write-Verbose $_.Exception.Message
        }

      } else {
        Write-Host "Datastore $($datastore.name) does not have enough free space, skip it." -ForegroundColor red
      }
    } else {
      Write-Host "[NOK]" -ForegroundColor red
    }

  } else {
    Write-Host "[NOK]" -ForegroundColor red
  }

  write-host
}

Disconnect-VIServer -Confirm:$false
