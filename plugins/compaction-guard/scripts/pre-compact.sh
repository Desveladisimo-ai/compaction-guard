#!/bin/sh
# PreCompact hook. Blocks an automatic compaction (including idle compaction) while
# there is room left, and lets it run above the ceiling so a session never ends up
# stuck on a failed request. A manual /compact is always allowed.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
# Fail open: any unexpected error (a shell arithmetic failure exits with status 2, which
# would block) ends as "allowed". Only the deliberate block below sets BLOCK.
trap '[ "${BLOCK:-}" = 1 ] || exit 0' EXIT
INPUT=$(cat)
trigger=$(printf '%s' "$INPUT" | json_str trigger)
[ "$trigger" = "manual" ] && exit 0
sid=$(safe_id "$(printf '%s' "$INPUT" | json_str session_id)")
transcript=$(printf '%s' "$INPUT" | json_str transcript_path)

used=$(context_used "$transcript")
if [ -z "$used" ] || [ -z "$sid" ]; then
  log_line "allowed: context size or session unknown"
  exit 0
fi
# shellcheck disable=SC2046  # splitting into WINDOW and SOURCE is intended
set -- $(window_size "$sid" "$used")
window=$1
pct=$(( used * 100 / window ))

if [ "$pct" -ge "$CEILING_PCT" ]; then
  log_line "allowed: $pct% is at or above the ceiling of $CEILING_PCT% (session $sid)"
  exit 0
fi

mkdir -p "$STATE_DIR" 2>/dev/null
printf '%s %s %s\n' "$(date -u +%FT%TZ)" "$pct" "$used" > "$STATE_DIR/$sid.blocked"
log_line "blocked: automatic compaction at $pct% ($used of $window tokens, session $sid)"
notify "Compaction Guard" "Blocked an automatic compaction at $pct%. Nothing was lost."
echo "Compaction Guard blocked an automatic compaction at $pct% of the context window. The conversation is intact." >&2
BLOCK=1
exit 2
