# 0011: Make an inactive session visible

- Status: Accepted
- Date: 2026-11-09

## Context
Claude Code loads plugins when a session starts or on `/reload-plugins`. A session open at install time never registers the plugin's hooks, and `claude plugin list` still reports the plugin as installed. The plugin had no way to show, from inside a session, that it was not active there ([incident review](../incidents/2026-11-09-plugin-inactive-in-open-session.md)).

## Decision
- A `SessionStart` hook with no matcher (so for every source: startup, clear, resume, compact) runs `mark-active.sh`, which records `state/<session id>.active`. The prompt hook records it too, because after `/reload-plugins` in an old session `SessionStart` does not fire but the next prompt does.
- The optional status line prints `guard OFF: run /reload-plugins` when the session already has tokens and no marker exists. A session with no tokens yet is never flagged, so a new session does not flash a false alarm.
- Per-session state files older than 30 days are removed by the same hook; the gauge-offer counter is kept.
- Documented in the README install section and the troubleshooting page, because users without the status line cannot see the indicator.

## Consequences
- Users of the gauge see the problem at a glance and the fix in the same line.
- Users without the gauge rely on the documentation; the plugin cannot do more, because nothing it ships loads into a session that did not load it.
- One more small file per session, mode `600`, pruned after 30 days.

## Evidence
Tests: "no sign of the hooks in a session with tokens: status line says guard OFF", "after the SessionStart hook ran, no guard OFF", "after a prompt (for example after /reload-plugins) no guard OFF", "a session with no tokens yet is not flagged", "old per-session files are removed", "the gauge offer counter is kept". A real session wrote the marker (mode `600`) on 2026-11-09.
