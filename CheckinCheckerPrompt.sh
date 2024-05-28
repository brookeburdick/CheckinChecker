#!/bin/bash
# This script will kick off only if it has been over 90 days since last checkin
# This can be customized if you wish to change or add to the pop-up message/ icon
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
	display dialog "Your Mac is no longer protected by Parachute security software. \n\nPlease save your work and contact Parachute Support immediately to re-enroll your Mac.\n\nTelephone: 415-762-0720\nEmail: Support@parachutetechs.com" with title "Immediate Action Required" with icon posix file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns" buttons {"I Understand"} default button 1
