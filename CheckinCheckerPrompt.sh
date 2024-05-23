#!/bin/bash
# This script will kick off only if it has been over 90 days since last checkin
# This can be customized if you wish to change or add to the pop-up message/ icon
# v1 2024
###THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.###

#Ask User to Contact Support via pop-up, LaunchDaemon will run this at intervals

osascript <<EOD
	display dialog "Your Mac is no longer protected by MDM software. \n\nPlease save your work and contact IT Support Support immediately to re-enroll your Mac." with title "Immediate Action Required" with icon posix file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns" buttons {"I Understand"} default button 1
