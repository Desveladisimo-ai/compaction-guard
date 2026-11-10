# Quality gates

Every change passes these before it can merge. They run in CI on every push and pull request ([`.github/workflows/ci.yml`](../.github/workflows/ci.yml)) and can be run locally with the commands shown.

| Gate | What it checks | Run locally |
|---|---|---|
| Tests, Ubuntu, macOS and Windows (Git Bash) | 101 checks: behaviour of every hook, the monitor, the status line, privacy modes, hostile inputs, and policy | `sh tests/run-tests.sh` |
| Policy tests | The scripts contain no network command, no `eval`, no privilege escalation | part of the suite |
| ShellCheck | Static analysis of all scripts as POSIX `sh` | `shellcheck -x -P SCRIPTDIR -s sh plugins/compaction-guard/scripts/*.sh` |
| Secret scan | Every commit in the history, with gitleaks | `docker run --rm -v "$PWD":/repo zricethezav/gitleaks detect --source /repo --log-opts="--all" --redact` |
| Version bump (pull requests) | A change under `plugins/` must move the version in the manifest ([ADR 0012](adr/0012-version-bump-on-every-plugin-change.md)) | `sh tests/check-version-bump.sh origin/main` |
| Plugin and marketplace validation | The manifest and layout, with `claude plugin validate` | `claude plugin validate ./plugins/compaction-guard` and `claude plugin validate .` |

Also on the Linux side, outside CI: the suite was run on Alpine 3.20 (busybox) and Ubuntu 24.04 (dash) in containers (`docker run --rm -v "$PWD":/r:ro alpine:3.20 sh -c 'cp -R /r /w && cd /w && sh tests/run-tests.sh'`).

## Supply chain
- Workflow actions are pinned to commit SHAs, with the version in a comment, and updated by Dependabot ([`.github/dependabot.yml`](../.github/dependabot.yml)).
- The workflow token is read-only (`permissions: contents: read`) and checkout does not persist credentials.
- The secret-scan image is pinned by digest.
- The plugin has no runtime dependencies ([ADR 0004](adr/0004-posix-shell-no-dependencies.md)).
- Every change is owned by the maintainer ([`CODEOWNERS`](../.github/CODEOWNERS)).

## Performance
Measured on macOS, 100 runs each, with a 422 KB transcript (the hooks read only the last 800 KB):

| Hook | When | Median | 95th percentile |
|---|---|---|---|
| `UserPromptSubmit` | every message | 88 ms | 95 ms |
| `SessionStart` | once per session | 60 ms | 69 ms |
| `PreCompact` | only on an automatic compaction | 215 ms | 241 ms |

The monitor sleeps one second between checks and reads one file path.

## Branch protection and repository settings
Recorded in the repository settings and verified at release; see [SECURITY.md](../SECURITY.md) and the release notes.

## Audits
See [the security audit](security/audit-2026-11-09.md) and [the threat model](security/threat-model.md).
