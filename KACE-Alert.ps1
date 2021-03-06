<#
.SYNOPSIS
	Launch, Control, and Track the KACE Alert dialog windows.

.DESCRIPTION
	You can use KACE-Prompt to launch, udpate, or destroy KACE Agent Alert windows.

.PARAMETER Name
	Required parameter, unique string that identifies the alert window for updates or termination. This string also appears in the header bar of the alert window.

.PARAMETER Title
	Optional title appearing above the block of text in alert windows.

.PARAMETER Message
	Main block of text to appear in alert window.

.PARAMETER Update
	Update the message text in an alert window without changing any other paraemters of the alert.

.PARAMETER Append
	Update the message text and append to existing text in an alert window without changing any other paraemters of the alert.

.PARAMETER Timeout
	Time (in seconds) to leave an alert on screen before timing out and closing. (Default is 43200, or 12 hours.)

.PARAMETER TimeoutAction
	Action to take after timeout is reached. (Default is "Cancel")

.PARAMETER yesno
	Present alert window with Yes/No buttons. (This button set cannot be combined with any other buttons)

.PARAMETER OK
	Present alert window with an OK button.

.PARAMETER Snooze
	Present alert window with a SNOOZE button.

.PARAMETER Cancel
	Present alert window with a CANCEL button.

.PARAMETER NoButtons
	Present alert window without any buttons. (Alert window will have to be manually closed or timed out with this option)

.PARAMETER SnoozeLimit
	Maximum number of times the snooze button will be shown/allowed.

.PARAMETER SnoozeLimitAction
	Action to take after Snooze Limit is reached, if user still does not select any buttons. (Default is "Cancel")

.PARAMETER SnoozeTime
	Present alert window with an OK button.

.PARAMETER Destroy
	Close the alert window matching the named alert window.

.PARAMETER Minimized
	Set the alert to launch minimized, so that users will only see the alert if they click the task bar icon.

.PARAMETER NoWait
	Override the default "Wait for completion" behavior on alerts that wait for user input.

.PARAMETER Silent
	Run script in silent mode, returning only exit codes, rather than text returns.

.EXAMPLE
	Create a new message window with the Title "Software Update" and message "Please click ok to proceed" and OK, Snooze, and Cancel buttons. This includes custom options as follows: 5 minute timeout, snooze on timeout, limit of 5 snoozes.

	PS C:\> KACE-Prompt -Name "SoftwareUpdate" -Title "Software Update" -Message "Please click ok to proceed" -Ok -Snooze -Cancel -Timeout 300 -TimoutAction "Snooze" -SnoozeLimit 5

  OK

.EXAMPLE
	Create a new message window with the message "Please wait. Software is being installed." without any buttons. This command returns the PID of the launched alert window.

	PS C:\> KACE-Prompt -Name "SoftwareInstall" -Message "Please wait. Software is being installed." -NoButtons

  7096

.EXAMPLE
	Update and append a message window.

	PS C:\> KACE-Prompt -Name "SoftwareInstall" -Message "Thank you for your patience. Software is still being installed" -Update -Append

  UPDATE

.EXAMPLE
	Create an alert window in standalone mode.

	PS C:\> KACE-Prompt -Name "SoftwareUpdate" -Message "Please click ok to proceed" -Ok -Snooze -Cancel -TimoutAction "Snooze" -SnoozeLimit 5 -SnoozeLimitAction "OK" -Silent

  0


.NOTES
	Author: Jared Villemaire
	url   : https://github.com/frenchsomething

#>

