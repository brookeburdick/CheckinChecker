package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"
)

const (
	// logLocation matches CheckinChecker.sh line 11.
	logLocation = "/private/var/tmp/CheckinChecker/CheckinChecker.log"
	// checkinLog matches CheckinChecker.sh line 77.
	checkinLog = "/private/var/tmp/CheckinChecker/JamfCheckinLog.txt"
	// maxDays matches the 90-day threshold used by the Bash script.
	maxDays = 90
)

var logger *log.Logger

// setupLogging is the Go replacement for the setup done around Bash lines 11-21.
// It ensures the log directory/file exist, then wires up a package-level logger.
func setupLogging() error {
	if err := os.MkdirAll(filepath.Dir(logLocation), 0o755); err != nil {
		return fmt.Errorf("create log directory: %w", err)
	}

	f, err := os.OpenFile(logLocation, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return fmt.Errorf("open log file: %w", err)
	}

	logger = log.New(f, "", 0)
	return nil
}

// scriptLogging mirrors Bash ScriptLogging (lines 17-21).
func scriptLogging(format string, args ...any) {
	if logger == nil {
		// Fallback if setup failed; keeps logging calls safe.
		logger = log.New(os.Stderr, "", 0)
	}

	timestamp := time.Now().Format("2006-01-02 15:04:05")
	logger.Printf("%s %s", timestamp, fmt.Sprintf(format, args...))
}

func main() {
	if err := setupLogging(); err != nil {
		log.Fatalf("failed to initialize logging: %v", err)
	}

	scriptLogging("******************** STARTING CHECKIN CHECKER ********************")

	// STEP 1 (Bash lines 197-220): wait for network before doing anything else.
	scriptLogging("Checking for active network connection.")
	if !waitForNetwork() {
		scriptLogging("********************* EXITING CHECKIN CHECKER - NO NETWORK ********************")
		os.Exit(1)
	}
	scriptLogging("Network connection appears to be live.")

	// STEP 2 (Bash lines 231-234): verify jamf binary path.
	scriptLogging("Checking for Jamf Binary")
	jamfBinary, err := findJamfBinary()
	if err != nil {
		scriptLogging("Jamf Binary Not Installed, Prompting user to call support")
		scriptLogging("********************* EXITING CHECKIN CHECKER - NO JAMF BINARY ********************")
		if daemonErr := installPromptDaemon(); daemonErr != nil {
			scriptLogging("Failed to install prompt daemon: %v", daemonErr)
		}
		os.Exit(1)
	}
	scriptLogging("Jamf Binary found at %s", jamfBinary)

	// STEP 3 (Bash lines 235-270): load last check-in and branch by elapsed time.
	scriptLogging("Checking last checkin day.")
	last, err := lastCheckinDate()
	if err != nil {
		scriptLogging("Jamf Checkin Log Not Found or no recurring check-ins, Prompting user to call support: %v", err)
		scriptLogging("********************* EXITING CHECKIN CHECKER - NO CHECKINS LOGGED ********************")
		if daemonErr := installPromptDaemon(); daemonErr != nil {
			scriptLogging("Failed to install prompt daemon: %v", daemonErr)
		}
		os.Exit(1)
	}

	elapsed := time.Since(last)
	threshold := time.Duration(maxDays) * 24 * time.Hour

	// Bash line 238 checks for a 0 epoch sentinel ("never checked in").
	if last.Unix() == 0 {
		scriptLogging("Device never checked in, attempting to check in. Will try again tomorrow.")
		if err := forceCheckin(jamfBinary); err != nil {
			scriptLogging("Force checkin failed: %v", err)
		}
		scriptLogging("********************* EXITING CHECKIN CHECKER - NO CHECKIN DATE ********************")
		os.Exit(1)
	}

	if elapsed < threshold {
		scriptLogging("Device recently checked in. Last checkin was %s.", last.Format(time.RFC3339))
		if err := deletePromptDaemon(); err != nil {
			scriptLogging("Failed to remove prompt daemon: %v", err)
		}
	} else {
		scriptLogging("Device has not checked in in over %d days. Elapsed Time is %d (in seconds). Last Checkin was %s", maxDays, int64(elapsed.Seconds()), last.Format(time.RFC3339))
		scriptLogging("Attempting to fix Jamf Binary.")
		if err := restartBinary(jamfBinary); err != nil {
			scriptLogging("Failed to restart Jamf Binary: %v", err)
		}

		// Bash lines 253-256 re-check using the same elapsed value and install the prompt daemon.
		if elapsed >= threshold {
			scriptLogging("Device has not checked in in over %d days. Last checkin was %s.", maxDays, last.Format(time.RFC3339))
			scriptLogging("Creating LaunchDaemon com.checkincheckerprompt.")
			if err := installPromptDaemon(); err != nil {
				scriptLogging("Failed to install prompt daemon: %v", err)
			}
		}
	}

	scriptLogging("******************** CHECKIN CHECKER COMPLETE ********************")
}
