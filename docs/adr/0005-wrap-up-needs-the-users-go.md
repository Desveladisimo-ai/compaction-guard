# 0005: The wrap-up needs the user's go

- Status: Accepted
- Date: 2026-11-06

## Context
The first build saved the handoff first and reported afterwards. Saving ends the session's work, so the user, not the assistant, should decide.

## Decision
Two steps. First the assistant says why now, what the wrap-up will save (the handoff, durable memory entries, stale documents it noticed, listed and not changed) and waits. Only after a yes, or after the user runs `/compaction-guard:wrap-up`, does it write. The wrap-up writes only the handoff and memory entries; it never edits code, documents or settings. The gate rule: if the next piece of work, times 1.5 plus a wrap-up reserve, fits in what is left, keep working with no wrap-up.

## Consequences
Nothing is saved or ended without the user. A wrap-up on every check would waste tokens, hence the rule.

## Evidence
Tested with the real client on 2026-11-06: with an alert in front of it and no go, the assistant produced the three-part message and wrote nothing; after "yes" it wrote the handoff and a memory entry ([test log](../decisions.md)).
