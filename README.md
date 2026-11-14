<p align="center">
  <img src="assets/header.svg" alt="Compaction Guard: you decide when Claude Code compacts" width="720"><br><br>
  <a href="https://github.com/Desveladisimo-ai/compaction-guard/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/Desveladisimo-ai/compaction-guard/ci.yml?branch=main&amp;label=CI" alt="CI status" height="20"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/Desveladisimo-ai/compaction-guard?style=flat" alt="MIT license" height="20"></a>
  <a href="https://github.com/Desveladisimo-ai/compaction-guard/releases"><img src="https://img.shields.io/github/v/release/Desveladisimo-ai/compaction-guard" alt="Latest release" height="20"></a>
  <br>
  <img src="https://img.shields.io/badge/Claude%20Code-plugin-3fc6ab" alt="Claude Code plugin" height="20">
  <img src="https://img.shields.io/badge/POSIX%20sh-no%20dependencies-1f4788" alt="POSIX sh, no dependencies" height="20">
  <a href="CONTRIBUTING.md"><img src="https://img.shields.io/badge/PRs-welcome-3fc6ab" alt="PRs welcome" height="20"></a>
</p>

<p align="center">
  <a href="#why-compaction-guard-exists">Why it exists</a> •
  <a href="#install">Install</a> •
  <a href="#what-it-does">What it does</a> •
  <a href="#what-runs-on-your-machine">What runs on your machine</a> •
  <a href="#optional-configuration">Optional configuration</a> •
  <a href="#supported-and-tested">Supported and tested</a> •
  <a href="#uninstall">Uninstall</a>
</p>

Claude Code compacts a long conversation automatically, replacing it with a summary, and since October 2026 it can also do so after you have been idle. Whatever the summary leaves out is gone, so work can be re-read, repeated or done wrong afterwards.

**Compaction Guard keeps your place, automatically.** When it is time to change session, it writes a short handoff note (you say yes once), and the next session picks it up by itself: type `/clear` or open a new session, and the assistant tells you where you were and carries on from the next step, with no message from you (interactive sessions). Until the context is nearly full, it also blocks Claude Code's automatic compaction, so nothing is summarized away behind your back, and it warns you and the assistant at 70% and 85% so you choose when to change.

## Why Compaction Guard exists

In October 2026 Claude Code began compacting idle conversations on its own. A long session left alone for about an hour is replaced by a summary shortly before the prompt cache expires, so that the next message does not have to reprocess everything. Compaction is a destructive change: the conversation you built is replaced by a summary, and that cannot be undone inside the session. This one arrived enabled by default, with no warning before it acted. The only notice, which says how to turn it off, comes afterwards.

I saw what that means in my own sessions. Claude Code forgot which of my GitHub accounts we were using on a project I had just started. In another session it stopped in the middle of a set of planned actions and asked me for information it had held a moment before.

Nobody had asked, nobody had warned me, and I had not chosen any of it.

Then I found I was not alone: other users were running into the same thing and saying so. That is when I decided to stop losing information to a destructive feature I had not chosen. I wanted control over when compaction happens, and I wanted what is relevant and important saved automatically before switching to a new session, together with a handoff from the previous session that the new one picks up on its own.

Compaction Guard is built for that gap.

## Install

```
claude plugin marketplace add Desveladisimo-ai/compaction-guard
claude plugin install compaction-guard@compaction-guard-marketplace
```

Start a new Claude Code session afterwards. That is all: it works with its defaults, with no setup.

**Sessions that were already open when you installed it do not have the plugin**: Claude Code loads plugins when a session starts. In an open session, run `/reload-plugins` to switch on the hooks (the handoff monitor needs that session to be restarted), or restart it. `claude plugin list` shows the plugin as installed either way, so check a long-running session before relying on it.

