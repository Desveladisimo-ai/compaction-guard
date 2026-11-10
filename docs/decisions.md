# Verification log and original decision table (2026-11-06)

The decisions are now recorded one by one as [architecture decision records](adr/README.md). This page keeps the original table, the facts verified about Claude Code's hooks, and the dated test results.

Taken by the maintainer after the design discussion. Each decision names its source or says it is a product choice.

## Goal

Install in one step, work with defaults, no setup. Detection is automatic. When it is time to change session, the assistant says why, saves what must outlive the session, and the next session continues by itself. The user never copies a handoff message.

## Decisions

| # | Decision | Reason |
|---|---|---|
| D1 | Block automatic compaction below a hard ceiling of 95% of the window; allow it at or above | The hooks reference says that blocking a compaction triggered to recover from a context-limit error makes the request fail, and the hook input has no field that tells the two cases apart. A ceiling keeps a session from getting stuck. The user is warned at 70% and 85% first |
| D2 | The handoff lives outside the repository, in `~/.claude/compaction-guard/handoffs/<project>/` (changed during the build from the plugin data folder) | No git noise, nothing private committed by accident. The same root holds the state shared with the optional status line, which runs outside the plugin and cannot see the plugin data folder, and it survives plugin updates and uninstalls. The message shows the path |
| D3 | The wrap-up writes only the handoff and durable memory entries | It never edits code, docs or settings. Stale documents it notices are listed for the user |
| D4 | The status line is offered once and never forced | A plugin cannot set the main status line (only `agent` and `subagentStatusLine` take effect in plugin settings). Warnings work without it |
| D5 | Install is one command | `/plugin install compaction-guard --marketplace <owner>/<repo>`, which the plugin validator reports as working in one step on Claude Code 2.1.275 or later; the older two-step form (`claude plugin marketplace add`, then `claude plugin install <name>@<marketplace>`) is documented. Hooks are active with defaults after install |
| D6 | A new session finds the handoff itself | A SessionStart hook adds the pending handoff to the context on `startup` and `clear`; `/clear` counts as a new session. The assistant announces it in one line and carries on, and the user can interrupt |
| D7 | Two steps, with the user's go in between. First the assistant shows why now, what the wrap-up will save (handoff, memory entries, stale documents it noticed, listed and not changed) and waits for a yes or for the user to run `/compaction-guard:wrap-up`; only then does it write. Added 2026-11-06 after the first build saved first and reported afterwards | Saving ends the session's work, so the user decides. |
| D7a | The assistant decides "end of a feature, clear boundary" using the gate rule; the hook only supplies facts and the instruction | A hook cannot tell that a feature is complete. The skill defines the rule: if the next piece, times 1.5 plus a wrap-up reserve, fits in what is left, keep working with no wrap-up; otherwise wrap up |
| D8 | A handoff has a status (pending, consumed, discarded) and expires after 14 days | So an unrelated later session starts clean; one phrase from the user discards it |

## The message the user sees when a move is advised

Fixed format, produced by the wrap-up skill:

1. Why: what just finished, why the next task is a clear boundary, the context size and the estimate for the next piece.
2. What was saved: the handoff (with its path) and the memory entries.
3. How to continue: type `/clear` or start a new session; it continues from the handoff on its own.

## Verified on 2026-11-06 (official hooks reference and a local test)

- PreCompact's `auto` matcher fires both for compaction at the window and for idle compaction (hooks reference). This matches the local observation.
- Exit code 2 blocks it. If it was proactive, the conversation continues uncompacted; if it was a recovery from an API context-limit error, the request fails (hooks reference).
- A PreCompact hook's `systemMessage` is discarded, so a blocked automatic compaction shows the user nothing by itself. Warnings travel through the prompt hook; an operating-system notification is the user-visible signal.
- SessionStart receives `source` (`startup`, `resume`, `clear`, `compact`, `fork`), and what the hook prints becomes context before the first prompt. UserPromptSubmit stdout is also added as context; its default timeout is 30 seconds.
- Context size from the transcript alone: the last assistant message's usage (input, cache read, cache creation) gave 623,718 tokens against 628,107 from the status line at a slightly later moment, a difference under 1%; reading the last 400 KB of the transcript took 16 milliseconds. So a prompt hook can measure context without a status line.

## Not verified, to settle before building

1. **Window size without a status line.** The transcript gives tokens used, not the window. A 200K window and a 1M window need different percentages. Plan: use the status line value when it exists, then the auto-compact window setting or variable when set, then a small table by model, and let the user override with an option. A wrong guess would warn too early or too late, so this needs a test.
2. Dependencies on Linux and Windows (the first local scripts used `jq` and `osascript`). Settled afterwards: POSIX shell without `jq`, tested on Ubuntu and Alpine on 2026-11-09; Windows is still untested.
3. What the interactive terminal shows when a hook blocks; VS Code and Desktop behavior.
4. How the wrap-up skill saves durable memory when the user has no memory feature enabled (it should skip that part and say so).

