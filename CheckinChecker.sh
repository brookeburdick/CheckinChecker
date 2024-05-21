#!/bin/bash
# Part 3 of 4 of CheckinChecker Program, main script
# Created by: Brooke Burdick brooburd@gmail.com
# v1 2024
###THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.###


#Enter the JSS server address needed only if on-prem server
#jss_server_address

log_location="/private/tmp/CheckinChecker/jamfcheck.log"
touch "/private/tmp/CheckinChecker/jamfcheck.log"
sudo chmod 755 "/private/tmp/CheckinChecker/jamfcheck.log"

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
CheckSiteNetwork (){  
  site_network="False"
  ping=`host -W .5 $jss_server_address`
  
  # If the ping fails - site_network="False"
  [[ $? -eq 0 ]] && site_network="True"
  
}

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
#echo $jamf_binary

}

#find the last check-in day from the jamf.log 
#output as Month day, no year in the logs, so we have to use this year by default...
#If it has been longer than 90 days and all other network checks succeed, proceed to restart Jamf Binary or prompt user to reinstall
LastCheckinDay () {
  line=$(grep "recurring check-in" /private/var/log/jamf.log | tail -1 )
  lastCheckin=$(echo $line | awk '{print $2, $3, $4 }')
  ScriptLogging "Last Checkin was $lastCheckin"
  
  formatDate=$(echo $lastCheckin )
  
  ### Validate input
  ### Read input
  monStr=$( echo $lastCheckin | awk '{print $1}' )
  dayNum=$( echo $lastCheckin | awk '{print $2}' )
  timeNum=$( echo $lastCheckin | awk '{print $3}')
  hrs=$( echo $timeNum | awk '{print $1}' )
  mins=$( echo $timeNum | awk '{print $2}' )
  secs=$( echo $timeNum | awk '{print $3}' )
  yearNum=$(date +%Y )
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
  checkinNum=$(echo $yearNum-$monNum-$dayNum )
  #echo "Last Checkin date was $checkinNum"
  
  #convert last checkin to epoch time
  lastCheckinEpoch=$( date -j -f "%Y-%m-%d" "$checkinNum" "+%s")
  #echo "Last checkin epoch" $lastCheckinEpoch 
  todayEpoch=$( date $today "+%s")
  #echo "Today epoch" $todayEpoch 
  
  elapsedTime=$(($todayEpoch - $lastCheckinEpoch))
  ScriptLogging "Elapsed Time since last checkin (in seconds) $elapsedTime"
}

#Jamf recon
forceCheckin(){
  ScriptLogging "Running Recon"
  sudo $jamf_binary recon >> $log_location
  sleep 20
}

#Restart Jamf binary
restartBinary(){
  sudo killall jamf
  sleep 10
  sudo jamf policy
}

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
      <string>/private/tmp/CheckinChecker/CheckinCheckerPrompt.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>300</integer> 
  </dict>
  </plist>" > /private/tmp/CheckinChecker/checkincheckerprompt.plist
  
  sudo chown root:wheel /private/tmp/CheckinChecker/checkincheckerprompt.plist
  sudo chmod 755 /private/tmp/CheckinChecker/checkincheckerprompt.plist
  sudo launchctl load /private/tmp/CheckinChecker/checkincheckerprompt.plist
}

deleteCheckerDaemon (){
  sudo launchctl bootout system/com.checkincheckerprompt
}
#End Functions

ScriptLogging "******************** Starting CheckinChecker ********************"
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
   ScriptLogging "Network connection appears to be offline. Exiting."
    exit 0
elif [[ "${NETWORKUP}" == "-YES-" ]]; then
   ScriptLogging "Network connection appears to be live."
else
  ScriptLogging "Error getting Network Status"
fi  

#CHECK DEVICE CAN REACH JSS SERVER
# ON-PREM ONLY
# CheckSiteNetwork
# if [[ "$site_network" == "False" ]]; then
# ScriptLogging "Unable to verify connection to JSS Server."
# elif [[ "$site_network" == "True" ]]; then
#  ScriptLogging "Access to JSS Server verified"
# fi

#CHECK JAMF BINARY EXISTS
ScriptLogging "Checking for Jamf Binary"
CheckBinary
if [[ $jamf_binary == "/usr/sbin/jamf" ]]; then
  ScriptLogging "Jamf Binary found at" $jamf_binary
elif [[ $jamf_binary == "/usr/local/bin/jamf" ]]; then
  ScriptLogging "Jamf Binary found at $jamf_binary"
else
    ScriptLogging "Jamf Binary Not Installed"
    checkinCheckerDaemon
fi  

#CHECK LAST CHECKIN DATE
#If it's been over 90 days, it will attempt to fix binary, and then a launchdaemon will be created to run a prompt every X minutes to call support
ScriptLogging "Checking last checkin day."
LastCheckinDay
#For testing
#elapsedTime=7776001
if [[ $elapsedTime == 0 ]]; then
  ScriptLogging "Device checked in today."
  deleteCheckerDaemon > /dev/null
#If it's been longer than 90 days, attempt to force check in and restart the binary
#If it still is not checking in, then launch the daemon  
elif [[ $elapsedTime > 7776000 ]]; then
  ScriptLogging "Device has not checked in in over 90 days. Elapsed Time is $elapsedTime (in seconds)."
  ScriptLogging "Attempting to fix Jamf Binary."
  restartBinary 
  forceCheckin 
  sleep 10
  LastCheckinDay
    if [[ $elapsedTime == 0 ]]; then
      ScriptLogging "Device checked in today."
    elif [[ $elapsedTime > 7776000 ]]; then
      ScriptLogging "Device has not checked in in over 90 days. Elapsed Time is $elapsedTime (in seconds)."
      ScriptLogging "Creating LaunchDaemon com.checkincheckerprompt."
      checkinCheckerDaemon
    elif [[ $elapsedTime < 7776000 ]]; then
      ScriptLogging "Device has not checked in in today. Elapsed time is $elapsedTime. Last checkin was $checkinNum."
    else
      ScriptLogging "Unable to calculate last checkin. Exiting."
    fi
elif [[ $elapsedTime < 7776000 ]]; then
  ScriptLogging "Device has not checked in in today. Elapsed time is $elapsedTime. Last checkin was $checkinNum."
  deleteCheckerDaemon > log_location
else
  ScriptLogging "Unable to calculate last checkin. Exiting."
fi	

ScriptLogging "******************** CheckinChecker Complete ********************"
exit 0