[CmdletBinding(DefaultParameterSetName="Buttons")]
Param
(
      [Parameter(Mandatory=$true)]
      [alias('ID')]
  [String]$Name,
      [Parameter(ParameterSetName='YesNo')]
      [Parameter(ParameterSetName='Buttons')]
      [Parameter(ParameterSetName='NoButtons')]
      [Parameter(ParameterSetName='Update')]
  [String]$Title,
      [Parameter(ParameterSetName='YesNo')]
      [Parameter(ParameterSetName='Buttons')]
      [Parameter(ParameterSetName='NoButtons')]
      [Parameter(ParameterSetName='Update')]
  [String]$Message=" ",
      [Parameter(ParameterSetName='Update')]
  [Switch]$Update,
      [Parameter(ParameterSetName='Update')]
  [Switch]$Append=$false,
      [Parameter(ParameterSetName='YesNo')]
      [Parameter(ParameterSetName='Buttons')]
      [Parameter(ParameterSetName='NoButtons')]
  [Int]$Timeout=43200,
      [Parameter(ParameterSetName='Buttons')]
      [Parameter(ParameterSetName='YesNo')]
      [ValidateSet('Yes','No','Ok','Snooze','Cancel')]
  [String]$TimeoutAction="Cancel",
      [Parameter(ParameterSetName='YesNo')]
  [Switch]$yesno,
      [Parameter(ParameterSetName='Buttons')]
  [Switch]$OK=$true,
      [Parameter(ParameterSetName='Buttons')]
  [Switch]$Snooze,
      [Parameter(ParameterSetName='Buttons')]
  [Switch]$Cancel,
      [Parameter(ParameterSetName='NoButtons')]
  [Switch]$NoButtons,
      [Parameter(ParameterSetName='Buttons')]
  [Int]$SnoozeLimit=3,
      [Parameter(ParameterSetName='Buttons')]
      [ValidateSet('Ok','Cancel')]
  [String]$SnoozeLimitAction="Cancel",
      [Parameter(ParameterSetName='Buttons')]
  [Int]$SnoozeTime=900,
      [Parameter(ParameterSetName='Destroy')]
  [Switch]$Destroy,
  [Parameter(ParameterSetName='YesNo')]
  [Parameter(ParameterSetName='Buttons')]
  [Switch]$NoWait,
  [Parameter(ParameterSetName='YesNo')]
  [Parameter(ParameterSetName='Buttons')]
  [Parameter(ParameterSetName='NoButtons')]
  [Switch]$Minimized,
  [Switch]$Silent
)

function ExitWithCode {
    param
    (
        $exitcode,
        $exittext
    )

    $host.SetShouldExit($exitcode)
    If($exitcode -eq 0){
        exit $exitcode
    }
    Else {
        throw $exittext
    }
}

