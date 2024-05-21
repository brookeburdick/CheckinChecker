# CheckinChecker
Repo for CheckinChecker Program
CheckinChecker Program

This Program runs every day, locally on a Mac, to calculate when it last checked into Jamf. If the This script does not rely on Jamf to work, only to install and kick it off. 

If a Mac has checked in in the past 90 days, it will log the results and exit. If it has been over 90 days, the CheckinChecker Program will first attempt to fix the binary, and then will create a persistent pop-up urging users to contact IT Support to get their Mac re-enrolled in Jamf. 

Once the user checks back into Jamf, the pop-ups will automatically disable. 

This program is meant to fix devices no longer checking into Jamf, without the need to reach out to users individually. The pop-up is persistent enough users will be compelled to reach out to IT Support. 

Pop-up
This pop-up will pop up every 5 minutes until the user re-enrolls in Jamf.
 

Logging
As the CheckinChecker runs, it logs all output into the jamflog.log

Deploy via Jamf
1.	Upload the kickoff script into Jamf
 
2.	Upload the pkg into Jamf
 
3.	Create a policy 	
a.	First install the pkg  
b.	Run the script AFTER the pkg is installed
 
4.	After that, the program will run in the background of the Mac even if it stops checking into Jamf.

Customization
(Advanced) This program is customizable, you can customize the pop-up message, scan intervals, and pop-up intervals. Download the pkg, open it, edit, and re-package via composer. 

Pop-up customization:
/private/tmp/CheckinChecker/CheckinCheckerPrompt.sh

Scan intervals (default 24 hours): 
/private/tmp/CheckinChecker/CheckinCheckerKickoff.sh

Pop-up Intervals: 
/private/tmp/CheckinChecker/CheckinChecker.sh (go to function checkinCheckerDaemon > edit interval)

If you want to change the checkin interval (default 90 days):
/private/tmp/CheckinChecker/CheckinChecker.sh 
•	Go to line 222, elif [[ $elapsedTime > 7776000 ]]; then and change to desired elapsed time in seconds
•	Make sure to change all instances of the seconds

For on-prem servers: There is some commented out lines for checking connection to server.

Troubleshooting
If a user calls in to re-enroll, or if there is an error with the prompts, you can run a command in Terminal to stop getting the prompts. This can be added to Self Service as well (but is pretty useless until the user is checking back into Jamf). Once a Mac checks back in, the program will automatically stop the prompts and unload the LaunchDaemon, but it can also be done manually. 

sudo launchctl bootout system/com.checkincheckerprompt

Logs can be found at: /private/tmp/CheckinChecker/jamfcheck.log

Stop the CheckinChecker program (not recommended, this will NOT stop the pop-ups, see the command above): sudo launchctl bootout system/com.checkinchecker

Remove the program at: /private/tmp/CheckinChecker (delete the folder)

Notes
This script has been adapted, added to, and modified from the CasperCheck script. The script was not updated in over 7 years, meant for on-premise servers, and QuickAdd packages are no longer an option. 
GitHub - rtrouton/CasperCheck
![image](https://github.com/broojamfburd/CheckinChecker/assets/36173452/5b0ffe92-22d7-4eb8-aa0e-919e7b9e6187)
