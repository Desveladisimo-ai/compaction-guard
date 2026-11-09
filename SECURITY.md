# Security

## Reporting a vulnerability

Use GitHub's private reporting: open the **Security** tab of this repository and choose **Report a vulnerability**. Please do not open a public issue.

You can expect an acknowledgement within a few days. This is a volunteer project, so there is no fixed fix time.

## What the plugin touches

It runs local shell scripts, makes no network requests, and writes only under `~/.claude/compaction-guard/` (or `$COMPACTION_GUARD_HOME`). Handoff files are written by the assistant and may contain what you worked on, so review one before sharing it.
