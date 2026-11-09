# 0002: Block automatic compaction below a ceiling, allow it above

- Status: Accepted
- Date: 2026-11-06

## Context
Claude Code's `PreCompact` hook can block a compaction (exit code 2). The hooks reference says that blocking a compaction triggered to recover from a context-limit error makes the request fail, and the hook input has no field that tells the two cases apart. A gate that always blocks could leave a session stuck.

## Decision
Block automatic compactions while the context is below 95% of the window; allow them at or above. Manual `/compact` is never blocked. The ceiling is configurable (`COMPACTION_GUARD_CEILING_PCT`). The user is warned at 70% and 85% first, so the decision is theirs before the ceiling is reached.

## Consequences
- A user who never decides gets Claude Code's own compaction at the ceiling, not a stuck session. The README says so.
- The window size is not in the transcript. The order of sources is: the value written by the optional status line, the `CLAUDE_CODE_AUTO_COMPACT_WINDOW` variable, then an assumption (200k, or 1M once the context is past 200k), which the warnings disclose.

## Evidence
Real client with a 100,000-token window: attempts at 71% and 93% were blocked, the attempt at 115% was allowed and the session finished (see [the test log](../decisions.md)). Unit tests cover the ceiling and the window sources.
