# Sources

Retrieved 2026-11-06 unless stated. "Observed" means produced by a command in the working session.

| # | Source | Used for |
|---|---|---|
| S1 | Claude Code changelog, https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md (file read through the GitHub contents API, 9,977 lines, top entry 2.1.318) | what each version changed about compaction |
| S2 | GitHub releases API, `GET /repos/anthropics/claude-code/releases/tags/vX`, field `published_at` | release dates of versions 2.1.15 and later (earlier versions have no GitHub release) |
| S3 | npm registry, `npm view @anthropic-ai/claude-code time --json` | publish dates, including the early versions (0.2.98, 1.0.48, 1.0.51, 2.0.64) |
| S4 | Settings reference, https://code.claude.com/docs/en/settings-reference.md (entries `idleCompaction`, `autoCompactEnabled`, `autoCompactWindow`), read through a research agent on 2026-11-03 | defaults and where each setting can live |
| S5 | Environment variables, https://code.claude.com/docs/en/env-vars.md (`DISABLE_AUTO_COMPACT`, `DISABLE_COMPACT`, `CLAUDE_CODE_IDLE_COMPACT_MIN_TOKENS`) | switches that turn compaction off |
| S6 | Hooks reference, https://code.claude.com/docs/en/hooks.md (first 100,000 characters) | `PreCompact` matcher values and blocking, `UserPromptSubmit` stdout as context, size limit |
| S7 | Status line, https://code.claude.com/docs/en/statusline.md | the JSON a status line receives (context window size, used percentage, current usage) |
| S8 | Plugin manifest reference, https://code.claude.com/docs/en/plugins-reference.md | what a plugin can contain, layout, reserved names, plugin `settings` limits |
| S9 | Create a marketplace, https://code.claude.com/docs/en/plugin-marketplaces.md | how people install a plugin from a git repository |
| S10 | Public issue tracker, https://github.com/anthropics/claude-code/issues, search `in:title compact created:>=2026-10-14` (GitHub search API) | 90 issues with "compact" in the title since idle compaction shipped; individual reports, not verified |
| S11 | The maintainer's session transcript of 2026-10-30 to 2026-11-06 (compact boundary records: trigger, tokens before and after, duration) | measured compactions |
| S12 | The maintainer's hook logs (`compact-blocked` flag files) of 2026-11-03 | the gate blocking idle compaction |

Not used and not verified: any claim about why the behavior was chosen beyond what the changelog states; any cost figure for rework (not measured).
