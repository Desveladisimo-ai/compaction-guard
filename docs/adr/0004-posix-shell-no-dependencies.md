# 0004: POSIX shell and standard tools only

- Status: Accepted
- Date: 2026-11-06

## Context
The first local version used `jq` and `osascript`. A public plugin should work on macOS and Linux with nothing to install, and every dependency is something a user may not have and something to keep secure.

## Decision
The scripts are POSIX `sh` using only `sed`, `grep`, `awk`, `tail`, `date`, `cksum` and `find`. Desktop notifications use `osascript` or `notify-send` when present and are skipped otherwise. JSON fields are read with `sed`, which is enough for the few flat fields the hooks receive.

## Consequences
- No supply chain beyond the operating system. Nothing to install.
- Native Windows without a POSIX shell is not supported and is not tested.
- A change in Claude Code's JSON shape can make a field unreadable; the hooks then fail open ([0007](0007-fail-open.md)).

## Evidence
The suite passes on macOS, Ubuntu 24.04 (dash) and Alpine 3.20 (busybox); ShellCheck is clean with `-s sh`; a policy test fails the build if a script gains a network call, `eval` or privilege escalation.
