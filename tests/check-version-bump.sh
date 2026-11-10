#!/bin/sh
# Fails if files under plugins/ changed relative to BASE without a new version in
# plugins/compaction-guard/.claude-plugin/plugin.json. Claude Code identifies a plugin
# release by that string, so changed files under an unchanged version are never
# delivered by `claude plugin update`. Usage: sh tests/check-version-bump.sh <base-ref>
base=${1:?usage: check-version-bump.sh <base-ref>}
manifest=plugins/compaction-guard/.claude-plugin/plugin.json
changed=$(git diff --name-only "$base"...HEAD -- plugins/ | grep -v '^$')
if [ -z "$changed" ]; then echo "no plugin files changed: no version bump needed"; exit 0; fi
old=$(git show "$base:$manifest" 2>/dev/null | sed -n 's/.*"version" *: *"\([^"]*\)".*/\1/p' | head -n 1)
new=$(sed -n 's/.*"version" *: *"\([^"]*\)".*/\1/p' "$manifest" | head -n 1)
if [ -z "$new" ]; then echo "FAIL: no version in $manifest"; exit 1; fi
if [ "$old" = "$new" ]; then
  echo "FAIL: plugin files changed but the version is still $new:"; echo "$changed"
  echo "Bump \"version\" in $manifest and add a CHANGELOG entry."; exit 1
fi
echo "plugin files changed and the version moved: $old -> $new"
