# 0007: Fail open on any error

- Status: Accepted
- Date: 2026-11-09

## Context
A shell arithmetic error exits with status 2. For `PreCompact` that blocks the compaction at any fill level; for `UserPromptSubmit` it blocks and erases the user's message. Settings come from the environment and state files, so values cannot be trusted to be numbers.

## Decision
- Every numeric setting and window size is validated (`num_or`) and falls back to its default when it is not a whole number in range.
- `pre-compact.sh` ends in success on any unexpected error; only the deliberate block exits with 2.
- `prompt.sh` and `session-start.sh` always end in success.
- State files are read only if they are plain files, never a pipe, link or folder, and the handoff is capped at 50 KB.
- If the context size cannot be read, compaction is allowed and the reason goes to `guard.log`.

## Consequences
A broken or hostile setting can disable a protection but can never trap a session, block a message or run code. That is the intended trade: the plugin is a convenience layered over Claude Code, and must never be worse than not having it.

## Evidence
Found by the [security audit](../security/audit-2026-11-09.md) (IR-02, IR-03, IR-04). On the pre-fix scripts under dash, a window file containing `0` and `COMPACTION_GUARD_CEILING_PCT=x` both blocked above the ceiling. Regression tests cover each case.
