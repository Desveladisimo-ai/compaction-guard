#!/bin/sh
# Monitor. Claude Code starts it with the session, in the session's folder, and turns
# every line it prints into a notice that wakes the assistant. When the SessionStart
# hook has loaded a handoff it leaves a marker; this prints one line so the assistant
# speaks first and carries on from the handoff, with no message from the user.
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
  if [ -r "$marker" ]; then
    rm -f "$marker"
    echo "Compaction Guard: the handoff from the previous session is loaded. Announce it as your instructions say and carry on from its Next step."
    # Test hook: lets the unit tests end the process.
    [ -n "${COMPACTION_GUARD_MONITOR_ONCE:-}" ] && exit 0
  fi
  if [ -n "${COMPACTION_GUARD_MONITOR_ONCE:-}" ] && [ "$waited" -ge "$MONITOR_WAIT" ]; then
    exit 0
  fi
  waited=$((waited + 1))
  sleep 1
done
