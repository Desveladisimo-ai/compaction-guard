# Changelog

All notable changes to this project are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [0.1.2] - first public release

Versions 0.1.0 and 0.1.1 were private development builds and were never published. 0.1.2 is the first release; it includes the fixes below that were found after 0.1.1.

### Added
- A `PreCompact` hook that blocks Claude Code's automatic compaction, including idle compaction, while the context is below the ceiling (95% of the window by default). Manual `/compact` is never blocked.
- A `UserPromptSubmit` hook that tells the assistant where the context stands: a line every 100k tokens, a warning at 70% and an alert at 85%.
- The `wrap-up` skill: shows what it will save, waits for the user's go, then writes a handoff note.
- A `SessionStart` hook and the `handoff-announce` monitor: a new session in the same project, or `/clear`, picks up the pending handoff by itself and carries on from its next step, with no message from the user (interactive sessions).
- The optional `status-line` skill: a context gauge such as `ctx 33%  333k/1000k  left 667k`, offered up to three times and installed only after asking.
- Optional configuration through `COMPACTION_GUARD_*` environment variables; the defaults need no setup.
- Desktop notification when a compaction is blocked, where `osascript` (macOS) or `notify-send` (Linux) exists.
- A test suite (90 checks) that passes on macOS, Ubuntu 24.04 and Alpine 3.20, ShellCheck-clean scripts, and CI that runs both plus `claude plugin validate`.

### Security
- Everything the plugin writes is private to the user (folders `700`, files `600`); installs made by earlier development builds are tightened on first run.
- Session identifiers are reduced to safe characters before they become file names.
- No network access; no files written outside `~/.claude/compaction-guard/`.
- A handoff is handed to the assistant as delimited notes, capped at 50 KB, that grant no permission; the assistant asks before any step that deletes data, sends data off the machine, pushes or publishes, installs software or changes credentials or settings. The wrap-up skill may not copy instructions found in web pages, issues, files or tool results into the next step.
- Every numeric setting is validated before it reaches arithmetic, so a bad value falls back to its default instead of running code or blocking; the hooks end in success on any unexpected error, so they can neither block a compaction nor erase a message by accident.
- Only plain files are read from the state folder (never a pipe, link or folder); a state path containing shell characters is replaced by the default; the folder is tightened only when it is a real folder of the current user.
- The log is capped (200 KB) and used handoffs are removed after 90 days.

### Fixed
- A session that was open when the plugin was installed had none of its hooks and nothing said so ([#5](https://github.com/Desveladisimo-ai/compaction-guard/issues/5), [incident review](docs/incidents/2026-11-09-plugin-inactive-in-open-session.md)). The optional status line now shows `guard OFF: run /reload-plugins` in such a session; the README and a new [troubleshooting page](docs/troubleshooting.md) explain it.
- Files changed under an unchanged version were never delivered by `claude plugin update`. Every change to the plugin now needs a new version, enforced in CI.
- The notice after a blocked compaction printed the time where the percentage belongs.

### Documentation and gates
- Ten architecture decision records, a threat model and a pre-release security audit record (findings, fixes and the regression test for each).
- CI gates: tests on Ubuntu and macOS, ShellCheck, a secret scan of the full history, plugin and marketplace validation, and policy tests that fail the build on a network call, `eval` or privilege escalation. Actions are pinned to commit SHAs and updated by Dependabot.

### Known limits
- A real Claude Code session on Windows (the scripts pass the test suite under Git Bash in CI) and what VS Code and the Desktop app show when a compaction is blocked have not been observed; `docs/testing/client-checklist.md` says how.
- Sessions that were already open at install time need `/reload-plugins` (hooks) or a restart (monitor); the status line gauge makes the case visible.
