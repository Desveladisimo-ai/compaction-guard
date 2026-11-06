# Feature decisions (2026-11-06)

Taken with the owner after the design discussion. Each decision names its source or says it is a product choice.

## Goal

Install in one step, work with defaults, no setup. Detection is automatic. When it is time to change session, the assistant says why, saves what must outlive the session, and the next session continues by itself. The user never copies a handoff message.

## Decisions

| # | Decision | Reason |
|---|---|---|
| D1 | Block automatic compaction below a hard ceiling of 95% of the window; allow it at or above | The hooks reference says that blocking a compaction triggered to recover from a context-limit error makes the request fail, and the hook input has no field that tells the two cases apart. A ceiling keeps a session from getting stuck. The user is warned at 70% and 85% first |
| D2 | The handoff lives outside the repository by default (plugin data folder, keyed by project) | No git noise, nothing private committed by accident. The message shows the path. The folder is deleted with the plugin on uninstall (documented behavior of the plugin data directory) |
| D3 | The wrap-up writes only the handoff and durable memory entries | It never edits code, docs or settings. Stale documents it notices are listed for the user |
| D4 | The status line is offered once and never forced | A plugin cannot set the main status line (only `agent` and `subagentStatusLine` take effect in plugin settings). Warnings work without it |
| D5 | Install is two commands, or one line that runs both | `claude plugin marketplace add <owner>/<repo>` then `claude plugin install <name>@<marketplace>` (documented). Hooks are active with defaults after install |
| D6 | A new session finds the handoff itself | A SessionStart hook adds the pending handoff to the context on `startup` and `clear`; `/clear` counts as a new session. The assistant confirms in one line before acting |
| D7 | The assistant decides "end of a feature, clear boundary" using the gate rule; the hook only supplies facts and the instruction | A hook cannot tell that a feature is complete. The skill defines the rule: if the next piece, times 1.5 plus a wrap-up reserve, fits in what is left, keep working with no wrap-up; otherwise wrap up |
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
2. Dependencies on Linux and Windows (the local scripts use `jq` and `osascript`).
3. What the interactive terminal shows when a hook blocks; VS Code and Desktop behavior.
4. How the wrap-up skill saves durable memory when the user has no memory feature enabled (it should skip that part and say so).
