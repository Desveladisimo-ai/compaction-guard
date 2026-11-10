# Plugin inactive in a session that was open at install time

- Date: 2026-11-09
- Issue: [#5](https://github.com/Desveladisimo-ai/compaction-guard/issues/5)
- Fixed in: 0.1.2
- Severity: medium. A user lost context to an automatic summary, the thing the plugin prevents. No data was lost beyond what a compaction replaces with a summary.

## Summary
An idle compaction was not blocked in a long-running session. The plugin was installed, enabled and listed as installed, but that session had never loaded it, so none of its hooks ran. Nothing told the user the session was unprotected.

## Timeline (UTC)
| When | What |
|---|---|
| Day 0 | A long-running Claude Code session starts. |
| Day 19, 06:30 | The plugin (0.1.1) is installed at user scope. |
| Days 19 to 20 | Sessions started after the install have their automatic compactions blocked; each block is in `guard.log`. |
| Day 21 | The older session is compacted while idle. There is no `guard.log` line for it. The user notices the compaction and reports it. |
| Day 21 | Investigation: the hook script, run by hand against that session's transcript, blocks correctly (exit 2). `guard.log` has entries only for sessions that began after the install. The documentation says plugins load at session start or on `/reload-plugins`. Root cause confirmed. |
| Day 21 | A second finding: the maintainer's installed copy is a cache pinned to 0.1.1 and lacks later fixes. |

## Root cause
Claude Code loads the set of plugins when a session starts, or when `/reload-plugins` runs; changes made to disk or settings after that do not reach a running session. The older session predated the install by 19 days.

The first explanation offered during the investigation, that the hooks are read at session start, was an inference. It was confirmed against the documentation before being written down here.

## Why it was not caught earlier
1. **The install instructions were incomplete.** They said "Start a new Claude Code session afterwards" and never said that sessions already open do not get the plugin.
2. **The state was invisible.** `claude plugin list` shows disk state, not what a running session loaded. The plugin had no way to show, in a session, that it was not active there.
3. **Versions hid fixes.** Claude Code identifies a release by the manifest `version` string. Files changed under an unchanged version are never delivered by `claude plugin update`, and nothing in the project's process required a bump.
4. **The tests exercised the scripts, not the loading of the plugin into a long-lived session.** That boundary belongs to Claude Code; the plugin can only make it visible.

## What went well
- `guard.log` made the diagnosis quick: every recorded block belonged to a session started after the install.
- The script itself was correct; running it by hand separated "the logic is wrong" from "the logic never ran".
- The installed-copy discrepancy was found because the investigation compared the installed files with the repository instead of assuming they matched.

## Resolution
| Action | Where |
|---|---|
| README install section: sessions open at install time need `/reload-plugins` (hooks) or a restart (monitor); `claude plugin list` cannot tell which case you are in | README |
| Troubleshooting page with the symptom, how to tell, and the fix | [troubleshooting](../troubleshooting.md) |
| The optional status line shows `guard OFF: run /reload-plugins` in a session where the hooks have not run; a `SessionStart` hook for every source and the prompt hook record that they ran | [ADR 0011](../adr/0011-make-an-inactive-session-visible.md) |
| Every change to the plugin needs a new version, enforced in CI | [ADR 0012](../adr/0012-version-bump-on-every-plugin-change.md) |
| Version 0.1.2, so `claude plugin update` delivers the fixes to existing installs | [changelog](../../CHANGELOG.md) |

## What remains outside the project's control
Whether a session has loaded a plugin is decided by Claude Code. A user without the status line gauge still has to know to reload or restart; the README and the troubleshooting page say so, and nothing in the plugin can load itself into a running session.

## Follow-up
- Done 2026-11-09: the exact `owner/repo` install command works for an anonymous user and installs 0.1.2.
- Done 2026-11-10: with 0.1.3, `claude plugin update` moved an install from 0.1.2 to 0.1.3 (scratch git marketplace in an isolated config folder, local path source), and a fresh install from `Desveladisimo-ai/compaction-guard` delivered 0.1.3 with every script executable. Not verified: `claude plugin update` over the GitHub address from an older installed version, which needs the next release.
