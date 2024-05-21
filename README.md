# CheckinChecker Program
This Program runs every day, once per day, locally on a Mac to calculate when it last checked into Jamf. The This script does not rely on Jamf to work, only to install and kick it off. 

If a Mac has checked in in the past 90 days, it will log the results and exit. If it has been over 90 days, the CheckinChecker Program will first attempt to fix the binary, and then will create a persistent pop-up urging users to contact IT Support to get their Mac re-enrolled in Jamf. 

Once the user checks back into Jamf, the pop-ups will automatically disable. 

This program is meant to fix devices no longer checking into Jamf, but are still online and being used, without the need to reach out to users individually. The pop-up is persistent enough users should be compelled to reach out to IT Support. 

**Pop-up**

This pop-up will pop up every 5 minutes until the user re-enrolls in Jamf.

 <img width="372" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/456d76d8-f02c-4a45-b14c-ace95b2d4593">

**Logging**

As the CheckinChecker runs, it logs all output into the jamflog.log
Checking in:
<img width="468" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/0a6570cb-37ff-4315-a078-77ac6f5cc681">
Not checkeed in over 90 days:
<img width="468" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/9815220e-7cd1-461e-be26-e08fc3fd2d77">

**Deploy via Jamf**
1.	Upload the CheckinChecker_StartProgram script into Jamf
2.	Upload the pkg into Jamf
3.	Create a policy 	
a.	First install the pkg  
b.	Run the script AFTER the pkg is installed
c. Run once per computer
5.	After that, the program will run in the background of the Mac even if it stops checking into Jamf.

**Customization**
(Advanced) 
This program is customizable, you can customize the pop-up message, scan intervals, and pop-up intervals. Download the pkg, open it, edit, and re-package via composer. 

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

You can customize and then re-package via Jamf. Keep the file names the same! 

**Troubleshooting**

If a user calls in to re-enroll, or if there is an error with the prompts, you can run a command in Terminal to stop getting the prompts. This can be added to Self Service as well (but is pretty useless until the user is checking back into Jamf). Once a Mac checks back in, the program will automatically stop the prompts and unload the LaunchDaemon, but it can also be done manually. 

sudo launchctl bootout system/com.checkincheckerprompt

Logs can be found at: /private/tmp/CheckinChecker/jamfcheck.log

Stop the CheckinChecker program (not recommended, this will NOT stop the pop-ups, see the command above): sudo launchctl bootout system/com.checkinchecker

Remove the program at: /private/tmp/CheckinChecker (delete the folder)

**Notes**
This script has been adapted, added to, and modified from the CasperCheck script. The script was not updated in over 7 years, meant for on-premise servers, and QuickAdd packages are no longer an option. This new program is meant to work with Jamf Pro (cloud). 
GitHub - rtrouton/CasperCheck (https://github.com/broojamfburd/CheckinChecker/assets/36173452/5b0ffe92-22d7-4eb8-aa0e-919e7b9e6187)

The year is not shown on jamf.log, so the year is assumed to be this year - will need to fix

**Scenarios**
User last checked in today. – no popup
 <img width="468" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/7c000126-01f4-474d-81ab-687791ad828d">


It’s been over 90 days, but CheckinChecker is able to successfully fix the issue and check in – no popup. 
 <img width="468" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/9c4de230-cbe5-42f3-bac9-56593af499d5">


It’s been over 90 days, but even after attempting to fix, the Mac still has not checked in – popup.
 <img width="468" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/a482afd9-5062-48d8-aba6-898c273821ec">


It’s been over 1 day but less than 90 days since last checkin – no popup
 <img width="332" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/a8656429-4fac-4055-a2cc-0a0490c02db0">


User has no internet – no popup 
The program will wait up to 1 hour to establish a connection before exiting for the day.
<img width="468" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/ae9a3ea9-910f-4457-8177-9103fcb87369">
 
User does not have the Jamf binary installed (irrespective of last checkin).  - popup
 <img width="468" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/08c52bc5-dad5-4bfb-a5ed-e1594d2a24a0">


The Computer has never checked in - popup
This is rare, but can be found on a newly enrolled Mac or newly re-enrolled Mac
Resolve by running “sudo jamf policy” in terminal.
<img width="468" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/82711ccc-4ee2-40ea-bf11-a44d8f2e2853">

