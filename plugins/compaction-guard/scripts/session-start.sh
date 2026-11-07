#!/bin/sh
# SessionStart hook (startup and clear). Adds a pending handoff for this project to
# the context, once, so a new session continues where the last one stopped.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
INPUT=$(cat)
dir=$(printf '%s' "$INPUT" | json_str cwd)
[ -n "$dir" ] || dir="${CLAUDE_PROJECT_DIR:-$PWD}"
mkdir -p "$STATE_DIR" 2>/dev/null

if [ ! -e "$STATE_DIR/first-run" ]; then
  date -u +%FT%TZ > "$STATE_DIR/first-run"
  echo "Compaction Guard is active in this installation: automatic compaction is blocked while there is room left, the context is watched, and a wrap-up with a handoff is suggested when it is time to change session. Tell the user this once, in one or two sentences, and that /compaction-guard:status-line adds an optional context gauge."
fi

hdir="$GUARD_HOME/handoffs/$(project_key "$dir")"
pending="$hdir/pending.md"
[ -r "$pending" ] || exit 0

if [ -n "$(find "$pending" -mtime +"$HANDOFF_MAX_DAYS" 2>/dev/null)" ]; then
  log_line "handoff expired, not injected: $pending"
  exit 0
fi

mkdir -p "$hdir/archive" 2>/dev/null
echo "A previous session in this project wrapped up with the handoff below. Start your reply with one line, 'Continuing from the handoff: <goal in a few words>. OK?', unless the user's first message is clearly about something else, in which case ask once whether to discard the handoff. Then continue from its 'Next step'."
echo
cat "$pending"
archived="$hdir/archive/$(date -u +%Y%m%dT%H%M%SZ).md"
mv "$pending" "$archived" 2>/dev/null && log_line "handoff injected and archived: $archived"
exit 0
