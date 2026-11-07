#!/bin/sh
# SessionStart hook (startup and clear). Adds a pending handoff for this project to
# the context, once, so a new session continues where the last one stopped.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
INPUT=$(cat)
dir=$(printf '%s' "$INPUT" | json_str cwd)
[ -n "$dir" ] || dir="${CLAUDE_PROJECT_DIR:-$PWD}"
mkdir -p "$STATE_DIR" 2>/dev/null

# Offer the optional gauge until the user installs it, declines it, or has seen the
# offer three times. The count goes up only when the user sends a first message
# (see prompt.sh), so a session that is opened and closed does not use it up.
sid=$(printf '%s' "$INPUT" | json_str session_id)
offer="$STATE_DIR/gauge-offer"
if gauge_installed; then
  echo "done" > "$offer"
fi
state=$(cat "$offer" 2>/dev/null)
case "$state" in
  done|declined) ;;
  *)
    case "$state" in ''|*[!0-9]*) state=0 ;; esac
    if [ "$state" -lt "$OFFER_MAX" ] && [ -n "$sid" ]; then
      echo "$sid" > "$STATE_DIR/gauge-offer.pending"
      echo "Compaction Guard is active: automatic compaction is blocked while there is room left, the context is watched, and a wrap-up with a handoff is suggested when it is time to change session. Start your first reply with one short sentence telling the user this, and that /compaction-guard:status-line (optional, asks first) adds a context gauge and makes the warning levels exact. If they say they do not want it, run: echo declined > \"$offer\""
    fi
    ;;
esac

hdir="$GUARD_HOME/handoffs/$(project_key "$dir")"
pending="$hdir/pending.md"
[ -r "$pending" ] || exit 0

if [ -n "$(find "$pending" -mtime +"$HANDOFF_MAX_DAYS" 2>/dev/null)" ]; then
  log_line "handoff expired, not injected: $pending"
  exit 0
fi

mkdir -p "$hdir/archive" 2>/dev/null
echo "A previous session in this project left the handoff below. First decide whether it contains real work to continue: done items, decisions, or a concrete next step that is more than reading documents or asking the user what to do. If it does, start your reply with the line 'Continuing from the handoff: <goal in a few words>. Say stop if you want something else.' and carry on from its Next step without waiting for an answer. If it says no work was done, or its next step is only to read documents or ask the user, start your reply with the line 'The previous session left a handoff with nothing to continue.' and then carry on normally. In either case, if the user's first message is clearly about something else, do not continue the handoff and ask once whether to discard it."
echo
cat "$pending"
echo injected > "${STATE_DIR:?}/announce.$(phys_key "$dir")"
archived="$hdir/archive/$(date -u +%Y%m%dT%H%M%SZ).md"
mv "$pending" "$archived" 2>/dev/null && log_line "handoff injected and archived: $archived"
exit 0
