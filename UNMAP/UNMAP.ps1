<#
.SYNOPSIS
  Run UNMAP (Space reclamation) on all datastores of a specified host.

.DESCRIPTION
  Run UNMAP (Space reclamation) on all datastores of a specified host.
  Tested with HP 3PAR Array.
  If you want to use automated task, don't forget to use:
  New-VICredentialStoreItem -Host $esxi -User root -Password "Super$ecretPassword"
  Based on the work of Luca Sturlese for logs files

.INPUTS
  None

.OUTPUTS
  Log file stored by default in the same repository.

.NOTES
  Version:        3.0
  Author:         Erwan Quélin
  Creation Date:  16/02/2015
  Purpose/Change: Initial script development

.EXAMPLE
  None
#>

### Variables ###########################################################################

# Debug mode
$DebugPreference = 'SilentlyContinue' #Might be Continue, SilentlyContinue

#Script Version
$sScriptVersion = '3.0'

#Log File Info
$sLogPath = '.'
$sLogName = 'UNMAP.log'

$esxi = 'esx1.domain.local' #ESXi which will be used to run the UNMAP VAAI
$vendor = '3PARdata' #might be 3PARdata, DGC (for VNX)

$EmailFrom = 'from@domain.local'
$EmailTo = 'to@domain.local'
$EmailSubject = 'UNMAP Script Report'
$sSmtpServer = 'smtp.domain.local'


### Functions ###########################################################################
### DO NOT EDIT BEYOND THIS LINE !!! ####################################################

function HostConnexion {
  If (($creds = Get-VICredentialStoreItem -Host $esxi -ErrorAction SilentlyContinue) -ne $null) {
    $connexion = Connect-VIServer $esxi -User $creds.User -Password $creds.Password
    Log-Write -LogPath $sLogFile -LineValue "Connexion to $($connexion.Name) with username $($connexion.User)"
  } else {
    Log-Write -LogPath $sLogFile -LineValue "Credentials not found, use New-VICredentialStoreItem command"
    Log-Finish -LogPath $sLogFile
    break
  }
}

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

Function Log-Start{
  [CmdletBinding()]

  Param ([Parameter(Mandatory=$true)][string]$LogPath, [Parameter(Mandatory=$true)][string]$LogName, [Parameter(Mandatory=$true)][string]$ScriptVersion)

  Process{
    $sFullPath = $LogPath + "\" + $LogName

    #Check if file exists and delete if it does
    If((Test-Path -Path $sFullPath)){
      Remove-Item -Path $sFullPath -Force
    }

    #Create file and start logging
    New-Item -Path $LogPath -Value $LogName -ItemType File -ErrorAction SilentlyContinue

    Add-Content -Path $sFullPath -Value "***************************************************************************************************"
    Add-Content -Path $sFullPath -Value "Started processing at [$([DateTime]::Now)]."
    Add-Content -Path $sFullPath -Value "***************************************************************************************************"
    Add-Content -Path $sFullPath -Value ""
    Add-Content -Path $sFullPath -Value "Running script version [$ScriptVersion]."
    Add-Content -Path $sFullPath -Value ""
    Add-Content -Path $sFullPath -Value "***************************************************************************************************"
    Add-Content -Path $sFullPath -Value ""

    #Write to screen for debug mode
    Write-Debug "***************************************************************************************************"
    Write-Debug "Started processing at [$([DateTime]::Now)]."
    Write-Debug "***************************************************************************************************"
    Write-Debug ""
    Write-Debug "Running script version [$ScriptVersion]."
    Write-Debug ""
    Write-Debug "***************************************************************************************************"
    Write-Debug ""
  }
}


Function Log-Write{
  [CmdletBinding()]
  Param ([Parameter(Mandatory=$true)][string]$LogPath, [Parameter(Mandatory=$true)][string]$LineValue)

  Process{
    Add-Content -Path $LogPath -Value $LineValue

    #Write to screen for debug mode
    Write-Debug $LineValue
  }
}


Function Log-Error{
  [CmdletBinding()]

  Param ([Parameter(Mandatory=$true)][string]$LogPath, [Parameter(Mandatory=$true)][string]$ErrorDesc, [Parameter(Mandatory=$true)][boolean]$ExitGracefully)
  Process{

    Add-Content -Path $LogPath -Value "Error: An error has occurred [$ErrorDesc]."

    #Write to screen for debug mode
    Write-Debug "Error: An error has occurred [$ErrorDesc]."

    #If $ExitGracefully = True then run Log-Finish and exit script
    If ($ExitGracefully -eq $True){
      Log-Finish -LogPath $LogPath
      Break
    }
  }
}


Function Log-Finish{
  [CmdletBinding()]
  Param ([Parameter(Mandatory=$true)][string]$LogPath, [Parameter(Mandatory=$false)][string]$NoExit)

  Process{
    Add-Content -Path $LogPath -Value ""
    Add-Content -Path $LogPath -Value "***************************************************************************************************"
    Add-Content -Path $LogPath -Value "Finished processing at [$([DateTime]::Now)]."
    Add-Content -Path $LogPath -Value "***************************************************************************************************"

    #Write to screen for debug mode
    Write-Debug ""
    Write-Debug "***************************************************************************************************"
    Write-Debug "Finished processing at [$([DateTime]::Now)]."
    Write-Debug "***************************************************************************************************"

    #Exit calling script if NoExit has not been specified or is set to False
    If(!($NoExit) -or ($NoExit -eq $False)){
      Exit
    }
  }
}

Function Log-Email{
  [CmdletBinding()]
  Param ([Parameter(Mandatory=$true)][string]$LogPath, [Parameter(Mandatory=$true)][string]$EmailFrom, [Parameter(Mandatory=$true)][string]$EmailTo, [Parameter(Mandatory=$true)][string]$EmailSubject)
  Process{

    Try{
      $sBody = (Get-Content $LogPath | out-string)

      #Create SMTP object and send email
      $oSmtp = new-object Net.Mail.SmtpClient($sSmtpServer)
      $oSmtp.Send($EmailFrom, $EmailTo, $EmailSubject, $sBody)
      Exit 0
    }
    Catch{
      Exit 1
    }
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

#Log path creation
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

# Write log file header
Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion

# Connexion to host
HostConnexion

# Esxcli
$esxcli = get-vmhost -Name $esxi | Get-EsxCli

# Run tests on each datastore, run UNMAP if everything is OK
foreach ($datastore in Get-Datastore) {
  $timestamp = $((get-date).ToString("yyyyMMdd-HHmmss"))
  Log-Write -LogPath $sLogFile -LineValue "$timestamp - Processing Datastore $($datastore.name)"
  if ((Is3PARArray) -and (UNMAPSupport) -and (DatastoreAccessible) -and (EnoughFreeSpace)) {
    #ReclaimSpace
    Log-Write -LogPath $sLogFile -LineValue 'ReclaimSpace'
  }
}

# Deconnexion from host
Disconnect-VIServer -Confirm:$false

# Write log footer
Log-Finish -LogPath $sLogFile

# Send email
Log-Email -LogPath $sLogFile -EmailFrom $EmailFrom -EmailTo $EmailTo -EmailSubject $EmailSubject
