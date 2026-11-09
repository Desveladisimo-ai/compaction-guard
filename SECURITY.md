# Security

## Reporting a vulnerability

Use GitHub's private reporting: open the **Security** tab of this repository and choose **Report a vulnerability**. Please do not open a public issue.

You can expect an acknowledgement within a few days. This is a volunteer project, so there is no fixed fix time. Confirmed issues are fixed, recorded in the [changelog](CHANGELOG.md) and credited to the reporter if they wish.

## Supported versions

Only the latest release receives fixes.

## What the plugin touches

It runs local shell scripts, makes no network requests, and writes only under `~/.claude/compaction-guard/` (or `$COMPACTION_GUARD_HOME`), readable by your user only. Handoff files are written by the assistant and may contain what you worked on, so review one before sharing it. The full model of what is trusted and what is not is in the [threat model](docs/security/threat-model.md).

## What has been reviewed

Before the first release the code had a maintainer audit and an independent AI-agent review, a secret scan of the whole history and static analysis; every finding, its fix and its regression test is in the [audit record](docs/security/audit-2026-11-09.md), which also says what was not done (no human third-party audit). The checks that run on every change are in [quality gates](docs/quality-gates.md).
