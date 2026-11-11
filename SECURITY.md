# Security

## Reporting a vulnerability

Use GitHub's private reporting: open the **Security** tab of this repository and choose **Report a vulnerability**. Please do not open a public issue.

You can expect an acknowledgement within a few days. This is a volunteer project, so there is no fixed fix time. Confirmed issues are fixed, recorded in the [changelog](CHANGELOG.md) and credited to the reporter if they wish.

## Supported versions

Only the latest release receives fixes.

## Getting fixes

A fix reaches an installed copy only through a plugin update. Auto-update is off by default for this marketplace; [how to turn it on, or update by hand](README.md#updates). To be told when a release exists, choose **Watch**, then **Custom**, then **Releases** on the repository page. Security fixes are marked as such in the release notes.

## Trust boundary

The plugin protects your files from other accounts on the computer (folders `700`, files `600`). It does not protect them from someone using your account: that person already has your files, your Claude Code login and your permission settings. A handoff you leave unclaimed is picked up by the first session opened in that project under your account, and the assistant continues it. Lock your screen or log out when you leave a shared computer.

## What the plugin touches

It runs local shell scripts, makes no network requests, and writes only under `~/.claude/compaction-guard/` (or `$COMPACTION_GUARD_HOME`), readable by your user only. Handoff files are written by the assistant and may contain what you worked on, so review one before sharing it. The full model of what is trusted and what is not is in the [threat model](docs/security/threat-model.md).

## What has been reviewed

Before the first release the code had a maintainer audit and an independent AI-agent review, a secret scan of the whole history and static analysis; every finding, its fix and its regression test is in the [audit record](docs/security/audit-2026-11-09.md), which also says what was not done (no human third-party audit). The checks that run on every change are in [quality gates](docs/quality-gates.md).
