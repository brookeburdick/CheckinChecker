#!/bin/bash

#logging variables
log_location="/private/var/tmp/CheckinChecker/jamfcheck.log"
touch "/private/var/tmp/CheckinChecker/jamfcheck.log"

# Function to provide logging of the script's actions to
# the log file defined by the log_location variable
ScriptLogging(){
	
	DATE=`date +%Y-%m-%d\ %H:%M:%S`
	LOG="$log_location"
	
	echo "$DATE" " $1" >> $LOG
}

#Ask User to Contact Support via pop-up, LaunchDaemon will run this at intervals
ScriptLogging "Prompting User to Contact support to re-enroll machine."
osascript <<EOD
	display dialog "Your Mac is no longer protected by MDM security software. \n\nPlease save your work and contact IT Support immediately to re-enroll your Mac." with title "Immediate Action Required" with icon posix file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns" buttons {"I Understand"} default button 1
