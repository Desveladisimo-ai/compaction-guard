<p align="center">
  <img src="assets/header.svg" alt="Compaction Guard: you decide when Claude Code compacts" width="720"><br><br>
  <a href="https://github.com/Desveladisimo-ai/compaction-guard/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/Desveladisimo-ai/compaction-guard/ci.yml?branch=main&amp;label=CI" alt="CI status" height="20"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/Desveladisimo-ai/compaction-guard" alt="MIT license" height="20"></a>
  <a href="https://github.com/Desveladisimo-ai/compaction-guard/releases"><img src="https://img.shields.io/github/v/release/Desveladisimo-ai/compaction-guard" alt="Latest release" height="20"></a>
  <br>
  <img src="https://img.shields.io/badge/Claude%20Code-plugin-3fc6ab" alt="Claude Code plugin" height="20">
  <img src="https://img.shields.io/badge/POSIX%20sh-no%20dependencies-1f4788" alt="POSIX sh, no dependencies" height="20">
  <a href="CONTRIBUTING.md"><img src="https://img.shields.io/badge/PRs-welcome-3fc6ab" alt="PRs welcome" height="20"></a>
</p>

<p align="center">
  <a href="#install">Install</a> •
  <a href="#what-it-does">What it does</a> •
  <a href="#what-runs-on-your-machine">What runs on your machine</a> •
  <a href="#optional-configuration">Optional configuration</a> •
  <a href="#limits">Limits</a> •
  <a href="#uninstall">Uninstall</a>
</p>

Claude Code compacts a long conversation automatically, replacing it with a summary, and since October 2026 it can also do so after you have been idle. Whatever the summary leaves out is gone, so work can be re-read, repeated or done wrong afterwards. **Compaction Guard makes compaction a decision you take**: it blocks automatic compaction while there is room, shows you and the assistant where the context stands, and hands the work to a fresh session when it is really time to change.

## Install

```
claude plugin marketplace add Desveladisimo-ai/compaction-guard
claude plugin install compaction-guard@compaction-guard-marketplace
```

Start a new Claude Code session afterwards. That is all: it works with its defaults, with no setup. Requirements: Claude Code, and a POSIX shell with `sed`, `grep`, `awk`, `date`, `cksum` and `find`, which macOS and Linux have by default. Native Windows is not tested.

## What it does

With the defaults:

- **Blocks automatic compaction** (including idle compaction) while the context is below 95% of the window. Manual `/compact` is never blocked.
- **Tells the assistant where the context stands**: a line at every 100k tokens, a warning at 70% and an alert at 85%, each with an instruction to check whether the next piece of work still fits.
- **Hands work to a new session.** When the check says to change session, the `wrap-up` skill shows what it will save, waits for your go, and writes a handoff. The next session in that project receives it by itself, announces it and continues from its next step, with no message from you (interactive sessions only).
- **Optional gauge.** The `status-line` skill adds a line such as `ctx 33%  333k/1000k  left 667k` to your status line, after asking. The plugin works without it.

### Is this better than the built-in switches?

Not always. If you only want automatic compaction off, Claude Code has simpler options: `"idleCompaction": false` for the idle case, and `autoCompactEnabled: false` or the `DISABLE_AUTO_COMPACT=1` environment variable for all of it. In our test with auto-compact off and a small window, the context kept growing with no warning at all. What this plugin adds over the switches is the visible gauge, a warning the assistant itself sees, a rule for when to change session, and the wrap-up and handoff procedure.

## What runs on your machine

Everything is plain shell scripts in [`plugins/compaction-guard/scripts`](plugins/compaction-guard/scripts). Nothing is sent over the network.

| Piece | When it runs | What it does |
|---|---|---|
| `PreCompact` hook (automatic compactions only) | Before Claude Code compacts on its own | Blocks it below the ceiling, records a small flag file, and shows a desktop notification where `osascript` (macOS) or `notify-send` (Linux) exists |
| `UserPromptSubmit` hook | At every message you send | Reads the transcript's token usage and adds the warning lines to the assistant's context |
| `SessionStart` hook (new session and `/clear`) | When a session starts | Loads a pending handoff for the project, if there is one |
| `handoff-announce` monitor | The whole session | Checks once a second whether a handoff was just loaded, and if so wakes the assistant to announce it. This is the "1 monitor" Claude Code shows in its status bar |
| `wrap-up` and `status-line` skills | Only when run | Write the handoff, or show the status line setting. Neither edits your settings without your yes |

Files it writes, all under `~/.claude/compaction-guard/` (or `$COMPACTION_GUARD_HOME`): `state/` (flags and counters), `handoffs/<project>/` (pending and archived handoffs) and `guard.log`. Handoffs older than 14 days are ignored. Handoffs are written by the assistant, so read one before you share it: it can contain what you worked on.

## Optional configuration

Nothing here is required. The defaults above work out of the box, and most people never touch these. If you want different thresholds, export any of these environment variables (for example in your shell profile) before starting Claude Code:

| Variable | Default | Meaning |
|---|---|---|
| `COMPACTION_GUARD_CEILING_PCT` | 95 | Automatic compaction is blocked below this percent of the window |
| `COMPACTION_GUARD_WARN_PCT` | 70 | Warning threshold |
| `COMPACTION_GUARD_ALERT_PCT` | 85 | Alert threshold |
| `COMPACTION_GUARD_STEP_TOKENS` | 100000 | A context line is added every this many tokens |
| `COMPACTION_GUARD_HANDOFF_DAYS` | 14 | Handoffs older than this are ignored |
| `COMPACTION_GUARD_HOME` | `~/.claude/compaction-guard` | Where state and handoffs live |

## Limits

Stated plainly, so you can decide:

- Tested on macOS, Ubuntu and Alpine (the test suite passes on all three). Native Windows is not tested.
- What you see when a hook blocks a compaction in the VS Code and Desktop clients was not observed; the terminal and headless behavior were.
- Whether the hook runs for idle compaction in every client was observed only in the terminal.
- What happens at the true limit of the window, with compaction blocked, was not tested.
- The warnings and the gate depend on the token counts in Claude Code's transcript. If that format changes and the size cannot be read, the hook fails open: compaction is allowed and the warnings stay silent, so a broken gate never traps a session. Each such case is written to `guard.log`.

## Uninstall

```
claude plugin uninstall compaction-guard
claude plugin marketplace remove compaction-guard-marketplace
```

Your handoffs and state stay in `~/.claude/compaction-guard/` until you delete that folder.

## Documentation

- [Timeline](docs/timeline.md): what changed in Claude Code's compaction and when, with sources.
- [Design](docs/design.md): why a plugin and not a skill, what a plugin can and cannot do.
- [Decisions](docs/decisions.md): each design decision, what was verified and what was tested.
- [Sources](docs/sources.md): every source, with its retrieval date.

## Development

```
sh tests/run-tests.sh                                              # 59 checks
shellcheck -x -P SCRIPTDIR -s sh plugins/compaction-guard/scripts/*.sh
claude plugin validate ./plugins/compaction-guard
claude plugin validate .
```

CI runs all of this on every push. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © Francisco Felix
