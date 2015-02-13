# Erwan Quelin

# Run UNMAP (Space reclamation) on 3PAR datastores on a specified host

#Script Version
$sScriptVersion = "2.0"

#Log File Info
$sLogPath = "."
$sLogName = "3PAR_UNMAP.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

$esxi = 'esx-srv20.semitan.lan' #ESXi which will be used to run the UNMAP VAAI
$vendor = '3PARdata'

##################### DO NOT EDIT BEYOND THIS LINE ###########################

### Functions ###########################################################################

function ReclaimSpace {
  [int]$FreeSpace = $datastore.FreeSpaceMB
  $asyncUnmapFileSize = [math]::Round($FreeSpace / 10)
  Log-Write -LogPath $sLogFile -LineValue "Reclaiming free space on datastore $($datastore.name) with an asyncUnmapFile size of $asyncUnmapFileSize MB"
  Try {
    $result = $esxcli.storage.vmfs.unmap($asyncUnmapFileSize, $datastore.name, $null)
  }
  Catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViError] {
    Log-Write -LogPath $sLogFile -LineValue "Error while reclaiming space on $($datastore.name)"
    Log-Write -LogPath $sLogFile -LineValue $_.Exception.Message
  }
  Log-Write -LogPath $sLogFile -LineValue
}

function Is3PARArray {
  Log-Write -LogPath $sLogFile -LineValue "Verifying if the datastore is on a 3PAR SAN array"
  $lun = Get-ScsiLun -Datastore $datastore.name
  if ($lun.Vendor -eq $vendor) {
    Log-Write -LogPath $sLogFile -LineValue "[OK]"
    return $true
  } else {
    Log-Write -LogPath $sLogFile -LineValue "[NOK]"
    return $false
  }
}

function UNMAPSupport {
  Log-Write -LogPath $sLogFile -LineValue "Verifying if the datastore support VAAI UNMAP primitiv"
  Try {
    $vaai = $esxcli.storage.core.device.vaai.status.get($lun.CanonicalName)
  }
  Catch {
    Log-Write -LogPath $sLogFile -LineValue "Error while verifying primitiv support on $($datastore.name)"
  }

  if ($vaai.ZeroStatus -eq 'supported') {
    Log-Write -LogPath $sLogFile -LineValue "[OK]"
    return $true
  } else {
    Log-Write -LogPath $sLogFile -LineValue "[NOK]"
    return $false
  }
}

function DatastoreAccessible {
  Log-Write -LogPath $sLogFile -LineValue "Verifying if the datastore is accessible"
  $datastoreView = $datastore | Get-View
  if ($datastoreView.Summary.accessible) {
    Log-Write -LogPath $sLogFile -LineValue "[OK]"
    return $true
  } else {
    Log-Write -LogPath $sLogFile -LineValue "[NOK]"
    return $false
  }
}

function EnoughFreeSpace {
  [int]$FreeSpace = $datastore.FreeSpaceMB
  Log-Write -LogPath $sLogFile -LineValue "Verifying if the datastore as enough free space "
  Log-Write -LogPath $sLogFile -LineValue "Free Space: $FreeSpace MB"
  if ($FreeSpace -ge 1024) {
    Log-Write -LogPath $sLogFile -LineValue "[OK]"
    return $true
  } else {
    Log-Write -LogPath $sLogFile -LineValue "[NOK]"
    return $false
  }
}

### Script ###########################################################################

#Verify if VMware Automation Core Snap In is available
if ((Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null) {
  Add-PSSnapin VMware.VimAutomation.Core
}

# UNMAP operation can be long, remove timeout
$timeout = Set-PowerCLIConfiguration -WebOperationTimeoutSeconds -1 -Scope Session -Confirm:$false

# Ignore Certificates Warning while connecting to host
$certificate = Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false

#Dot Source required Function Libraries
. ".\logs.ps1"

#Connection to the host

Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion

$timestamp = $((get-date).ToString("yyyyMMdd-HHmmss"))

$connexion = Connect-VIServer -Server $esxi
Log-Write -LogPath $sLogFile -LineValue "Connexion to $($connexion.Name) with username $($connexion.User)"

$esxcli = get-vmhost -Name $esxi | Get-EsxCli

# Run tests on each datastore, run UNMAP if everithing is OK
foreach ($datastore in Get-Datastore) {
  Log-Write -LogPath $sLogFile -LineValue "$timestamp - Processing Datastore $($datastore.name)"
  if ((Is3PARArray) -and (UNMAPSupport) -and (DatastoreAccessible) -and (EnoughFreeSpace)) {
    #ReclaimSpace
    Log-Write -LogPath $sLogFile -LineValue ''
  }
}

Disconnect-VIServer -Confirm:$false

Log-Finish -LogPath $sLogFile
