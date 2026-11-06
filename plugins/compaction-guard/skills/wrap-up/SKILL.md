---
name: wrap-up
description: Use when the context gate says to change session (the next piece of work does not fit in the room left, or a feature just ended at a clear boundary), or when the user asks to wrap up. Saves a handoff and durable notes so a new session continues by itself.
---

# Wrap-up: save what must outlive this session

Run this only when the gate check says to move, or when the user asks. If neither is true, say so in one sentence and stop; a wrap-up on every check wastes tokens.

## 1. Find where to write

Run this command and use the path it prints:

```
"${CLAUDE_PLUGIN_ROOT}/scripts/handoff-path.sh"
```

## 2. Write the handoff

Write the file at that path, in this form. Keep it short and concrete; a person should be able to read it in two minutes. Never put credentials, tokens or personal data in it.

```
---
created: <UTC time>
project: <project folder>
status: pending
context at wrap-up: <percent and tokens>
---

# Handoff

## Goal
<what this body of work is for, in one or two sentences>

## State
- Done: <what is finished and checked, with the command or file that shows it>
- In progress: <what is half done, and exactly where it stopped>

## Decisions and why
- <decision> because <reason>

## Not verified
- <anything claimed but not checked>

## Next step
<the first action the next session should take, specific enough to start without asking>

## Waiting on the user
- <approvals, merges, choices that only the user can make>

## Do not touch
- <things deliberately left alone, and why>

## Key paths and commands
- <how to run the tests, where the important files are>

## Noticed but not changed
- <stale documents or loose ends seen; listed, not edited>
```

## 3. Save lasting facts

If you have a persistent memory mechanism available, save the facts that will matter in future sessions and cannot be read from the project itself: decisions with their reason, the user's preferences, pointers to outside resources. Do not duplicate what is already saved. If you have no memory mechanism, skip this and say so.

## 4. Change nothing else

Do not edit code, documents or settings as part of the wrap-up. Stale documents go in the handoff under "Noticed but not changed".

## 5. Tell the user, in three parts

1. **Why now:** what just finished, why the next task is a clear boundary or does not fit, the context size and the estimate for the next piece.
2. **What I saved:** the handoff path, and the memory entries if any.
3. **How to continue:** "Type `/clear`, or open a new session. It will continue from the handoff on its own; you do not need to paste anything."

Then stop. Do not start new work in this session.
