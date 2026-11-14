# Changelog

All notable changes to this project are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [0.1.7] - 2026-11-12

### Fixed
- The same folder reached through a symbolic link (on macOS `/tmp` and `/private/tmp`, or a linked project folder) had a different handoff key depending on the spelling, so a handoff written from one spelling was not found from the other. The key is now made from the physical path everywhere (the wrap-up, the session start, the monitor). A handoff saved under the old key by a folder that was opened through a link is not found after the update; it can be moved by hand, and a folder opened by its physical path is not affected (closes finding 7 of the [audit](docs/security/audit-2026-11-10.md)).

### Changed
- The test suite has 144 checks (2 new, for the symbolic link). The 0.1.6 announcement for a handoff that waits on the user was seen in a real interactive session, and read as designed (reported by the maintainer, 2026-11-12).

## [0.1.6] - 2026-11-12

### Fixed
- A handoff whose next step waits on the user (an approval, an answer, a condition such as "if the user says merge") was announced with "The previous session left a handoff with nothing to continue.", although the handoff was delivered and held real state. The assistant now says "Continuing from the handoff: <goal>. Waiting on you: <what is pending>. Say go, or tell me something else." and waits. The "nothing to continue" line is kept for a handoff with no work done and nothing open. A "Waiting on the user" section alone does not make a handoff a waiting one: a concrete next step still starts ([ADR 0013](docs/adr/0013-announce-a-wrap-up-with-nothing-to-hand-over.md)). Found in the maintainer's own sessions; no handoff was lost, only the first line was wrong (checked against the session transcripts).

- Two monitors in one folder could both announce the same handoff on some Linux hosts. 0.1.5 claimed the notice with `mkdir`; on a Linux 7.0 Azure CI runner two `mkdir` of one path both succeeded in 63 of 100 tries (hard link, symlink, noclobber and rename: 0 of 100, also on macOS and Windows Git Bash). The claim now needs both a `mkdir` lock and a rename of the notice to a name of the process's own, because a plain `mv` was not exclusive in Git Bash on Windows (2 of 5 runs) either; a double claim needs both to fail on the same host ([ADR 0006](docs/adr/0006-automatic-pickup-by-monitor.md)).

### Changed
- The test suite has 142 checks (2 new, for the instruction text). The behaviour itself was checked with a real Claude Code client on four handoffs: waiting on answers, conditional on a merge, a concrete step beside an unrelated wait, and nothing queued.

## [0.1.5] - 2026-11-11

### Fixed
- With two Claude Code sessions open in the same project folder (for example the one that ran the wrap-up, and a new one), the monitor of the old session could take the "handoff loaded" notice meant for the new one, and wake the old session to carry on from a handoff it never received. A notice is now claimed by one monitor only (the claim is a `mkdir`, which only one process can win, also in Git Bash), and the line says to act on it only if the session's context contains the handoff text. The new session still receives the handoff in its context and acts on it at its first message; which session is woken before the first message depends on timing, because Claude Code does not document a session identifier a monitor can read ([ADR 0006](docs/adr/0006-automatic-pickup-by-monitor.md), [audit](docs/security/audit-2026-11-10.md)).
- A notice left behind by a session that has no monitor (for example `claude -p`) no longer wakes a later, unrelated session: notices older than a minute are removed without a word.
- The notice file is written through a new file and a move, so a link planted at its path is never written through.
- A wrap-up run after the assistant had changed into a subfolder wrote the handoff under that subfolder's name, so the next session in the project found nothing (the Bash tool does not export `CLAUDE_PROJECT_DIR`; checked 2026-11-10). The session start now records its folder, and `handoff-path.sh` walks up from the current folder to the nearest recorded one.
- The delimiters around an injected handoff or wrap-up note carry a random per-run token, so text inside the note cannot imitate the closing line.

### Changed
- The test suite has 140 checks (8 new).
- SECURITY.md and the README state the trust boundary: the plugin protects against other OS accounts, not against someone using yours.

## [0.1.4] - 2026-11-10

### Fixed
- A handoff written by the wrap-up skill could be created readable by other users (mode 644): the assistant writes it with its editor tool, which ignores the plugin's `umask 077`. The skill now ends the write with `chmod 600`, and the session start tightens `pending.md` to 600 before it reads or archives it, so a skipped step cannot leave it open. The folder was already `700`, so other users could not reach the file, but the documented guarantee (files `600`) now holds ([ADR 0003](docs/adr/0003-state-outside-the-repository-private.md)).

### Changed
- The test suite has 132 checks (1 new: a handoff created as 644 ends 600).

## [0.1.3] - 2026-11-09

### Fixed
- A new session after a wrap-up that had nothing to hand over started with no message, which looked the same as a handoff that failed to save. The wrap-up now records that it found nothing to continue (`no-handoff.sh`), and the next session in the project says so in one line, with the reason, and the monitor wakes the assistant to say it before the user types ([ADR 0013](docs/adr/0013-announce-a-wrap-up-with-nothing-to-hand-over.md)). A pending handoff still wins over the note, and a session that never ran a wrap-up still starts silently.

### Changed
- The test suite has 131 checks (30 new, for the note and for the scripts being executable).

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
- A test suite (101 checks) that passes on macOS, Ubuntu 24.04, Alpine 3.20 and Windows under Git Bash, ShellCheck-clean scripts, and CI that runs both plus `claude plugin validate`.

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
