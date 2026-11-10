# 0003: State and handoffs live outside the repository, private to the user

- Status: Accepted (amended 2026-11-09: permissions)
- Date: 2026-11-06

## Context
Handoffs record what the user worked on, and they are read back into the assistant's context. They must not end up committed by accident, must survive plugin updates and uninstalls, and must be shared with the optional status line, which runs outside the plugin and cannot see the plugin data folder.

## Decision
Everything lives under `~/.claude/compaction-guard/` (override: `COMPACTION_GUARD_HOME`): `state/`, `handoffs/<project>/` and `guard.log`. All of it is created for the user only (`umask 077`: folders `700`, files `600`). A folder created by an earlier version is tightened once, only if it is a real folder (not a symlink) owned by the current user. A home path containing shell metacharacters is replaced by the default. Session identifiers are reduced to `A-Za-z0-9._-` before they become file names.

## Consequences
- No git noise and nothing private in a repository.
- Another local user cannot read handoffs or plant one.
- The state folder is not removed on uninstall; the README says how to delete it.

## Evidence
Tests: "state folder is private to the user", "older install: folder tightened", "a symlinked home is not tightened", "session id is sanitized into one file name", "a home path with a dollar sign is replaced by the default". Found by the [security audit](../security/audit-2026-11-09.md) (SA-01, SA-02, IR-06, IR-07).

## Amendment (2026-11-10, version 0.1.4)
The `umask` does not cover the handoff: the wrap-up skill writes `pending.md` with the assistant's editor tool, and the file was observed as `644`. The skill now runs `chmod 600` after writing, and `session-start.sh` runs `chmod 600` on `pending.md` (a regular file only) before reading and archiving it. Test: "a handoff written as 644 ends private to the user".
