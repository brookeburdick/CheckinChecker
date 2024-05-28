#!/bin/bash
# This is the main script, it will run daily to check the Mac's last checkin date, if it's been over 90 days it will create a new process to prompt the user to call support
# This script is called by a Launch Daemon, not Jamf itself, so it runs locally
# Created by: Brooke Burdick brooburd@gmail.com
# v1 2024
###THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.###
#Enter the JSS server address needed only if on-prem server
#jss_server_address

#This is the location everything will be logged
log_location="/private/var/tmp/CheckinChecker/CheckinChecker.log"
touch "/private/var/tmp/CheckinChecker/CheckinChecker.log"
sudo chmod 755 "/private/var/tmp/CheckinChecker/CheckinChecker.log"

# Function to provide logging of the script's actions to
# the log file defined by the log_location variable
ScriptLogging(){
    DATE=`date +%Y-%m-%d\ %H:%M:%S`
    LOG="$log_location"
    echo "$DATE" " $1" >> $LOG
}

CheckForNetwork(){
# Determine if the network is up by looking for any non-loopback network interfaces.
  local test
    
    if [[ -z "${NETWORKUP:=}" ]]; then
        test=$(ifconfig -a inet 2>/dev/null | sed -n -e '/127.0.0.1/d' -e '/0.0.0.0/d' -e '/inet/p' | wc -l)
        if [[ "${test}" -gt 0 ]]; then
            NETWORKUP="-YES-"
        else
            NETWORKUP="-NO-"
        fi
    fi
}

#Not used unless using an on-premise server
#CheckSiteNetwork (){  
#  site_network="False"
#  ping=`host -W .5 $jss_server_address`
  
  # If the ping fails - site_network="False"
#  [[ $? -eq 0 ]] && site_network="True"
  
#}

