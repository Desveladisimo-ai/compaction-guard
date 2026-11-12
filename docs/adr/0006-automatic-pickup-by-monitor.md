# 0006: A monitor starts the next session from the handoff

- Status: Accepted
- Date: 2026-11-07

## Context
A `SessionStart` hook can put the handoff in the context, but the assistant then waits for the user's first message. The goal is that the user never copies or types anything. `initialUserMessage` is documented for non-interactive `-p` mode only.

## Decision
The `SessionStart` hook (on `startup` and `clear`) loads the pending handoff and leaves a marker file. A plugin monitor, `handoff-announce`, polls once a second and prints one line when it sees the marker, which wakes the assistant to announce the handoff and carry on. The monitor never ends: when a monitor ends, Claude Code reports "stream ended" and starts a pointless turn in every session.

## Consequences
- Works after `/clear` and in a new session, interactive sessions only (monitors do not start with `-p`).
- Claude Code shows "1 monitor" in its status bar; the README explains it.
- Monitors, like hooks, run as the user; Claude Code sets that, not the plugin. The monitor only reads and deletes a marker file under `state/` and prints one line. It reads the marker only if it is a plain file ([0007](0007-fail-open.md)).

## Evidence
Real interactive session on Claude Code 2.1.319: a pending handoff at start was announced after 6.7 s; the flow "idle session, handoff appears, user types `/clear`" was announced after 4.3 s, with no message from the user ([test log](../decisions.md)).

## Amendment (2026-11-11, version 0.1.5)
The marker is per project folder, so two sessions in one folder shared it, and the monitor of the session that ran the wrap-up could take the notice meant for the new session. A monitor now claims the marker by renaming it to a name of its own (only one rename can succeed; 0.1.5 shipped a `mkdir` lock, which a Linux 7.0 Azure CI runner did not make exclusive: two `mkdir` of one path both succeeded in 63 of 100 tries, while rename, hard link, symlink and noclobber file creation had one winner in 100 of 100 tries on Linux, macOS and Windows Git Bash), ignores and removes a marker older than a minute, and its line says to act only if the session's context contains the handoff text. Binding the notice to one session would need a session identifier visible to the monitor; the Claude Code documentation does not give one (checked 2026-11-10), so the new session relies on the handoff text in its own context and acts on it at its first message when it is not woken first. Tests: "two monitors in one folder: exactly one is woken", "a stale marker does not wake the assistant".

The wrap-up and the session start must also agree on the project folder. The Bash tool does not export `CLAUDE_PROJECT_DIR` and keeps a folder the assistant changed to, so `handoff-path.sh` now walks up from the current folder to the nearest folder a session was started in (recorded under `state/roots/` by the session start). Test: "a wrap-up from a subfolder uses the session's project folder".
