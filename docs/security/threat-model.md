# Threat model

What the plugin protects, what it trusts, and what it does about each way that trust could be abused. Written for a reader who wants to judge the design, not take it on faith. Decisions are in the [ADRs](../adr/README.md); the findings that shaped this page are in the [audit](audit-2026-11-09.md).

## What it protects
1. **The user's session.** The plugin must never trap a session, block a message, or make things worse than not having it.
2. **The content of handoffs.** They record what the user worked on.
3. **The integrity of what reaches the assistant's context.** The handoff and the warning lines are inputs the assistant acts on.

## Trust boundaries
| Input | Trusted? | Why |
|---|---|---|
| Claude Code (the host) and the user's own account | Yes | The plugin runs inside it, as the user. Hooks and monitors run with the user's permissions; Claude Code sets that, the plugin cannot lower it. |
| JSON on a hook's stdin (session id, paths, trigger) | Validated | Produced by Claude Code, but reduced to safe characters before use. |
| Environment variables (`COMPACTION_GUARD_*`, `CLAUDE_*`) | Validated | A cloned repository's settings can set them. |
| Files in the state folder | Validated | Owned by the user, mode `700`/`600`; read only if plain files. |
| The transcript file | Validated | Only token counts are read; nothing from it is executed or injected. |
| **Handoff content** | **No** | Written by the assistant, possibly after reading untrusted content. Treated as data. |

## Threats and responses
| Threat | Response | Where | Test |
|---|---|---|---|
| Another local user reads or plants a handoff | Folders `700`, files `600`; older installs tightened once, only if owned by the user and not a symlink | [0003](../adr/0003-state-outside-the-repository-private.md) | "state folder is private to the user", "a symlinked home is not tightened" |
| An identifier forms a path (`../`) | Identifiers reduced to `A-Za-z0-9._-` | 0003 | "session id stays inside the state folder" |
| An environment value reaches arithmetic or a command | Every number validated with a fallback; no `eval`; state path with shell characters replaced | [0007](../adr/0007-fail-open.md) | "a setting cannot run a command", "a home path with a dollar sign is replaced by the default", policy "scripts never use eval" |
| A bad value blocks compaction or erases a message | Hooks fail open and end in success on unexpected errors | 0007 | "a bad ceiling falls back to 95 and allows above it", "prompt hook ends in success with a hostile setting" |
| A pipe, link or folder in place of a state file hangs a hook or leaks a file | Only plain files are read; the handoff is capped at 50 KB | 0007 | "a pipe named pending.md does not hang the session start", "a link named pending.md is not followed", "an oversized handoff is cut" |
| An instruction hidden in content the assistant read survives into the next session | Handoff delimited as data; risky steps need a question; the wrap-up may not copy outside instructions | [0008](../adr/0008-handoff-is-data-not-instructions.md) | "the notes grant no permission", "risky next steps need a question first"; real-client check |
| The plugin sends data out | No network commands; checked on every build | [0004](../adr/0004-posix-shell-no-dependencies.md) | policy "scripts make no network calls" |
| Secrets committed to the repository | Full-history scan on every build | [quality gates](../quality-gates.md) | CI job "Secret scan" |
| A compromised workflow dependency | Actions pinned to commit SHAs, read-only token, Dependabot updates | quality gates | `.github/workflows/ci.yml` |

## Out of scope
- A compromised user account, operating system or Claude Code itself.
- A malicious marketplace or a modified copy of this plugin. Install from the official repository and read the scripts; they are short.
- Prompt injection in general. This plugin bounds one path (the handoff); Claude Code's permission prompts are the control for the rest.
- Native Windows (not tested).

## Reporting
See [SECURITY.md](../../SECURITY.md).