function Get-StringHash([String] $String,$HashName = "MD5") {
  #http://jongurgul.com/blog/get-stringhash-get-filehash/
  #https://gallery.technet.microsoft.com/scriptcenter/Get-StringHash-aa843f71
  $StringBuilder = New-Object System.Text.StringBuilder
  [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{
    [Void]$StringBuilder.Append($_.ToString("x2"))
  }
  $StringBuilder.ToString()
}

###################################
###################################
# Universal variables
###################################
###################################

#
$AlertMesgDir=$env:ProgramData+"\Dell\KACE\user\"
# Alert prefix is standard, set it here for building alert indicator file paths later
$AlertIndicatorPrefix=$AlertMesgDir+"KUSERALERT_"
# The alert indicator files use a file extension that is a MD5 hash of the "Name" field.
$IndicatorExt=Get-StringHash($Name)
# Set path to KUserAlert.exe based on OS Architecture, since KACE Agent is only 32-bit, this is pretty easy.
If (Test-Path "$Env:SYSTEMDRIVE\Program Files (x86)" -PathType Container) {$AlertPath = $env:SYSTEMDRIVE+"\Program Files (x86)\Dell\KACE\KUserAlert.exe"} Else {$AlertPath = $env:SYSTEMDRIVE+"\Program Files\Dell\KACE\KUserAlert.exe"}
# Make sure the KUserAlert.exe file is present as expected.
If (-not (Test-Path $AlertPath)) {
  If ($Silent) { ExitWithCode 2 "KUSERALERT_MISSING" }
  Else { return "KUSERALERT_MISSING" }
}

# Delete any stale response messages from the KACE User directory
  (Get-ChildItem $AlertMesgDir) | ForEach-Object {
    If($_.Extension -eq ".$IndicatorExt") {
      Remove-Item $_.FullName
    }
  }

###################################
###################################

If($Minimized) {
  # Set the window styles of the respective commands to Minimized
  $PSWMI=[wmiclass]"Win32_ProcessStartup"
  $PSWMI.Properties['ShowWindow'].value=11
  #https://blogs.technet.microsoft.com/option_explicit/2012/12/04/psexec-for-powershell/
  #https://msdn.microsoft.com/en-us/library/aa394375%28v=vs.85%29.aspx?f=255&MSPPError=-2147217396
  $WindowStyle="Minimized"
}
Else{
  # Set the window styles to Normal
  $PSWMI=[wmiclass]"Win32_ProcessStartup"
  $PSWMI.Properties['ShowWindow'].value=1
  #https://blogs.technet.microsoft.com/option_explicit/2012/12/04/psexec-for-powershell/
  #https://msdn.microsoft.com/en-us/library/aa394375%28v=vs.85%29.aspx?f=255&MSPPError=-2147217396
  $WindowStyle="Normal"
}



If ( $PSCmdlet.ParameterSetName -eq 'Update' ) {
  $a=$false
  If ($Append) {
      $a=$true
  }
  $Message.Split("`n") | ForEach {
    If($a) {
      Add-Content $AlertIndicatorPrefix"APND."$IndicatorExt ""
    }
    Add-Content $AlertIndicatorPrefix"MESG."$IndicatorExt $_
    $a=$true
    While(Test-Path $AlertIndicatorPrefix"MESG."$IndicatorExt) {Start-Sleep -Milliseconds 5}
 }
  #Add-Content $AlertIndicatorPrefix"MESG."$IndicatorExt "$Message"
  #$Message | Out-File -filepath $AlertIndicatorPrefix"MESG."$IndicatorExt
  If ($Silent) { ExitWithCode 0 }
  Else { return "MESSAGEUPDATED" }
}
ElseIf ( $PSCmdlet.ParameterSetName -eq 'Destroy' ) {
  $AlertWindows=Get-WmiObject Win32_Process -Filter "name = 'KUserAlert.exe'" | Select ProcessID,CommandLine
  If($AlertWindows -ne $null) {
    $AlertWindows | ForEach-Object {
        New-Item -Path $AlertIndicatorPrefix"DESTROY."$IndicatorExt -Type file -force
        (Get-Process -Id $_.ProcessID).CloseMainWindow()
    }
    If ($Silent) { ExitWithCode 0 }
    Else { return "DESTROY" }
  }
}
ElseIf( $PSCmdlet.ParameterSetName -eq 'YesNo') {
  #YesNo buttons selected
  If($NoWait) {
    $Alert = ([wmiclass]"win32_Process").create("""$AlertPath"" -name=""$Name"" -title=""$Title"" -message=""$Message"" -timeout=$Timeout -yesno""",$null,$PSWMI)
    If ($Alert) {
      If ($Silent) { ExitWithCode 0 }
      Else { return $Alert }
    }
    Else {
      If ($Silent) { ExitWithCode 1 "FAILED" }
      Else { return "FAILED" }
    }
  }
  Else {
    $Alert = Start-Process $AlertPath -ArgumentList "-name=""$Name"" -title=""$Title"" -message=""$Message"" -timeout=$Timeout -yesno" -WindowStyle $WindowStyle -PassThru -wait

    If (Test-Path $AlertIndicatorPrefix"YES."$IndicatorExt) {
      If ($Silent) { ExitWithCode 0 }
      Else { return "YES" }
      }
    Else {
        If (($Alert.ExitTime-$Alert.StartTime).TotalSeconds -gt $Timeout) {
          If ($Silent) {
            If ($TimeoutAction -match "(YES|OK)") { ExitWithCode 0 "TIMEOUT" }
            Else { ExitWithCode 1 "TIMEOUT" }
          }
          Else { return "TIMEOUT" }
        }
        Else {
          If ($Silent) { ExitWithCode 1 "NO" }
          Else { return "NO" }
        }
    }
  }
}
ElseIf ( $PSCmdlet.ParameterSetName -eq 'NoButtons' ) {
  #No Buttons used, treid running Invoke-WMIMethod, but that cmdlet isn't supported in Powershell 2.0
  #Switched to manually launching a win32_process to launch alert so that the alert process isn't a child of the powershell process
  $PSProcess=([wmiclass]"win32_Process").create("""$AlertPath"" -name=""$Name"" -title=""$Title"" -message=""$Message"" -timeout=$Timeout -cancel",$null,$PSWMI)
  #Return PID of alert
  If ($Silent) { ExitWithCode 0 }
  Else { return $Alert }
}
Else {
  # "Standard Buttons used"
  # Build the string used to display buttons in the alert windows
  $Buttons = @()
  If($OK) { $Buttons += "-ok" }
  If($Snooze) { $Buttons += "-snooze" }
  If($Cancel) { $Buttons += "-cancel" }
  $ButtonString=$([string]::join(" ", $Buttons))
  If($NoWait) {
    $Alert = ([wmiclass]"win32_Process").create("""$AlertPath"" -name=""$Name"" -title=""$Title"" -message=""$Message"" -timeout=$Timeout $ButtonString""",$null,$PSWMI)
    If ($Alert) {
      If ($Silent) { ExitWithCode 0 }
      Else { return $Alert }
    }
    Else {
      If ($Silent) { ExitWithCode 1 "FAILED" }
      Else { return "FAILED" }
    }
  }
  Else {
  $AlertResponses="DESTROY","CANCEL","SNOOZE"
  If ($Snooze) {
    $SnoozeCount=1
    Do {
      If ($Snoozed) {
        Start-Sleep -s $SnoozeTime
        $SnoozeCount++
      }
      $Snoozed=$false
      If ($SnoozeCount -lt $SnoozeLimit) {
        $Alert = Start-Process $AlertPath -ArgumentList "-name=""$Name"" -title=""$Title"" -message=""$Message"" -timeout=$Timeout $ButtonString" -WindowStyle $WindowStyle -PassThru -wait
      }
      Else {
        $ButtonString = $ButtonString.replace("-snooze","")
        $Alert = Start-Process $AlertPath -ArgumentList "-name=""$Name"" -title=""$Title"" -message=""$Message"" -timeout=$Timeout $ButtonString" -WindowStyle $WindowStyle -PassThru -wait
      }
      $ButtonResponse=$false
      ForEach ($x in $AlertResponses) {
          If (Test-Path "$AlertIndicatorPrefix$x.$IndicatorExt") {
              $ButtonResponse=$true
              If ($x -eq "SNOOZE"){
                $Snoozed=$true
              }
              ElseIf ($x -eq "DESTROY") {
                If ($Silent) { ExitWithCode 99 $x }
                Else { return $x }
              }
              ElseIf ($x -eq "CANCEL") {
                If ($Silent) { ExitWithCode 1 $x }
                Else { return $x }
              }
              Else {
                If ($Silent) { ExitWithCode 1 $x }
                Else { return $x }
              }
          }
      }
      If (-not $ButtonResponse) {
          If (($Alert.ExitTime-$Alert.StartTime).TotalSeconds -gt $Timeout) {
            If ($TimeoutAction -eq 'Snooze') {
              $Snoozed=$true
            }
            Else{
              If ($Silent) {
                If ($TimeoutAction -eq "(OK|YES)") { ExitWithCode 0 }
                Else { ExitWithCode 1 "TIMEOUT" }
              }
              Else { return "TIMEOUT" }
            }
          }
          Else {
            If ($Silent) { ExitWithCode 0 }
            Else { return "OK" }
          }
      }
    } While (($Snoozed) -and ($SnoozeCount -lt $SnoozeLimit))
    If ($Silent) {
      If($SnoozeLimitAction -eq "OK") { ExitWithCode 0 }
      Else { ExitWithCode 1 "SNOOZELIMIT" }
    }
    Else { return "SNOOZELIMIT" }
  }
  Else {
    $Alert = Start-Process $AlertPath -ArgumentList "-name=""$Name"" -title=""$Title"" -message=""$Message"" -timeout=$Timeout $ButtonString" -WindowStyle $WindowStyle -PassThru -wait
    ForEach ($x in $AlertResponses) {
        If (Test-Path "$AlertIndicatorPrefix$x.$IndicatorExt") {
            $ButtonResponse=$true
            If ($x -eq "DESTROY") {
              If ($Silent) { ExitWithCode 99 $x }
              Else { return $x }
            }
            ElseIf ($x -eq "CANCEL") {
              If ($Silent) { ExitWithCode 1 $x }
              Else { return $x }
            }
            Else {
              If ($Silent) { ExitWithCode 1 $x }
              Else { return $x }
            }
        }
    }
    If (-not $ButtonResponse) {
        If (($Alert.ExitTime-$Alert.StartTime).TotalSeconds -gt $Timeout) {
          If ($Silent) {
            If ($TimeoutAction -eq "(OK|YES)") { ExitWithCode 0 }
            Else { ExitWithCode 1 "TIMEOUT" }
          }
          Else { return "TIMEOUT" }
        }
        Else {
          If ($Silent) { ExitWithCode 0 }
          Else { return "OK" }
        }
    }
  }
}
}
