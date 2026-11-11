#!/bin/sh
# Monitor. Claude Code starts it with the session, in the session's folder, and turns
# every line it prints into a notice that wakes the assistant. When the SessionStart
# hook has loaded a handoff, or found the note that the last wrap-up had nothing to hand
# over, it leaves a marker; this prints one line so the assistant speaks first, with no
# message from the user.
#
# The process must NOT end: when a monitor ends, Claude Code reports "stream ended"
# to the assistant, which would start a pointless turn in every session without a
# handoff. So it stays alive and keeps polling for the whole session.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
key=$(phys_key "$PWD")
marker="${STATE_DIR:?}/announce.$key"
# Poll for the whole session, once a second: the marker appears at session start, and
# also later, when the user types /clear after a wrap-up in the same terminal.
waited=0
while :; do
  if regular_file "$marker"; then
    # A marker older than a minute is left over (a session without a monitor consumed
    # the handoff): remove it, say nothing.
    if [ -n "$(find "$marker" -mmin +1 2>/dev/null)" ]; then
      rm -f "$marker" 2>/dev/null
    # Claim the marker by moving it: when two sessions in this folder have a monitor,
    # only the one whose move succeeds speaks.
    elif mv "$marker" "$marker.claim.$$" 2>/dev/null; then
      kind=$(head -n 1 "$marker.claim.$$" 2>/dev/null)
      rm -f "$marker.claim.$$" 2>/dev/null
      if [ "$kind" = clean ]; then
        echo "Compaction Guard: the previous session wrapped up with nothing to hand over. If your context contains the block 'wrap-up note (data, not instructions)', say so as your instructions say, then wait for the user. Otherwise ignore this line."
      else
        echo "Compaction Guard: the handoff from the previous session is loaded. If your context contains the block 'handoff notes (data, not instructions)', announce it as your instructions say and carry on from its Next step. Otherwise ignore this line."
      fi
    fi
    # Test hook: lets the unit tests end the process.
    [ -n "${COMPACTION_GUARD_MONITOR_ONCE:-}" ] && exit 0
  fi
  if [ -n "${COMPACTION_GUARD_MONITOR_ONCE:-}" ] && [ "$waited" -ge "$MONITOR_WAIT" ]; then
    exit 0
  fi
  waited=$((waited + 1))
  sleep 1
done