## Build and test results (2026-11-06)

Version 0.1.0 of the plugin is in `plugins/compaction-guard`. Hooks are POSIX shell and need only `sed`, `grep`, `tail`, `awk`, `date`, `cksum` and `find`. Windows without a POSIX shell is not supported yet.

- `claude plugin validate` passes for the plugin and the marketplace. Warnings only at that point: no author, no license, no icon (all three were added afterwards).
- `sh tests/run-tests.sh`: 43 of 43 passed at version 0.1.0 (90 of 90 at 0.1.1) (context size, window size, blocking and the ceiling, warnings, the handoff flow, the status line). The tests found one real bug, in the status line when it receives no data; fixed.
- End to end with the real client, a temporary home and throwaway projects:
  1. **Handoff.** A new session received a pending handoff by itself, opened with the one-line confirmation, quoted its next step and what was waiting on the user, and the handoff was archived.
  2. **Wrap-up skill.** The skill wrote a handoff with every section, saved a memory entry, said what was not verified (the user's claim of passing tests was recorded as not re-run) and gave the three-part message.
  3. **Real automatic compaction** with the window set to the 100,000 minimum: the attempt at 71% (71,295 tokens) was blocked, the attempt at 93% (93,403) was blocked, and the attempt at 115% (115,536) was allowed because it is above the 95% ceiling. The context then dropped to 50,368 and the session finished all six file reads, so it did not get stuck. The first run of this test did not reach compaction because the model stopped to ask a question; the instruction was made explicit and the test rerun, and that is the result reported.
  4. **Warning to the assistant.** On the next message the assistant received the block notice and a context warning with the gate-check instruction.
- Side effect found and cleaned: tests that run `claude` in a temporary project folder leave a folder for it under `~/.claude/projects`. They were removed by exact path.

## Not tested

- ~~The plugin installed from a marketplace~~ Tested on 2026-11-09: installed into a fresh Claude Code config from a local marketplace and from the git remote; the scripts arrive executable and the hooks run from the installed copy. Still untested: the exact `owner/repo` shorthand, which needs the repository to be public.
- What the interactive terminal, VS Code and Desktop show on a block; Linux and Windows.
- The 1,000,000-token window behavior of the ceiling on a real long session (the logic is covered by the unit tests; the live test used a 100,000 window).
- The status line skill (written, not run).

### Two-step wrap-up, tested 2026-11-06 with the real client

With a context alert in front of it and no go from the user, the assistant produced the three-part message (why now, what will be saved, the user's call), used no tools and wrote nothing. After the reply "yes" it ran the wrap-up skill, wrote the handoff and a memory entry, listed what it had not verified, and said it was safe to type `/clear` or open a new session. Note: the handoff also reflected the tester's own global instructions, so a handoff carries the user's own rules as well as the plugin's.

## Starting a new session from the handoff immediately (experiment, 2026-11-07)

Question: can a new session start from the handoff with no message from the user? Findings:
- `initialUserMessage` (a SessionStart hook output) exists but the documentation limits it to non-interactive `-p` mode, so it cannot do it in the terminal.
- A plugin **monitor** can. The docs describe a monitor as a background command started with the session, whose output "reaches Claude as notifications". Run in a real interactive session (a pseudo-terminal, nobody typing), a throwaway plugin whose monitor printed one line produced an assistant reply 8.7 seconds after the start. Each monitor event also ran the UserPromptSubmit hook.
- Trap found: when a monitor process ends, Claude Code reports "stream ended" to the assistant and a pointless turn starts. So the monitor never ends; it polls once a second for the whole session.
- Built in 0.1.1: the SessionStart hook leaves a marker when it loads a handoff; `scripts/announce-monitor.sh` (declared in `monitors/monitors.json`) prints one line when it sees the marker, which wakes the assistant, which announces the handoff and carries on from its Next step.
- Tested in a real interactive session on Claude Code 2.1.319, macOS: (a) a pending handoff at session start: the assistant announced at 6.7 seconds and acted on the Next step with no input; (b) the exact flow, an idle session, a handoff appears, the user types `/clear`: the assistant announced 4.3 seconds later and acted, with no message from the user.

Limits: interactive sessions only (monitors do not start with `-p`); the monitor runs with the user's full permissions outside the sandbox (documented), and this one only reads a marker file; VS Code, the desktop app, Linux and Windows are untested; on Bedrock, Vertex, Foundry or with telemetry off, monitors need Claude Code 2.1.310 or later (documented).