Requirements: Claude Code, and a POSIX shell with `sed`, `grep`, `awk`, `date`, `cksum` and `find`, which macOS and Linux have by default. On native Windows, install [Git for Windows](https://git-scm.com/downloads/win): Claude Code runs hooks in Git Bash there, and the monitor needs it. WSL works like Linux.

## What it does

With the defaults:

- **Saves your place and picks it up in the next session, for you.** When the check says it is time to change session, the `wrap-up` skill shows what it will save and waits for your go. It then writes a *handoff*, a short note with the goal, the state, the decisions and the next step. You never write, copy or load one: the next session in that project finds it, announces it in one line and carries on from its next step, with no message from you (interactive sessions only). If the wrap-up finds nothing to continue, it saves no handoff but leaves a one-line note, and the next session says so and why, so a quiet start is never a handoff that went missing. The only thing you decide is when to change session. A handoff is handed over as notes, not as instructions: the assistant does not carry on by itself with a step that deletes data, sends data off your machine, pushes or publishes, installs software or changes credentials or settings. It names the step and asks first.
- **Blocks automatic compaction** (including idle compaction) while the context is below 95% of the window. Manual `/compact` is never blocked.
- **Tells the assistant where the context stands**: a line at every 100k tokens, a warning at 70% and an alert at 85%, each with an instruction to check whether the next piece of work still fits.
- **Optional gauge.** The `status-line` skill adds a line such as `ctx 33%  333k/1000k  left 667k` to your status line, after asking. It also shows `guard OFF: run /reload-plugins` in a session that has not loaded the plugin (see [troubleshooting](docs/troubleshooting.md)). The plugin works without it.

### You decide, with a safety net

Nothing is saved or ended without your go, and nothing is compacted behind your back while there is room. If you never decide, the plugin does not hold the line forever: at the ceiling (95% of the window by default) it steps aside and lets Claude Code compact, because blocking a compaction that Claude Code needs in order to keep working would make the next request fail. The warnings at 70% and 85% exist so you decide before that point.

### Is this better than the built-in switches?

Not always. If you only want automatic compaction off, Claude Code has simpler options: `"idleCompaction": false` for the idle case, and `autoCompactEnabled: false` or the `DISABLE_AUTO_COMPACT=1` environment variable for all of it. In our test with auto-compact off and a small window, the context kept growing with no warning at all. What this plugin adds over the switches is the visible gauge, a warning the assistant itself sees, a rule for when to change session, and the wrap-up and handoff procedure.

## What runs on your machine

Everything is plain shell scripts in [`plugins/compaction-guard/scripts`](plugins/compaction-guard/scripts). Nothing is sent over the network.

| Piece | When it runs | What it does |
|---|---|---|
| `PreCompact` hook (automatic compactions only) | Before Claude Code compacts on its own | Blocks it below the ceiling, records a small flag file, and shows a desktop notification where `osascript` (macOS) or `notify-send` (Linux) exists |
| `UserPromptSubmit` hook | At every message you send | Reads the transcript's token usage and adds the warning lines to the assistant's context |
| `SessionStart` hook (new session and `/clear`) | When a session starts | Loads a pending handoff for the project, if there is one; if the last wrap-up had nothing to hand over, says that instead |
| `handoff-announce` monitor | The whole session | Checks once a second whether a handoff (or a note that there was none) was just loaded, and if so wakes the assistant to announce it. This is the "1 monitor" Claude Code shows in its status bar |
| `wrap-up` and `status-line` skills | Only when run | Write the handoff, or show the status line setting. Neither edits your settings without your yes |

Files it writes, all under `~/.claude/compaction-guard/` (or `$COMPACTION_GUARD_HOME`): `state/` (flags and counters), `handoffs/<project>/` (the notes saved for the next session, the one-line note when a wrap-up had nothing to hand over, and the ones already used) and `guard.log`. Everything is created readable and writable by your user only (folders `700`, files `600`), including on installs made by an earlier version, which are tightened on first run. Handoffs older than 14 days are ignored. A handoff is picked up by the first session opened in that project under your account, so keep your account to yourself ([trust boundary](SECURITY.md#trust-boundary)). Handoffs are written by the assistant, so read one before you share it: it can contain what you worked on.

Like every Claude Code plugin hook and monitor, these scripts run as your user; Claude Code decides that, not the plugin. This plugin asks for nothing beyond that: no network, no files outside `~/.claude/compaction-guard/`, and session identifiers are reduced to safe characters before they become file names. The monitor only reads and deletes a small marker file under `state/` and prints one line; you can read it in [`announce-monitor.sh`](plugins/compaction-guard/scripts/announce-monitor.sh).

## Optional configuration

Nothing here is required. The defaults above work out of the box, and most people never touch these. If you want different thresholds, export any of these environment variables (for example in your shell profile) before starting Claude Code:

| Variable | Default | Meaning |
|---|---|---|
| `COMPACTION_GUARD_CEILING_PCT` | 95 | Automatic compaction is blocked below this percent of the window |
| `COMPACTION_GUARD_WARN_PCT` | 70 | Warning threshold |
| `COMPACTION_GUARD_ALERT_PCT` | 85 | Alert threshold |
| `COMPACTION_GUARD_STEP_TOKENS` | 100000 | A context line is added every this many tokens |
| `COMPACTION_GUARD_HANDOFF_DAYS` | 14 | A saved handoff, or a nothing-to-hand-over note, older than this is not picked up |
| `COMPACTION_GUARD_HOME` | `~/.claude/compaction-guard` | Where state and handoffs live |

## Supported and tested

- **Claude Code:** tested on 2.1.314 to 2.1.319 in the terminal; the 0.1.3 announcement of a wrap-up with nothing to hand over was run on 2.1.322 with `claude -p` (hook and skill), and the 0.1.6 announcement of a handoff that waits on the user was seen in an interactive session; the monitor wake-up and the two-sessions-in-one-folder case have not been seen. Handoff auto-start needs an interactive session, because plugin monitors do not run with `-p`.
- **Operating systems:** macOS, Ubuntu 24.04, Alpine 3.20 and Windows under Git Bash (the test suite passes on all four; on Windows the checks that need file modes or symlinks are skipped). A real Claude Code session on Windows has not been checked yet; see the [client checklist](docs/testing/client-checklist.md).
- **Blocking tested end to end** with a 100,000-token window: attempts at 71% and 93% were blocked, and the attempt at 115% was allowed, as designed. On a real 1,000,000-token window the same logic is covered by the unit tests only.
- **Other clients:** Claude Code fires the same hook events in the terminal, IDE extensions and the Desktop app, and the VS Code extension shares plugins with the CLI (Claude Code documentation). What each client's own interface shows when a block happens has not been observed; the [client checklist](docs/testing/client-checklist.md) says how to check it, and the open verification issues track it.

## How it fails

It is built to never trap a session. If the token count cannot be read (for example if Claude Code changes its transcript format), the hook allows compaction and the warnings stay silent, and the reason is written to `guard.log`. Above the ceiling it also allows compaction, because blocking one that Claude Code needs in order to recover from a full context would make the request fail.

## Updates

Claude Code does not update this plugin by itself unless you turn that on: auto-update is off by default for marketplaces that are not Anthropic's own. You decide:

- **Automatic (recommended if you want fixes without checking):** in a Claude Code session run `/plugin`, open the **Marketplaces** tab, select `compaction-guard-marketplace` and choose **Enable auto-update**. From then on, after you send your first message in a session, Claude Code waits a random time of up to ten minutes, then installs any new version and shows `Plugin updated: compaction-guard · Run /reload-plugins to apply`. The session you are in keeps the old version until you run `/reload-plugins` or restart it; the handoff monitor needs a restart. New sessions load the new version.
- **Manual:** run `claude plugin update compaction-guard@compaction-guard-marketplace`, then `/reload-plugins` in open sessions or restart them. Run it again whenever you want to check; `claude plugin marketplace update` alone only refreshes the list and does not change the installed plugin.
- **Know when a release exists:** on the repository page choose **Watch**, then **Custom**, then **Releases**, and GitHub emails you. Fixes for security problems are marked as such in the release notes.

Every change to the plugin raises its version number ([ADR 0012](docs/adr/0012-version-bump-on-every-plugin-change.md)), which is what makes an update available. The plugin itself makes no network requests, so it cannot check for updates on its own. This section comes from the Claude Code documentation on [keeping plugins updated](https://code.claude.com/docs/en/plugins/install.md); the toggle's wording and the timing are not tested by this project.

## Uninstall

```
claude plugin uninstall compaction-guard
claude plugin marketplace remove compaction-guard-marketplace
```

The plugin saves and picks up handoffs by itself, so there is nothing for you to do with them. The notes and state it already saved stay in `~/.claude/compaction-guard/` after uninstalling; delete that folder only if you want them gone.

## Documentation

- [Timeline](docs/timeline.md): what changed in Claude Code's compaction and when, with sources.
- [Design](docs/design.md): why a plugin and not a skill, what a plugin can and cannot do.
- [Architecture decision records](docs/adr/README.md): each decision, why it was taken and how it was verified.
- [Threat model](docs/security/threat-model.md) and [security audit](docs/security/audit-2026-11-09.md): what is trusted, what was found and fixed, with a regression test for each finding.
- [Troubleshooting](docs/troubleshooting.md) and [incident reviews](docs/incidents/README.md): what to do when it seems inactive, and the blameless reviews of failures, each with its root cause and fix.
- [Quality gates](docs/quality-gates.md): what every change must pass, how to run it locally, and measured hook latency.
- [Verification log](docs/decisions.md): verified facts about Claude Code's hooks and the dated test results.
- [Sources](docs/sources.md): every source, with its retrieval date.

## Development

```
sh tests/run-tests.sh                                              # 142 checks
shellcheck -x -P SCRIPTDIR -s sh plugins/compaction-guard/scripts/*.sh
claude plugin validate ./plugins/compaction-guard
claude plugin validate .
```

CI runs all of this on every push, plus a secret scan of the whole history. See [CONTRIBUTING.md](CONTRIBUTING.md) and the [quality gates](docs/quality-gates.md).

## License

[MIT](LICENSE) © Francisco Felix
