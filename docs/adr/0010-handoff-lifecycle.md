# 0010: Handoff lifecycle: archive after use, expire, prune

- Status: Accepted
- Date: 2026-11-06 (pruning added 2026-11-09)

## Context
An unrelated later session must start clean, but a used handoff should not be destroyed: the user may want to look back at it.

## Decision
A pending handoff is moved to `archive/` when it is loaded, never deleted at that point. A pending handoff older than 14 days is ignored (`COMPACTION_GUARD_HANDOFF_DAYS`). Archived handoffs are removed after 90 days. One phrase from the user discards a pending handoff.

## Consequences
Nothing is lost when a handoff is picked up; the folder does not grow without bound; the guard log is capped at 200 KB.

## Evidence
Tests: "handoff is archived", "an expired handoff is not injected", "an old archived handoff is removed", "the log is cut when it grows past 200 KB".
