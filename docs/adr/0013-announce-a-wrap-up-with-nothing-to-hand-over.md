# 0013: Announce a wrap-up that had nothing to hand over

- Status: Accepted
- Date: 2026-11-09

## Context
When a wrap-up finds nothing worth continuing, the `wrap-up` skill wrote nothing and told the user so in that session (step 0b). The next session then started with no message at all. A silent start looks the same as a handoff that failed to save, and the only record that the wrap-up chose to save nothing was in a conversation that had already ended. A user who ran the wrap-up as the last step of a session could not tell the two cases apart.

## Decision
- When there is nothing to hand over, the skill runs `scripts/no-handoff.sh <reason>`. It writes `handoffs/<project>/nothing.md` (time and reason, mode `600`) next to where `pending.md` would be, through a temporary file and `mv`, so a link in its place is replaced and never written through.
- The `SessionStart` hook, when there is no `pending.md` and a `nothing.md`, tells the assistant to open its reply with one line saying the previous session wrapped up with nothing to hand over, and why, then to carry on normally. It archives the note as `archive/<time>-nothing.md` and leaves the `announce` marker with the content `clean`; the monitor wakes the assistant with its own line, so the announcement does not wait for the user's first message (interactive sessions).
- The reason is text written by the assistant, so it is handled as in [0008](0008-handoff-is-data-not-instructions.md): cut to one line of 300 characters without control characters, delimited as data, stated to grant no permission.
- A pending handoff wins. If both exist, the handoff is loaded and the note is removed, because the handoff describes work that is still open.
- A note older than the handoff expiry (14 days) is ignored, like a handoff ([0010](0010-handoff-lifecycle.md)).
- A session that never ran a wrap-up leaves no note, so it still starts silently. The plugin cannot tell that case from a failure without a record, and announcing on every start would be noise.

## Consequences
- After a wrap-up, the next session always says something: the handoff it continues from, or that there was none to continue and why.
- One more small private file, pruned with the archive after 90 days.
- If the assistant skips the script, the next session is silent as before; the skill states why the script matters.

## Evidence
Tests (section "a wrap-up with nothing to hand over is announced by the next session"): "the next session is told the previous wrap-up had nothing to hand over", "the marker is announced only once", "the monitor says the previous wrap-up had nothing to hand over", "a reason with a line break is kept on one line", "control characters are removed from the reason", "a long reason is cut", "a pending handoff is injected even when a marker exists", "an expired marker is not announced", "a pipe named nothing.md does not hang the session start", "no-handoff.sh does not write through a link", "the wrap-up skill tells the assistant to run no-handoff.sh".
