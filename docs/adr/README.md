# Architecture decision records

Each file records one decision: the situation, what was decided, and what follows from it. A decision is never edited after the fact; a later decision supersedes it and says so. To propose a change, open an issue or a pull request that adds a new record from [`template.md`](template.md).

| # | Decision | Status |
|---|---|---|
| [0001](0001-one-plugin-with-skills.md) | One plugin, with skills for the parts that run on demand | Accepted |
| [0002](0002-ceiling-block-below-allow-above.md) | Block automatic compaction below a ceiling, allow it above | Accepted |
| [0003](0003-state-outside-the-repository-private.md) | State and handoffs live outside the repository, private to the user | Accepted |
| [0004](0004-posix-shell-no-dependencies.md) | POSIX shell and standard tools only | Accepted |
| [0005](0005-wrap-up-needs-the-users-go.md) | The wrap-up needs the user's go | Accepted |
| [0006](0006-automatic-pickup-by-monitor.md) | A monitor starts the next session from the handoff | Accepted |
| [0007](0007-fail-open.md) | Fail open on any error | Accepted |
| [0008](0008-handoff-is-data-not-instructions.md) | A handoff is data, not instructions | Accepted |
| [0009](0009-status-line-is-optional.md) | The status line gauge is optional and never forced | Accepted |
| [0010](0010-handoff-lifecycle.md) | Handoff lifecycle: archive after use, expire, prune | Accepted |
| [0011](0011-make-an-inactive-session-visible.md) | Make an inactive session visible | Accepted |
| [0012](0012-version-bump-on-every-plugin-change.md) | Version bump on every plugin change, enforced in CI | Accepted |

Related: the [incident reviews](../incidents/README.md), the [threat model](../security/threat-model.md), the [security audit](../security/audit-2026-11-09.md) and the [quality gates](../quality-gates.md).
