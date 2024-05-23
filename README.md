**CheckinChecker Program**

CheckinChecker runs every day, locally on a Mac, to calculate when it last checked into Jamf and take action if it has not checked in in over 90 days. If a Mac has checked in in the past 90 days, it will log the results and exit. If it has been over 90 days, the CheckinChecker Program will first attempt to fix the binary, and then will create a persistent pop-up urging users to contact IT Support to get their Mac re-enrolled in Jamf. The program also checks for other stats, such as network connection and the location of the jamf binary.

Once the user checks back into Jamf, the pop-ups will automatically disable. 

This program is meant to fix devices no longer checking into Jamf, without the need to reach out to users individually and without needing the Jamf binary to be installed or working. The pop-up is persistent enough users will be compelled to reach out to IT Support. 


**Pop-up**

This pop-up will pop up every 5 minutes until the user re-enrolls in Jamf.
 <img width="372" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/841c884a-2b08-481b-9ea2-c9c31dd107bd">


**Components for Deployment**

•	Two scripts

•	One extension attribute

•	One pkg


**Deploy via Jamf**

1.	Upload the Extension attribute to Jamf.
2.	Upload CheckinCheckerKickoff.sh and CheckinChecker_Logging.sh scripts into Jamf
 
<img width="339" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/dcd88d82-1d27-4d47-a571-e289ebabcef3">

 <img width="372" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/56844073-2aef-43e4-a1ab-03fb05cd502e">

3.	Upload the CheckinChecker pkg into Jamf
<img width="310" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/cb37bfc3-ec19-4ec2-8a09-ce794d53a095">

4.	Create a policy to install CheckinChecker
a.	First add the pkg to install
<img width="429" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/0b0d82f2-5cbe-4e1e-b536-28dfc328b089">

b.	Run the CheckinChecker_Kickoff and the CheckinChecker_Logging scripts after the pkg is installed  

c.	Run Once per computer

<img width="414" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/9e398838-adca-4586-af32-490db250882a">

d.	This policy should have 1 package and 2 scripts and run once per computer.

 <img width="312" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/671c82b7-41f4-46b7-8e8b-8acdc1092731">

6.	Next, set up the check-in policy to run daily, this policy will write to a file (JamfCheckinLog.txt) to record the last check in day.
   
<img width="311" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/d60d38ce-af91-4dcd-9a6b-8515d6e0666c">

a.	Create the policy to run once a day with the script, scope to all users with CheckinChecker installed (you can make a smart group from the previously uploaded extension attribute).

b.	This policy should have 1 script, scoped to users with CheckinChecker Installed, and run once per day. 

<img width="312" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/27a93696-fa92-4f1f-8a62-7098b05528ca">


**Logging**

As the CheckinChecker runs, it logs all output into the checkinchecker.log

Example:

 <img width="468" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/0f91d52f-d097-4d58-b874-423a142a347c">
 
Computer not checked in in over 90 days example:

 <img width="459" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/8613c980-a90f-4455-b23b-545597ef5dc3">


**Log Scenarios**

User last checked in today. – no popup

 <img width="468" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/66892fcd-0a3d-4db1-a3d8-965a9c87d1fb">

It’s been over 90 days, but CheckinChecker is able to successfully fix the issue and check in – no popup. 

 <img width="468" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/2c3217e9-4764-4abb-ae32-ad548b0afdad">

It’s been over 90 days, but even after attempting to fix, the Mac still has not checked in – popup.

 <img width="468" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/b92ac14e-5864-4cf9-ae78-c8cd8637d9d8">


It’s been over 1 day but less than 90 days since last checkin – no popup

<img width="332" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/9a0e1a2b-966a-4567-8b38-fc0abae18090">
 

User has no internet – no popup 
The program will wait up to 1 hour to establish a connection before exiting for the day.

<img width="468" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/818454a4-5b6f-422b-a42e-f8a3ca2614b9">
 
User does not have the Jamf binary installed (irrespective of last checkin).  - popup

 <img width="468" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/857e3cd4-e9d6-4b19-af28-4973205c0c0e">


The Computer has never checked in - popup

This is rare, but can be found on a newly enrolled Mac, a newly re-enrolled Mac, OR if you never deployed the daily checkin policy. Running “sudo jamf policy” in terminal will run the checkin policy.

<img width="468" alt="image" src="https://github.com/broojamfburd/CheckinChecker/assets/36173452/34d9fc13-8f01-4513-a7b2-d7172983e92f">


**Customization**

(Advanced) This program is customizable, you can customize the pop-up message, scan intervals, and pop-up intervals. Download the pkg, open it, edit, and re-package via composer. 

Pop-up customization:
/private/tmp/CheckinChecker/CheckinCheckerPrompt.sh

Scan intervals (default 24 hours): 
/private/tmp/CheckinChecker/CheckinCheckerKickoff.sh

Pop-up Intervals: 
/private/tmp/CheckinChecker/CheckinChecker.sh (go to function checkinCheckerDaemon > edit interval)

If you want to change the last checkin trigger (default 90 days):
/private/tmp/CheckinChecker/CheckinChecker.sh 
•	Go to line 222, elif [[ $elapsedTime > 7776000 ]]; then and change to desired elapsed time in seconds
•	Make sure to change all instances of the seconds

For on-prem servers: There is some commented out lines for checking connection to server, but is not tested.


**Troubleshooting**

If a user calls in to re-enroll, or if there is an error with the prompts, you can run a command in Terminal to stop getting the prompts. This can be added to Self Service as well (but is useless until the user is checking back into Jamf). Once a Mac checks back in, the program will automatically stop the prompts and unload the LaunchDaemon, but it can also be done manually. 

sudo launchctl bootout system/com.checkincheckerprompt

Logs can be found at: /private/tmp/CheckinChecker/checkinchecker.log

Stop the CheckinChecker program (not recommended, this will NOT stop the pop-ups, see the command above): sudo launchctl bootout system/com.checkinchecker

Remove the program at: /private/tmp/CheckinChecker (delete the folder)


**Notes**
This script has been adapted, added to, and modified from the CasperCheck script. The script was not updated in over 7 years, meant for on-premise servers, and QuickAdd packages are no longer an option. 
GitHub - rtrouton/CasperCheck

