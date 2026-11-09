#!/bin/sh
# UserPromptSubmit hook. What this prints is added to the assistant's context.
# Silent unless there is something to say: a block happened, a 100k step was
# crossed, or the context reached the warning or alert level.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
# This hook must never end with a failure status: exit 2 would block and erase the user's
# message. Any unexpected error ends as success.
trap 'exit 0' EXIT
set -f
INPUT=$(cat)
sid=$(safe_id "$(printf '%s' "$INPUT" | json_str session_id)")
transcript=$(printf '%s' "$INPUT" | json_str transcript_path)
[ -n "$sid" ] || exit 0

# The first message of a session that was offered the gauge counts as one offer shown.
pending="$STATE_DIR/gauge-offer.pending"
if regular_file "$pending" && [ "$(cat "$pending")" = "$sid" ]; then
  shown=$(cat "$STATE_DIR/gauge-offer" 2>/dev/null)
  case "$shown" in ''|*[!0-9]*) shown=0 ;; esac
  echo $(( shown + 1 )) > "$STATE_DIR/gauge-offer"
  rm -f "${STATE_DIR:?}/gauge-offer.pending"
fi

used=$(context_used "$transcript")
[ -n "$used" ] || exit 0
# shellcheck disable=SC2046  # splitting into WINDOW and SOURCE is intended
set -- $(window_size "$sid" "$used")
window=$1; source=$2
pct=$(( used * 100 / window ))
left=$(( (window - used) / 1000 ))
mkdir -p "$STATE_DIR" 2>/dev/null

note=""
[ "$source" = "assumed" ] && note=" The window size is assumed ($window tokens); /compaction-guard:status-line gives exact numbers."
line="Context: $pct% ($used of $window tokens, ${left}k left).$note"

blocked="${STATE_DIR:?}/${sid:?}.blocked"
if regular_file "$blocked"; then
  # shellcheck disable=SC2046,SC2086  # splitting the record into its three fields is intended
  set -- $(cat "$blocked")
  rm -f "$blocked"
  echo "Compaction Guard blocked an automatic compaction at $2% of the window (at $1). The context is intact. $line"
  if [ "$pct" -lt "$WARN_PCT" ]; then
    echo "No wrap-up is needed unless the gate check says to move."
  fi
fi

step=$(( used / STEP_TOKENS ))
last=0
regular_file "$STATE_DIR/$sid.step" && last=$(cat "$STATE_DIR/$sid.step")
case "$last" in ''|*[!0-9]*) last=0 ;; esac
echo "$step" > "$STATE_DIR/$sid.step"

gate="Gate check: at the end of the current piece of work, estimate the next piece from similar past pieces. If the estimate times 1.5 plus 30k tokens fits in what is left, keep working and do not wrap up. If it does not fit, or the next task is a clear boundary from this one, tell the user, in this form, and wait for their go: (1) why now, (2) what the wrap-up will save: the handoff, any lasting memory entries, and any stale documents you noticed (listed, not changed), (3) that they can answer yes or run /compaction-guard:wrap-up. Only after the go, run the compaction-guard:wrap-up skill."

if [ "$pct" -ge "$ALERT_PCT" ]; then
  echo "CONTEXT ALERT: $line Do not start new work. $gate"
elif [ "$pct" -ge "$WARN_PCT" ]; then
  echo "CONTEXT WARNING: $line Do not start a new feature or phase before the gate check. $gate"
elif [ "$step" -gt "$last" ]; then
  echo "$line (crossed $(( step * STEP_TOKENS / 1000 ))k tokens)."
fi
exit 0
