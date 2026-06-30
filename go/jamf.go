package main

import (
	"fmt"
	"os"
	"os/exec"
	"time"
)

// findJamfBinary ports CheckBinaryLocation/CheckBinary (Bash lines 47-71).
func findJamfBinary() (string, error) {
	// exec.LookPath is the Go equivalent of `which jamf`.
	if path, err := exec.LookPath("jamf"); err == nil {
		return path, nil
	}

	// Match Bash fallback behavior by checking known installation paths.
	fallbacks := []string{"/usr/local/bin/jamf", "/usr/sbin/jamf"}
	for _, path := range fallbacks {
		if _, err := os.Stat(path); err == nil {
			return path, nil
		}
	}

	return "", fmt.Errorf("jamf binary not found in PATH or fallback locations")
}

// forceCheckin ports Bash forceCheckin (lines 126-132): sudo jamf recon + sudo jamf policy.
func forceCheckin(jamfBinary string) error {
	scriptLogging("Running Recon")
	if err := runCommand("sudo", jamfBinary, "recon"); err != nil {
		return err
	}
	if err := runCommand("sudo", jamfBinary, "policy"); err != nil {
		return err
	}
	time.Sleep(10 * time.Second)
	return nil
}

// restartBinary ports Bash restartBinary (lines 135-141): killall jamf then jamf recon.
func restartBinary(jamfBinary string) error {
	scriptLogging("Restarting Jamf Binary...")
	if err := runCommand("sudo", "killall", "jamf"); err != nil {
		// Bash did not stop on this failure; continue so recon can still run.
		scriptLogging("killall jamf did not complete cleanly (continuing): %v", err)
	}
	time.Sleep(10 * time.Second)
	scriptLogging("Running Recon")
	return runCommand("sudo", jamfBinary, "recon")
}

// runCommand centralizes command execution and log capture.
func runCommand(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	output, err := cmd.CombinedOutput()
	if len(output) > 0 {
		scriptLogging("Command output (%s %v): %s", name, args, string(output))
	}
	if err != nil {
		return fmt.Errorf("command failed (%s %v): %w", name, args, err)
	}
	return nil
}
