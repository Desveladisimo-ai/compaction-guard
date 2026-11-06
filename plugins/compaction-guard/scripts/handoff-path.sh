#!/bin/sh
# Prints the path where the wrap-up skill writes the handoff for the current
# project, and creates its folder.
. "$(dirname "$0")/lib.sh"
dir="${CLAUDE_PROJECT_DIR:-$PWD}"
hdir="$GUARD_HOME/handoffs/$(project_key "$dir")"
mkdir -p "$hdir/archive"
echo "$hdir/pending.md"