# Identify location of jamf binary.
CheckBinary (){
jamf_binary=`/usr/bin/which jamf`
 if [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ ! -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/sbin/jamf"
 elif [[ "$jamf_binary" == "" ]] && [[ ! -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/local/bin/jamf"
 elif [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/local/bin/jamf"
 fi
}

# Finds the last check-in day from the /private/var/tmpCheckinChecker/JamfCheckinLog.txt 
# This relies on a companion Jamf policy that runs once per day
LastCheckinDay () {
#Before checking last check-in, we need to make sure the file exists
  if [[  -f  "/private/var/tmp/CheckinChecker/JamfCheckinLog.txt" ]]
  then
    line=$(grep "recurring check-in" /private/var/tmp/CheckinChecker/JamfCheckinLog.txt | tail -1 )
    lastCheckinEpoch=$(echo $line | awk '{ print $1 }')
    lastCheckinEpoch=$(echo "$lastCheckinEpoch" | tr -cd '[:digit:]. ')
    lastCheckinDate=$(echo $line | awk '{ print $2 }')
    lastCheckinDate=$(echo "$lastCheckinDate" | tr '-' ' ' )
    
    #Change the month name into a number
    monStr=$( echo $lastCheckinDate | awk '{print $2}' )
    dayNum=$( echo $lastCheckinDate | awk '{print $3}' | sed 's/.$//'  )
    yearNum=$( echo $lastCheckinDate | awk '{print $1}' | sed 's/^.//' )
    if [[ "$monStr" = "Jan" ]]; then
      monNum=01
    elif [[ "$monStr" = "Feb" ]]; then
      monNum=02
    elif [[ "$monStr" = "Mar" ]]; then
      monNum=03
    elif [[ "$monStr" = "Apr" ]]; then
      monNum=04
    elif [[ "$monStr" == "May" ]]; then
      monNum=05
    elif [[ "$monStr" = "Jun" ]]; then
      monNum=06
    elif [[ "$monStr" = "Jul" ]]; then
      monNum=07
    elif [[ "$monStr" = "Aug" ]]; then
      monNum=08
    elif [[ "$monStr" = "Sep" ]]; then
      monNum=09
    elif [[ "$monStr" = "Oct" ]]; then
      monNum=10
    elif [[ "$monStr" = "Nov" ]]; then
      monNum=11
    elif [[ "$monStr" == "Dec" ]]; then
      monNum=12
    fi
    todayEpoch=$( date $today "+%s")
    elapsedTime=$(($todayEpoch - $lastCheckinEpoch))
    # If the logs do not exist or there are no check-ins in the log, it will exit and prompt the user to contact support
  else 
    ScriptLogging "Jamf Checkin/ Log Not Found, Prompting user to call support"
    ScriptLogging "********************* EXITING CHECKIN CHECKER - NO CHECKINS LOGGED ********************"
    checkinCheckerDaemon
    exit 1
  fi 
}

# In an attempt to fix jamf binary, force checkin
forceCheckin(){
  ScriptLogging "Running Recon"
  sudo $jamf_binary recon  >> $log_location
  sudo $jamf_binary policy >> $log_location
  #sudo $jamf_binary policy  >> $log_location
  sleep 10
}

#Restart Jamf binary to try to repair it
restartBinary(){
  ScriptLogging "Restarting Jamf Binary..."
  sudo killall jamf
  sleep 10
  ScriptLogging "Running Recon"
  sudo $jamf_binary recon
}

# This daemon will run if it's been over 90 days since last checkin
# The Daemon will create a pop-up every 5 minutes
checkinCheckerDaemon(){
  echo "<?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.checkincheckerprompt</string>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/sh</string> 
      <string>/private/var/tmp/CheckinChecker/CheckinCheckerPrompt.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>300</integer> 
  </dict>
  </plist>" > /private/var/tmp/CheckinChecker/checkincheckerprompt.plist
  
  sudo chown root:wheel /private/var/tmp/CheckinChecker/checkincheckerprompt.plist
  sudo chmod 755 /private/var/tmp/CheckinChecker/checkincheckerprompt.plist
  sudo launchctl load /private/var/tmp/CheckinChecker/checkincheckerprompt.plist
}

deleteCheckerDaemon (){
  if [[ -f "/private/var/tmp/CheckinChecker/checkincheckerprompt.plist" ]]; then
    sudo launchctl bootout system/com.checkincheckerprompt
    rm -f /private/var/tmp/CheckinChecker/checkincheckerprompt.plist
    ScriptLogging "Removed checkincheckerprompt.plist, User will receive no more prompts"
  fi
}
#End Functions

# Main Body
ScriptLogging "******************** STARTING CHECKIN CHECKER ********************"
# Wait up to 60 minutes for a network connection to become 
# available which doesn't use a loopback address. This 
# condition which may occur if this script is run by a 
# LaunchDaemon at boot time.
# The network connection check will occur every 5 seconds
# until the 60 minute limit is reached.

#STEP1: CHECK NETWORK
ScriptLogging "Checking for active network connection."
CheckForNetwork
i=1
while [[ "${NETWORKUP}" != "-YES-" ]] && [[ $i -ne 720 ]]
do
    sleep 5
    NETWORKUP=
    CheckForNetwork
    echo $i
    i=$(( $i + 1 ))
done

# If no network connection is found within 60 minutes,
# the script will exit.

if [[ "${NETWORKUP}" != "-YES-" ]]; then
   ScriptLogging "********************* EXITING CHECKIN CHECKER - NO NETWORK ********************"
    exit 1
elif [[ "${NETWORKUP}" == "-YES-" ]]; then
   ScriptLogging "Network connection appears to be live."
else
  ScriptLogging "Error getting Network Status"
fi  

# CHECK DEVICE CAN REACH JSS SERVER
# ON-PREM ONLY
# CheckSiteNetwork
# if [[ "$site_network" == "False" ]]; then
# ScriptLogging "Unable to verify connection to JSS Server."
# elif [[ "$site_network" == "True" ]]; then
#  ScriptLogging "Access to JSS Server verified"
# fi

# STEP 2: CHECK JAMF BINARY EXISTS
ScriptLogging "Checking for Jamf Binary"
CheckBinary
if [[ $jamf_binary == "/usr/sbin/jamf" ]]; then
  ScriptLogging "Jamf Binary found at" $jamf_binary
elif [[ $jamf_binary == "/usr/local/bin/jamf" ]]; then
  ScriptLogging "Jamf Binary found at $jamf_binary"
else
    ScriptLogging "Jamf Binary Not Installed, Prompting user to call support"
    ScriptLogging "********************* EXITING CHECKIN CHECKER - NO JAMF BINARY ********************"
    checkinCheckerDaemon
    exit 1
fi  

# Check last checkin day, take action
# If over 90 days, trigger the prompt

ScriptLogging "Checking last checkin day."
LastCheckinDay
#This condition checks if the device has ever checked in, if not it defaults to 00000
if [[ $lastCheckinEpoch == 00000 ]]; then
  ScriptLogging "Device never checked in, attempting to check in. Will try again tomorrow."
  forceCheckin 
  ScriptLogging "********************* EXITING CHECKING CHECKER - NO CHECKIN DATE ********************"
  exit 1
elif [[ $elapsedTime -lt 7776000 ]]; then
ScriptLogging "Device recently checked in. Last checkin was $lastCheckinDate."
deleteCheckerDaemon
  #If it's been longer than 90 days, attempt to force check in and restart the binary
  #If it still is not checking in, then launch the daemon  
elif [[ $elapsedTime -ge 7776001 ]]; then
  ScriptLogging "Device has not checked in in over 90 days. Elapsed Time is $elapsedTime (in seconds). Last Checkin was $lastCheckinDate"
  ScriptLogging "Attempting to fix Jamf Binary."
  restartBinary 
  sleep 10
  if [[ $elapsedTime -ge 7776000 ]]; then
    ScriptLogging "Device has not checked in in over 90 days. Last checkin was $lastCheckinDate."
    ScriptLogging "Creating LaunchDaemon com.checkincheckerprompt."
    checkinCheckerDaemon
  elif [[ $elapsedTime -lt 7776000 ]]; then
    ScriptLogging "Device has recently checked in. Last checkin was $lastCheckinDate."
  else
    ScriptLogging "Unable to calculate last checkin. Exiting."
    ScriptLogging "********************* EXITING CHECKING CHECKER - UNABLE TO CALCULATE ********************"
  fi  
else
  ScriptLogging "Unable to calculate last checkin. Exiting."
  ScriptLogging "********************* EXITING CHECKING CHECKER - UNABLE TO CALCULATE ********************"
  exit 1
fi	

ScriptLogging "******************** CHECKIN CHECKER COMPLETE ********************"
exit 0
