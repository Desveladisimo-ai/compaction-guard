#!/bin/sh
# SessionStart hook, for every source (startup, clear, resume, compact). Records that
# the plugin's hooks run in this session, and removes per-session files older than 30
# days. Prints nothing.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
trap 'exit 0' EXIT
INPUT=$(cat)
sid=$(safe_id "$(printf '%s' "$INPUT" | json_str session_id)")
mark_active "$sid"
find "$STATE_DIR" -type f \( -name '*.active' -o -name '*.step' -o -name '*.window' -o -name '*.blocked' \) -mtime +30 -exec rm -f {} + 2>/dev/null
exit 0
