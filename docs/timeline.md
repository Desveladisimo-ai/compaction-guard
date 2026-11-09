# What changed, and when

Sources retrieved 2026-11-06. Every row cites a source from [`sources.md`](sources.md). Changelog entries are paraphrased; open the linked file at the version to read the original.

## The short version

Automatic compaction has existed in Claude Code since at least May 2025, with a context-left warning, and a hook that can block it since April 2026. What changed in October 2026 is **idle compaction**: a long conversation left alone for about 54 minutes is now summarized automatically, on by default, so the next message is cheaper to process. The off switch and a notice after the fact exist. A warning before it acts does not, as far as the sources show.

## Timeline

| Date (UTC) | Version | What the changelog says, in short | Source |
|---|---|---|---|
| 2025-05-01 | 0.2.98 | auto-compact was running twice; fixed. Shows auto-compact already existed | S1, S3 |
| 2025-07-10 | 1.0.48 | a `PreCompact` hook was added | S1, S3 |
| 2025-07-11 | 1.0.51 | the auto-compact warning threshold was raised from 60% to 80% (a context warning existed) | S1, S3 |
| 2025-12-10 | 2.0.64 | auto-compacting made instant | S1, S3 |
| 2026-03-14 | 2.1.76 | a circuit breaker stops auto-compaction after 3 failed attempts | S1, S2 |
| 2026-04-01 | 2.1.89 | a loop where context refills right after compacting, three times, now stops with an error | S1, S2 |
| 2026-04-13 | 2.1.105 | a `PreCompact` hook can block compaction (exit code 2 or a block decision) | S1, S2 |
| 2026-10-05 | 2.1.290 | the version from which the `idleCompaction` setting is read | S1, S2 (the entry that names it is in 2.1.299) |
| 2026-10-07 | 2.1.293 | fixed: the assistant sometimes treated its own last actions before a compaction as not yet done, and redid or retracted finished work | S1, S2 |
| **2026-10-14** | **2.1.299** | **idle compaction added in the terminal**: a conversation of 200K or more tokens left idle for about 54 minutes is compacted before the one-hour prompt cache expires, so the next message does not reprocess everything. A new variable sets the 200K minimum and `"idleCompaction": false` turns it off | S1, S2, S3 |
| 2026-10-16 | 2.1.302 | an "Idle compaction" row in `/config` to turn it on or off; the notice shown after an idle compaction now says how to turn it off | S1, S2 |
| 2026-10-26 | 2.1.311 | fixed: stale project instructions and memory files seen right after automatic compaction; compaction now asks once more if the model's reply has no summary in it | S1, S2 |
| 2026-10-30 | 2.1.314 | idle compaction extended to VS Code and the Desktop Code tab; also runs for users with telemetry off and on Bedrock, Vertex, Foundry and gateways; a very large `PreCompact` hook output no longer breaks compaction | S1, S2 |
| 2026-11-03 | 2.1.317 | fixed: very long conversations losing their earlier summary when compaction had to shorten its own request | S1, S2 |
| 2026-11-04 | 2.1.318 | fixed: idle compaction replacing a conversation with a reply that was not a summary | S1, S2 |

The date of the first public mention differs by a few hours between the npm publish time and the GitHub release time (version 2.1.299: published to npm 2026-10-14 00:23, GitHub release 02:49).

## What the documentation says the defaults are

- Automatic compaction is on by default (`autoCompactEnabled`, any settings file) and idle compaction is on by default (`idleCompaction`, boolean, default true), and it needs all of: an interactive client, auto-compact on, the one-hour cache, a conversation past the token threshold, and about an hour of inactivity (S4).
- `DISABLE_AUTO_COMPACT=1` turns off automatic compaction, and idle compaction with it; `DISABLE_COMPACT=1` turns off all compaction including the manual command (S5).
- A `PreCompact` hook runs before compaction. Its matcher values are `manual` and `auto`; exit code 2 blocks the compaction (S6).

## What this does not show

- It does not show why the default was chosen beyond the stated reason, which is avoiding a full reprocessing when the prompt cache has expired. A cost reason is documented; nothing in the sources speaks to intent beyond that.
- It does not show a warning before an idle compaction. The changelog describes a notice after it (2.1.302). Whether any client shows a warning before was not found in the sources; not verified.
- It does not quantify how many people were affected. The public issue tracker has 90 issues since 2026-10-14 with "compact" in the title (S10); they are individual reports and were not verified one by one.

## The argument that the sources support

A default that rewrites a working conversation into a short summary changes what the assistant knows, and the user cannot see in advance what the summary will keep. Anthropic's own fixes in the weeks after the feature (2.1.311, 2.1.317, 2.1.318) are about summaries that were stale, shortened or not summaries at all. A warning before the action, at a level the user sets, is a small change that would let people save state first. This is a request, not an accusation.
