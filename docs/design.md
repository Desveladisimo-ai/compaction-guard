# Design: a plugin, not a skill

Research from the official documentation (S6, S8, S9), done before the build. The plugin described here exists; what was decided and tested is in [decisions.md](decisions.md).

## Recommendation

Build **one plugin**, not a standalone skill. The protection has to be always on, and only a plugin can ship hooks that run in every session. Put a **skill inside the plugin** for the wrap-up procedure, because that procedure should run only when needed.

## What a plugin can and cannot carry (from the manifest reference, S8)

Can: skills, commands, agents, hooks (`hooks/hooks.json`, merged with settings), MCP servers, background monitors, executables on the `PATH` (`bin/`), user options (`userConfig`, available to hooks as `CLAUDE_PLUGIN_OPTION_<KEY>`).

Cannot: set the main status line. The plugin `settings` block applies only `agent` and `subagentStatusLine`; other keys are dropped. It also cannot set `idleCompaction` or `autoCompactEnabled`. So the visible gauge needs one user step (add a status line command to their settings) or a command in the plugin that guides them through it.

Naming: the validator rejects plugin names starting with `claude-` or `anthropic-` and warns when "claude" is a separate word in the name. This project's name `compaction-guard` is fine.

## Proposed parts

| Part | Mechanism | What it does |
|---|---|---|
| Block | `PreCompact` hook, exit 2 on automatic triggers, exit 0 on manual | stops the compaction nobody asked for; our local test showed it also runs for the idle case |
| Tell the assistant | `UserPromptSubmit` hook, stdout added as context | one line at each 100k tokens, a warning at 70%, a wrap-up alert at 85%, a note after a block |
| Show the person | status line command (user adds it) plus a desktop notification from the block hook | used and remaining tokens, always visible |
| Wrap up | skill `wrap-up` | save decisions to memory, fix stale documents, write the next-session prompt; runs only when the gate says to move |
| Setup | skill or command `setup` | explains the status line step, offers to show the exact settings text; never edits settings without the user's yes |
| Settings | `userConfig` | the thresholds (default 100k step, 70%, 85%) |

The gate rule we used, which the wrap-up skill should state: at the end of each piece of work and at each 100k tokens, estimate the next piece from past pieces; if the estimate times 1.5 plus a wrap-up reserve fits what is left, keep working with no wrap-up; otherwise wrap up and start a new session. A wrap-up on every check wastes tokens.

## Honest comparison with the one-line options

Before installing anything, a person can set `"idleCompaction": false` in their settings, and `autoCompactEnabled: false` or `DISABLE_AUTO_COMPACT=1` to stop automatic compaction altogether (S4, S5). Those are simpler. In our test, with auto-compact off and a small window, the context kept growing with no warning at all and no limit at the configured window (observed 2026-11-02); what happens at the true limit was not tested. The plugin's value over the switches is: a visible gauge, a warning the assistant itself sees, a decision rule, and a wrap-up procedure. The README must say this plainly.

## Distribution

1. Own marketplace: a git repository with `.claude-plugin/marketplace.json` listing the plugin. People run `claude plugin marketplace add <owner>/<repo>` and `claude plugin install compaction-guard@<marketplace-name>` (S9). The marketplace name must not be one of the reserved official names.
2. Later: Anthropic's directory has a submission path (S8, S9); it reads the icon, documentation, support, privacy and terms links from the manifest, so those fields should be filled in.
3. Check before release: `claude plugin validate` on the plugin and the marketplace, in CI.

## Open questions (status 2026-11-09)

1. **Cross-platform scripts.** Resolved for macOS and Linux: the scripts are POSIX `sh` using only `sed`, `grep`, `awk`, `date`, `cksum` and `find`, with no `jq`, and the test suite passes on macOS, Ubuntu 24.04 and Alpine 3.20. Native Windows is not tested.
2. **What the user sees when a hook blocks a compaction** in the interactive terminal, VS Code and Desktop. Only the headless behavior was observed.
3. **Does the hook run for the idle compaction in every client?** Observed in the terminal (twice). VS Code and Desktop received idle compaction in 2.1.314; not tested.
4. **What happens at the true limit** with compaction blocked. Not tested (about 1,000,000 tokens of cost).
5. **A before/after measurement.** The same task with and without an unattended compaction, counting repeated reads and wrong statements. Without it the problem statement stays anecdotal. This is the strongest thing the project could add.

## Ideas, not decided

- **Save lessons when they are learned.** A wrap-up saves at a boundary, but a correction of the form "X means Y" should be saved in the same turn it is given, or it dies with the session. A small instruction in the prompt hook, or a hook on the user's message that spots phrases like "I told you", "again" and "you forgot", could remind the assistant to write the memory entry before continuing. Not designed; not tested.

