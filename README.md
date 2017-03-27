KACE-Alert
=============

This is a powershell interface and control mechanism for the KACE Windows User Alert (KUserAlert.exe) included with the KACE K1000 Agent software.

## Requirements
* Windows OS Only
* KACE K1000 Agent installed on local system
* Powershell v2+

## Functionality
* Launch, Monitor, Update, and Close KACE Alerts
* 


## Instructions
#### To use as a script (as-is):
```powershell
  # Running the 
  PS C:\> C:\Path\to\script\KACE-Alert.ps1 -Name "SoftwareUpdate" -Title "Software Update" -Message "Please click ok to proceed"
  
```

#### To use this in a powershell script, embed the script in a function by putting the contents between these two lines:
```powershell
  function KACE-Alert {
    #Script Contents
  }
```
### Any calls to the function would then be formatted as follows:
```powershell
  KACE-Alert -Name "SoftwareUpdate" -Title "Software Update" -Message "Please click ok to proceed"
```


## Examples

#### Create a new alert
```powershell
#Create a new message window with the Title "Software Update" and message "Please click ok to proceed" and OK, Snooze, and Cancel buttons. This includes custom options as follows: 5 minute timeout, snooze on timeout, limit of 5 snoozes.

	PS C:\> KACE-Alert.ps1 -Name "SoftwareUpdate" -Title "Software Update" -Message "Please click ok to proceed" -Ok -Snooze -Cancel -Timeout 300 -TimoutAction "Snooze" -SnoozeLimit 5

  OK
```

#### Create an alert without any buttons
```powershell
	#Create a new message window with the message "Please wait. Software is being installed." without any buttons. This command returns the PID of the launched alert window.

	PS C:\> KACE-Alert.ps1 -Name "SoftwareInstall" -Message "Please wait. Software is being installed." -NoButtons

  7096
```

#### Update and append text to an alert
```powershell
	#Update and append a message window. The message window must be identified by "name" used when the alert was launched.

	PS C:\> KACE-Alert.ps1 -Name "SoftwareInstall" -Message "Thank you for your patience. Software is still being installed" -Update -Append

  UPDATE
  ```
  
#### Launch an alert and return exit code only
```powershell
	#Create an alert window in standalone mode. This will return only INT exit codes, rather than string return values. Possible exit codes are 0, 1, and 99.

	PS C:\> KACE-Alert.ps1 -Name "SoftwareUpdate" -Message "Please click ok to proceed" -Ok -Snooze -Cancel -TimoutAction "Snooze" -SnoozeLimit 5 -SnoozeLimitAction "OK" -Silent

  0
```
