package main

import (
	"fmt"
	"os"
	"os/user"
	"path/filepath"
)

const promptDaemonLabel = "com.checkincheckerprompt"

func promptDaemonPlistPath() (string, *user.User, error) {
	currentUser, err := user.Current()
	if err != nil {
		return "", nil, fmt.Errorf("get current user: %w", err)
	}

	// filepath.Join is the Go equivalent of building ~/Library/LaunchAgents/... safely.
	path := filepath.Join(currentUser.HomeDir, "Library", "LaunchAgents", promptDaemonLabel+".plist")
	return path, currentUser, nil
}

// installPromptDaemon ports checkinCheckerDaemon (Bash lines 145-171).
// Like the Bash script, ownership/permission changes here expect root/sudo access.
func installPromptDaemon() error {
	plistPath, currentUser, err := promptDaemonPlistPath()
	if err != nil {
		return err
	}

	if err := os.MkdirAll(filepath.Dir(plistPath), 0o755); err != nil {
		return fmt.Errorf("create LaunchAgents directory: %w", err)
	}

	// IMPORTANT LEARNING NOTE:
	// This raw string literal (backticks) avoids escaping quote characters in XML.
	// It directly fixes the quoting bug in Bash line 146 where encoding="UTF-8"
	// sits inside a double-quoted heredoc-style echo string.
	plistContent := `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.checkincheckerprompt</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>/private/var/tmp/CheckinChecker/CheckinCheckerPrompt.sh</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>300</integer>
</dict>
</plist>
`

	if err := os.WriteFile(plistPath, []byte(plistContent), 0o644); err != nil {
		return fmt.Errorf("write prompt daemon plist: %w", err)
	}

	if err := runCommand("sudo", "chown", "root:wheel", plistPath); err != nil {
		return err
	}
	if err := runCommand("sudo", "chmod", "644", plistPath); err != nil {
		return err
	}

	uid := currentUser.Uid
	if err := runCommand("launchctl", "asuser", uid, "launchctl", "load", plistPath); err != nil {
		return err
	}
	if err := runCommand("launchctl", "asuser", uid, "launchctl", "enable", "gui/"+uid+"/"+promptDaemonLabel); err != nil {
		return err
	}
	if err := runCommand("launchctl", "asuser", uid, "launchctl", "kickstart", "-kp", "gui/"+uid+"/"+promptDaemonLabel); err != nil {
		return err
	}

	scriptLogging("Installed and loaded %s", filepath.Base(plistPath))
	return nil
}

// deletePromptDaemon ports deleteCheckerDaemon (Bash lines 173-183).
func deletePromptDaemon() error {
	plistPath, currentUser, err := promptDaemonPlistPath()
	if err != nil {
		return err
	}

	if _, err := os.Stat(plistPath); err != nil {
		if os.IsNotExist(err) {
			scriptLogging("No Checkin Checker Prompt Found.")
			return nil
		}
		return fmt.Errorf("check prompt daemon plist: %w", err)
	}

	uid := currentUser.Uid
	if err := runCommand("launchctl", "asuser", uid, "launchctl", "bootout", "gui/"+uid+"/"+promptDaemonLabel); err != nil {
		return err
	}
	if err := os.Remove(plistPath); err != nil {
		return fmt.Errorf("remove prompt daemon plist: %w", err)
	}

	scriptLogging("Disabled checkincheckerprompt.plist, User will receive no more prompts")
	return nil
}
