# Go Port of CheckinChecker (Learning Version)

This `go/` directory is a complete Go port of the existing Bash program in `CheckinChecker.sh`.

- The original Bash scripts are intentionally left unchanged.
- This Go version is primarily for learning: functions are split by purpose and heavily commented so you can map each part back to the Bash script.

## Bash-to-Go mapping

| Bash function / section | Bash lines | Go counterpart |
|---|---:|---|
| `ScriptLogging` | 17-21 | `main.go` → `setupLogging`, `scriptLogging` |
| `CheckForNetwork` | 23-35 | `network.go` → `checkForNetwork` |
| Network wait loop in main | 200-208 | `network.go` → `waitForNetwork` |
| `CheckBinaryLocation` + `CheckBinary` | 47-71 | `jamf.go` → `findJamfBinary`; `main.go` step 2 branch |
| `LastCheckinDay` | 75-123 | `checkin.go` → `lastCheckinDate`; `main.go` step 3 branch |
| `forceCheckin` | 126-132 | `jamf.go` → `forceCheckin` |
| `restartBinary` | 135-141 | `jamf.go` → `restartBinary` |
| `checkinCheckerDaemon` | 145-171 | `daemon.go` → `installPromptDaemon` |
| `deleteCheckerDaemon` | 173-183 | `daemon.go` → `deletePromptDaemon` |
| Main body orchestration | 188-270 | `main.go` → `main` |

## Biggest parser win in Go

In Bash, lines 89-113 manually map month names (`Jan`, `Feb`, etc.) to month numbers with a long `if/elif` ladder.

In Go, that entire ladder is removed. `lastCheckinDate` reads the epoch timestamp and converts it with:

```go
time.Unix(seconds, 0)
```

This is one of the biggest practical wins of the port: less manual parsing, fewer edge-case bugs.

## Go concepts highlighted for a Bash/C++ developer

- **Error-as-value**: `if err != nil { ... }` is normal control flow.
- **Multiple return values**: functions commonly return `(value, error)`.
- **`defer`**: e.g. `defer f.Close()` to ensure cleanup.
- **`for ... range`**: iterate slices/maps/interfaces cleanly.
- **Slices + `len()`**: lightweight dynamic lists and bounds checks.
- **Typed durations**: `5 * time.Second` instead of raw numeric sleeps.
- **Raw string literals**: backticks for multiline XML/plists without quote escaping.
- **`bufio.Scanner`**: line-by-line file reading (replacement for `grep ... | tail -1` pattern).

## Build and run (macOS)

Quick local iteration:

```bash
cd go
go run .
```

Single-architecture binary:

```bash
cd go
go build -o checkinchecker .
```

Universal macOS binary (Apple Silicon + Intel):

```bash
cd go
# These are native macOS builds. They also work as cross-compiles when run from
# another OS with a properly configured Go toolchain.
GOOS=darwin GOARCH=arm64 go build -o checkinchecker-arm64 .
GOOS=darwin GOARCH=amd64 go build -o checkinchecker-amd64 .
lipo -create -output checkinchecker checkinchecker-arm64 checkinchecker-amd64
```

Validation:

```bash
cd go
go build ./...
go vet ./...
```

## About macOS-specific commands

Operations like `launchctl`, `osascript`, `jamf`, and `killall` are still external system commands on macOS.

Go does not provide native APIs for those tools, so this port shells out via `os/exec`. The improvement is safer structure, clearer error handling, and stronger parsing/type safety around those shell calls.
As with the Bash version, commands that use `sudo` require an execution context with appropriate privileges (typically root/LaunchDaemon context or equivalent sudoers configuration).

## Deployment note vs Bash

Compared to the Bash version, deployment changes are mostly packaging:

- Include the compiled Go binary in your package.
- Point your LaunchDaemon to that binary (instead of `/bin/bash` + script path).
- Keep companion scripts/assets (like the prompt script) as needed.
