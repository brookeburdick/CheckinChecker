#!/bin/bash
# Part of 4 of 4 the CheckinChecker Program
# This script creates a pop-up on the user's screen
# The associated Launchdaemon will call this script every 5 minutes
# To customize the pop-up, you can edit the AppleScript
# Created by: Brooke Burdick brooburd@gmail.com
# v1 2024
###THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.###

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
