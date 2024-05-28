#!/bin/bash
# This script will create the launchdaemon to run the checkinchecker script daily
# This script will run with the checkinchecker pkg install policy
# Created by: Brooke Burdick brooburd@gmail.com
# v1 2024
###THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.###
  echo "<?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.checkinchecker</string>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/sh</string> 
      <string>/private/var/tmp/CheckinChecker/CheckinChecker.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>43200</integer> 
  </dict>
  </plist>" > ~/Library/LaunchAgents/com.checkinchecker.plist
  
  sudo chown root:wheel ~/Library/LaunchAgents/com.checkinchecker.plist
  sudo chmod 755 ~/Library/LaunchAgents/com.checkinchecker.plist
  
#find logged in user's UID  
uid=$(ls -ln /dev/console | awk '{ print $3 }')

launchctl asuser $uid launchctl load ~/Library/LaunchAgents/com.checkinchecker.plist
launchctl asuser $uid launchctl enable gui/$uid/com.checkinchecker
launchctl asuser $uid launchctl kickstart -kp gui/$uid/com.checkinchecker
