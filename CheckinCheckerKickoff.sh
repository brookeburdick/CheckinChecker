#!/bin/bash

  echo "<?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.checkinchecker</string>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/sh</string> 
      <string>/private/tmp/CheckinChecker/CheckinChecker.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>43200</integer> 
  </dict>
  </plist>" > /private/tmp/CheckinChecker/checkinchecker.plist
  
  sudo chown root:wheel /private/tmp/CheckinChecker/checkinchecker.plist
  sudo chmod 755 /private/tmp/CheckinChecker/checkinchecker.plist
  sudo launchctl load /private/tmp/CheckinChecker/checkinchecker.plist
