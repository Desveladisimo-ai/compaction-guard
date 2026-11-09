# Changelog

All notable changes to this project are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [0.1.1] - first public release

### Added
- A `PreCompact` hook that blocks Claude Code's automatic compaction, including idle compaction, while the context is below the ceiling (95% of the window by default). Manual `/compact` is never blocked.
- A `UserPromptSubmit` hook that tells the assistant where the context stands: a line every 100k tokens, a warning at 70% and an alert at 85%.
- The `wrap-up` skill: shows what it will save, waits for the user's go, then writes a handoff note.
- A `SessionStart` hook and the `handoff-announce` monitor: a new session in the same project, or `/clear`, picks up the pending handoff by itself and carries on from its next step, with no message from the user (interactive sessions).
- The optional `status-line` skill: a context gauge such as `ctx 33%  333k/1000k  left 667k`, offered up to three times and installed only after asking.
- Optional configuration through `COMPACTION_GUARD_*` environment variables; the defaults need no setup.
- Desktop notification when a compaction is blocked, where `osascript` (macOS) or `notify-send` (Linux) exists.
- A test suite (66 checks) that passes on macOS, Ubuntu 24.04 and Alpine 3.20, ShellCheck-clean scripts, and CI that runs both plus `claude plugin validate`.

### Security
- Everything the plugin writes is private to the user (folders `700`, files `600`); installs made by earlier development builds are tightened on first run.
- Session identifiers are reduced to safe characters before they become file names.
- No network access; no files written outside `~/.claude/compaction-guard/`.

### Known limits
- Native Windows is not tested.
- What VS Code and the Desktop app show when a compaction is blocked, and whether the hook fires for idle compaction there, has not been observed.
