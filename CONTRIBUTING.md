# Contributing

Thanks for helping. This is a small plugin made of POSIX shell scripts; keeping it that way (no dependencies beyond the standard tools) is a goal.

## Before you open a pull request

1. Run the checks the CI runs:
   ```
   sh tests/run-tests.sh
   shellcheck -x -P SCRIPTDIR -s sh plugins/compaction-guard/scripts/*.sh
   claude plugin validate ./plugins/compaction-guard
   claude plugin validate .
   ```
2. Changing anything under `plugins/` needs a new `version` in `plugins/compaction-guard/.claude-plugin/plugin.json` and a changelog entry; CI fails otherwise (see [ADR 0012](docs/adr/0012-version-bump-on-every-plugin-change.md)).
3. Add or update a test in `tests/run-tests.sh` for any behavior you change.
4. Keep scripts POSIX `sh` (no bashisms). Test on Linux if you can; `docker run --rm -v "$PWD":/r:ro alpine:3.20 sh -c 'cp -R /r /w && cd /w && sh tests/run-tests.sh'` is enough.
5. If your change is a design decision (a new default, a new trust assumption, a new file the plugin writes), add a record under `docs/adr/` from `docs/adr/template.md`.
6. The build fails if a script gains a network call, an `eval` or a privilege escalation; if you have a good reason, say so in the pull request and update the policy test with it.
7. Describe what you observed, not what you expect. A claim in the README or the docs is either something you ran, a linked source, or marked "not verified".

## Trying your change in a real session

Add your clone as a marketplace (`claude plugin marketplace add /path/to/clone`) and install from it. Claude Code then loads whatever is checked out in that folder, so a branch switch changes the plugin in your open sessions, and `/plugin` refuses to update it ("Local plugins cannot be updated remotely"). That is expected for a local folder.

## Reporting a bug

Use the bug template. Include your Claude Code version (`claude --version`), your OS, and the last lines of `~/.claude/compaction-guard/guard.log`. Remove anything private first.

## Security

Please do not open a public issue for a security problem. See [SECURITY.md](SECURITY.md).
