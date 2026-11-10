# Troubleshooting

## The plugin did nothing in a session I already had open

**Symptom.** Claude Code compacted a conversation on its own, or no warnings appeared, although `claude plugin list` shows `compaction-guard` as installed and enabled. `~/.claude/compaction-guard/guard.log` has no line for that session.

**Cause.** Claude Code loads plugins when a session starts, or when you run `/reload-plugins`. A session that was already open when you installed (or updated) the plugin never registered its hooks. `claude plugin list` reports what is installed on disk, not what a given running session has loaded. This is how Claude Code works for every plugin ([plugin loading reference](https://code.claude.com/docs/en/plugins/loading.md), *Check which stage a plugin reached*). It was the cause of [issue #5](https://github.com/Desveladisimo-ai/compaction-guard/issues/5); the full account is in the [incident review](incidents/2026-11-09-plugin-inactive-in-open-session.md).

**How to tell.**
- If you installed the optional status line gauge, a session where the hooks have not run shows `guard OFF: run /reload-plugins` next to the gauge once the conversation has tokens in it.
- Otherwise compare when the session started with when the plugin was installed (`installedAt` in `~/.claude/plugins/installed_plugins.json`). A session that started earlier does not have it.
- A session that has the plugin leaves a file `~/.claude/compaction-guard/state/<session id>.active`.

**Fix.** In the open session run `/reload-plugins`: it switches on the hooks without ending the session. The handoff monitor needs the session to be restarted, so until then a handoff is not picked up automatically after `/clear`. Or restart the session.

## A new session started and said nothing about a handoff

- If the last wrap-up found nothing to continue, the new session opens with "The previous session wrapped up with nothing to hand over: <reason>" ([ADR 0013](adr/0013-announce-a-wrap-up-with-nothing-to-hand-over.md)).
- If it says neither that nor "Continuing from the handoff", no handoff or note was found for that project folder. Check `~/.claude/compaction-guard/guard.log` and the folder `~/.claude/compaction-guard/handoffs/`: a wrap-up run from a different folder saves under that folder's name, and a handoff or note older than 14 days is ignored.
- A session that never ran the wrap-up leaves nothing and starts silently; that is expected.

## I updated the plugin and nothing changed

Claude Code identifies a release by the `version` string in the plugin manifest. If the version did not change, `claude plugin update` reports "already at the latest version" and keeps the cached copy, even if files differ. Releases of this project bump the version on every change to the plugin (a CI check enforces it). After `claude plugin update compaction-guard@compaction-guard-marketplace`, run `/reload-plugins` in open sessions, or restart them.

To see which version a session is running from, look at the path of the installed copy: `~/.claude/plugins/cache/compaction-guard-marketplace/compaction-guard/<version>/`.

## Nothing is blocked, but the plugin is loaded

- Automatic compaction is allowed at or above the ceiling (95% by default): that is by design, see [ADR 0002](adr/0002-ceiling-block-below-allow-above.md).
- If the token count cannot be read, the hook allows compaction and writes the reason to `guard.log` ([ADR 0007](adr/0007-fail-open.md)).
- A manual `/compact` is never blocked.

## On Windows nothing happens

Claude Code runs hooks in Git Bash on Windows, or in PowerShell when Git Bash is not installed; the scripts need Git Bash. Install [Git for Windows](https://git-scm.com/downloads/win) and restart the session. See the [client checklist](testing/client-checklist.md).

## Still stuck

Open an issue with your Claude Code version, OS, and the last lines of `guard.log` (remove anything private).
