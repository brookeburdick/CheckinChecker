package main

import (
	"net"
	"time"
)

// checkForNetwork is the Go equivalent of CheckForNetwork (Bash lines 23-35).
// Instead of parsing `ifconfig | sed | wc -l`, Go can inspect interfaces directly.
func checkForNetwork() bool {
	interfaces, err := net.Interfaces()
	if err != nil {
		scriptLogging("Error listing network interfaces: %v", err)
		return false
	}

	for _, iface := range interfaces {
		if iface.Flags&net.FlagUp == 0 {
			continue // Interface exists but is not active.
		}
		if iface.Flags&net.FlagLoopback != 0 {
			continue // Explicitly skip loopback interfaces (same intent as Bash).
		}

		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}

		for _, addr := range addrs {
			var ip net.IP
			switch v := addr.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			default:
				continue
			}

			if ip == nil || ip.IsLoopback() || ip.IsUnspecified() {
				continue
			}

			// If we found any real IPv4 or IPv6 address, network is considered up.
			if ip.To4() != nil || ip.To16() != nil {
				return true
			}
		}
	}

	return false
}

// waitForNetwork ports Bash lines 200-208: poll every 5 seconds, up to 720 attempts.
// 720 attempts * 5 seconds = 3,600 seconds (60 minutes).
func waitForNetwork() bool {
	const (
		maxAttempts = 720
		pollDelay   = 5 * time.Second
	)

	for attempt := 1; attempt <= maxAttempts; attempt++ {
		if checkForNetwork() {
			return true
		}

		scriptLogging("Network not available yet (attempt %d/%d)", attempt, maxAttempts)
		if attempt < maxAttempts {
			time.Sleep(pollDelay)
		}
	}

	return false
}
