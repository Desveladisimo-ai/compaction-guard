# 0012: Version bump on every plugin change, enforced in CI

- Status: Accepted
- Date: 2026-11-09

## Context
Claude Code identifies a plugin release by the `version` string in its manifest. If shipped files change while the version stays the same, `claude plugin update` reports "already at the latest version" and keeps the cached copy. On 2026-11-09 a maintainer's installed copy was found to lack several later fixes for exactly this reason ([incident review](../incidents/2026-11-09-plugin-inactive-in-open-session.md)).

## Decision
Any pull request that changes a file under `plugins/` must change `version` in `plugins/compaction-guard/.claude-plugin/plugin.json` and add a changelog entry. The CI job "Version bump" (`tests/check-version-bump.sh`) fails the pull request otherwise. Versions follow [Semantic Versioning](https://semver.org/): fixes are patch releases, compatible features are minor, incompatible changes are major. Changes that touch only documentation, tests or CI do not need a bump.

## Consequences
- A fix always reaches existing installs through `claude plugin update`.
- Small fixes cost a version number; that is cheap compared with an unfixed install.

## Evidence
`sh tests/check-version-bump.sh <base>` passes when the version moved and prints a failure naming the changed files when it did not (checked both ways on 2026-11-09).
