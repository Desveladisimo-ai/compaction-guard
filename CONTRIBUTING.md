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
2. Add or update a test in `tests/run-tests.sh` for any behavior you change.
3. Keep scripts POSIX `sh` (no bashisms). Test on Linux if you can; `docker run --rm -v "$PWD":/r:ro alpine:3.20 sh -c 'cp -R /r /w && cd /w && sh tests/run-tests.sh'` is enough.
4. Describe what you observed, not what you expect. A claim in the README or the docs is either something you ran, a linked source, or marked "not verified".

## Reporting a bug

Use the bug template. Include your Claude Code version (`claude --version`), your OS, and the last lines of `~/.claude/compaction-guard/guard.log`. Remove anything private first.

## Security

Please do not open a public issue for a security problem. See [SECURITY.md](SECURITY.md).
