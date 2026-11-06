# compaction-guard

Working project (drafts, not published). Goal: help people who lose work to Claude Code's automatic compaction, including the idle compaction that became default-on in October 2026. First an honest, sourced account of the problem; then a plugin that makes compaction a decision the person takes, with a visible gauge, warnings the model can see, and a wrap-up procedure.

Started 2026-11-06 from a working local setup built and tested over 2026-11-02 to 2026-11-06 (see `reference/`). This project is separate from any product repository.

## Status

| Piece | State |
|---|---|
| Problem timeline (what changed and when, with sources) | approved draft: `docs/01-timeline-draft.md` |
| Incident write-ups (what was lost, measured records, what the gate did) | approved draft: `docs/02-incidents-draft.md` |
| Plugin or skill design (what to package, how to ship it) | approved draft: `docs/03-plugin-design-draft.md` |
| Feature decisions taken with the owner (defaults, handoff, ceiling) | `docs/04-feature-decisions.md` |
| Sources with retrieval dates | `docs/sources.md` |
| Plugin itself | not started |

## Rules for everything in this project

1. A claim is one of: observed (with the command or file that shows it), taken from a public source (linked, with the retrieval date), reported by the owner (named as such), or marked "not verified".
2. Public text from the Claude Code repository is paraphrased with version numbers and links, not copied.
3. No claim about anyone's intent. The sources show a documented default and its effects; they do not show why anyone chose it beyond what the changelog says.
4. Anything taken from a private project is sanitized (no names, no identifiers) and approved by the owner before publication.
5. The plugin name must not start with `claude-` or `anthropic-` (the validator rejects it); this directory name is fine, the plugin name is chosen separately.

## Files

- `docs/` the drafts and the source list
- `reference/` the three scripts and the settings snippet that worked locally (macOS, needs `jq` and `osascript`); a starting point, not the plugin
