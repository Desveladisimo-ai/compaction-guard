#!/bin/sh
# Prints the path where the wrap-up skill writes the handoff for the current
# project, and creates its folder.
# The Bash tool does not export CLAUDE_PROJECT_DIR and keeps the folder the assistant
# changed to, so when it is unset, walk up from here to the nearest folder a session
# was started in (recorded by session-start.sh); without one, use this folder.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
dir="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$dir" ]; then
  dir="$PWD"
  d="$PWD"
  while :; do
    if [ -f "$STATE_DIR/roots/$(project_key "$d")" ]; then dir="$d"; break; fi
    [ "$d" = / ] || [ "$d" = . ] && break
    d=$(dirname "$d")
  done
fi
hdir="$GUARD_HOME/handoffs/$(project_key "$dir")"
mkdir -p "$hdir/archive"
echo "$hdir/pending.md"
