#!/bin/bash
# Part 1/4 CheckinChecker Program
# This script will create the launchdaemon to kick off the daily script checkinchecker.sh
# Checkin Checker will run once per day, if it's been determined > 90 days since last check-in, a new launchdaemon will be created
#This new Launchdaemon will create a pop-up every X seconds to call support and re-enroll

sudo sh "/private/tmp/CheckinChecker/CheckinCheckerKickoff.sh"

echo "Kicked off CheckinChecker Program."

sudo launchctl enable "/private/tmp/CheckinChecker/checkinchecker.plist"