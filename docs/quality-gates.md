# Quality gates

Every change passes these before it can merge. They run in CI on every push and pull request ([`.github/workflows/ci.yml`](../.github/workflows/ci.yml)) and can be run locally with the commands shown.

| Gate | What it checks | Run locally |
|---|---|---|
| Tests, Ubuntu, macOS and Windows (Git Bash) | 131 checks: behaviour of every hook, the monitor, the status line, privacy modes, hostile inputs, and policy | `sh tests/run-tests.sh` |
| Policy tests | The scripts contain no network command, no `eval`, no privilege escalation | part of the suite |
| ShellCheck | Static analysis of all scripts as POSIX `sh` | `shellcheck -x -P SCRIPTDIR -s sh plugins/compaction-guard/scripts/*.sh` |
| Secret scan | Every commit in the history, with gitleaks | `docker run --rm -v "$PWD":/repo zricethezav/gitleaks detect --source /repo --log-opts="--all" --redact` |
| Version bump (pull requests) | A change under `plugins/` must move the version in the manifest ([ADR 0012](adr/0012-version-bump-on-every-plugin-change.md)) | `sh tests/check-version-bump.sh origin/main` |
| Plugin and marketplace validation | The manifest and layout, with `claude plugin validate` | `claude plugin validate ./plugins/compaction-guard` and `claude plugin validate .` |

Also on the Linux side, outside CI: the suite was run on Alpine 3.20 (busybox) and Ubuntu 24.04 (dash) in containers (`docker run --rm -v "$PWD":/r:ro alpine:3.20 sh -c 'cp -R /r /w && cd /w && sh tests/run-tests.sh'`). To test exactly what is committed, feed the container `git archive HEAD` instead: Docker Desktop bind mounts can show a stale file mode after a `chmod` and fail the "every script is executable" check on a correct commit (`git archive HEAD | docker run --rm -i alpine:3.20 sh -c 'mkdir /w && cd /w && tar -x && sh tests/run-tests.sh'`).

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
| `SessionStart`, 0.1.3, no handoff and no note | once per session | 63 ms | 73 ms |
| `SessionStart`, 0.1.3, announcing a nothing-to-hand-over note | once, after such a wrap-up | 94 ms | 117 ms |
| `PreCompact` | only on an automatic compaction | 215 ms | 241 ms |

The first three rows were measured at 0.1.2 and not repeated; the hooks they time did not change in 0.1.3. The two 0.1.3 rows were measured on 2026-11-10 (macOS, 100 runs each, no transcript needed by this hook). The monitor sleeps one second between checks and reads one file path.

## Branch protection and repository settings
Verified through the GitHub API on 2026-11-09 and re-checked on 2026-11-10 (seven required checks, up to date, linear history, no force-push, secret scanning and push protection, private reporting):

- **`main` is protected.** A pull request is required (zero approvals, because there is a single maintainer), seven status checks must pass and be up to date (the three test runs, ShellCheck, the secret scan, plugin validation and the version bump), history is linear, force pushes and deletions are refused, and conversations must be resolved. Administrators are not forced through these rules, so the maintainer can bypass them; contributors cannot.
- **Secret scanning and push protection are on**, in addition to the CI scan of the history.
- **Dependabot alerts and security updates are on**; version updates for the workflow actions come from `dependabot.yml`.
- **The default workflow token is read-only**, and workflows cannot approve pull requests.
- **Private vulnerability reporting is on** (switched on when the repository was made public on 2026-11-09; the API returned 404 while it was private).

## Audits
See [the security audit](security/audit-2026-11-09.md) and [the threat model](security/threat-model.md).
