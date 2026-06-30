package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
	"unicode"
)

// lastCheckinDate ports LastCheckinDay (Bash lines 75-123).
func lastCheckinDate() (time.Time, error) {
	f, err := os.Open(checkinLog)
	if err != nil {
		if os.IsNotExist(err) {
			return time.Time{}, fmt.Errorf("check-in log file does not exist: %s", checkinLog)
		}
		return time.Time{}, fmt.Errorf("open check-in log: %w", err)
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	var lastRecurringLine string

	// This replaces `grep "recurring check-in" ... | tail -1` from Bash line 79.
	for scanner.Scan() {
		line := scanner.Text()
		if strings.Contains(line, "recurring check-in") {
			lastRecurringLine = line
		}
	}

	if err := scanner.Err(); err != nil {
		return time.Time{}, fmt.Errorf("scan check-in log: %w", err)
	}
	if lastRecurringLine == "" {
		return time.Time{}, fmt.Errorf("no recurring check-in entries found")
	}

	fields := strings.Fields(lastRecurringLine)
	if len(fields) < 2 {
		return time.Time{}, fmt.Errorf("unexpected recurring check-in format: %q", lastRecurringLine)
	}

	// Bash line 81 used `tr -cd '[:digit:]. '` to clean field 1.
	// We keep only digits and parse as epoch seconds.
	epochDigitsOnly := strings.Map(func(r rune) rune {
		if unicode.IsDigit(r) {
			return r
		}
		return -1
	}, fields[0])
	if epochDigitsOnly == "" {
		return time.Time{}, fmt.Errorf("missing epoch in recurring check-in line: %q", lastRecurringLine)
	}

	seconds, err := strconv.ParseInt(epochDigitsOnly, 10, 64)
	if err != nil {
		return time.Time{}, fmt.Errorf("parse epoch %q: %w", epochDigitsOnly, err)
	}

	// BIGGEST WIN OF THE GO PORT:
	// Bash lines 85-113 used a long month-name-to-number if/elif ladder.
	// Go's `time.Unix` makes that entire conversion unnecessary because the log
	// already provides epoch seconds. Native time handling removes manual parsing.
	return time.Unix(seconds, 0), nil
}
