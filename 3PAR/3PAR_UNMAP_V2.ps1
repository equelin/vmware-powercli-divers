# Erwan Quelin

# Run UNMAP (Space reclamation) on 3PAR datastores on a specified host

$esxi = 'esx-srv20.semitan.lan' #ESXi which will be used to run the UNMAP VAAI
$vendor = '3PARdata'

##################### DO NOT EDIT BEYOND THIS LINE ###########################

### Functions

function ReclaimSpace {
  [int]$FreeSpace = $datastore.FreeSpaceMB
  $asyncUnmapFileSize = [math]::Round($FreeSpace / 10)
  Write-Host "Reclaiming free space on datastore $($datastore.name) with an asyncUnmapFile size of $asyncUnmapFileSize MB" -ForegroundColor Blue
  Try {
    $result = $esxcli.storage.vmfs.unmap($asyncUnmapFileSize, $datastore.name, $null)
  }
  Catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViError] {
    Write-Host "Error while reclaiming space on $($datastore.name) : " -ForegroundColor red -nonewline
    Write-Host $_.Exception.Message
  }
  write-host
}

function Is3PARArray {
  Write-Host "Verifying if the datastore is on a 3PAR SAN array........ " -ForegroundColor Green  -nonewline
  $lun = Get-ScsiLun -Datastore $datastore.name
  if ($lun.Vendor -eq $vendor) {
    Write-Host "[OK]" -ForegroundColor cyan
    return $true
  } else {
    Write-Host "[NOK]" -ForegroundColor red
    return $false
  }
}

function UNMAPSupport {
  Write-Host "Verifying if the datastore support VAAI UNMAP primitiv........ " -ForegroundColor Green  -nonewline
  Try {
    $vaai = $esxcli.storage.core.device.vaai.status.get($lun.CanonicalName)
  }
  Catch {
    Write-Host "Error while verifying primitiv support on $($datastore.name)" -ForegroundColor red
  }

  if ($vaai.ZeroStatus -eq 'supported') {
    Write-Host "[OK]" -ForegroundColor cyan
    return $true
  } else {
    Write-Host "[NOK]" -ForegroundColor red
    return $false
  }
}

function DatastoreAccessible {
  Write-Host "Verifying if the datastore is accessible........ " -ForegroundColor Green  -nonewline
  $datastoreView = $datastore | Get-View
  if ($datastoreView.Summary.accessible) {
    Write-Host "[OK]" -ForegroundColor cyan
    return $true
  } else {
    Write-Host "[NOK]" -ForegroundColor red
    return $false
  }
}

function EnoughFreeSpace {
  [int]$FreeSpace = $datastore.FreeSpaceMB
  Write-Host "Verifying if the datastore as enough free space " -ForegroundColor Green -nonewline
  Write-Host "(Free Space: $FreeSpace MB) " -ForegroundColor Green -nonewline
  if ($FreeSpace -ge 1024) {
    Write-Host "[OK]" -ForegroundColor cyan
    return $true
  } else {
    Write-Host "[NOK]" -ForegroundColor red
    return $false
  }
}

### Script

#Verify if VMware Automation Core Snap In is available
if ((Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null) {
  Add-PSSnapin VMware.VimAutomation.Core
}

# UNMAP operation can be long, remove timeout
$timeout = Set-PowerCLIConfiguration -WebOperationTimeoutSeconds -1 -Scope Session -Confirm:$false

# Ignore Certificates Warning while connecting to host
$certificate = Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false

#Connection to the host
Connect-VIServer -Server $esxi
write-host

$esxcli = get-vmhost -Name $esxi | Get-EsxCli

# Run tests on each datastore, run UNMAP if everithing is OK
foreach ($datastore in Get-Datastore) {
  Write-Host "Processing Datastore $($datastore.name) :" -ForegroundColor Yellow
  if ((Is3PARArray) -and (UNMAPSupport) -and (DatastoreAccessible) -and (EnoughFreeSpace)) {
    ReclaimSpace
  }
}

Disconnect-VIServer -Confirm:$false
