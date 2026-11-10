#!/bin/sh
# Records that a wrap-up ran and had nothing to hand over. Usage: no-handoff.sh [REASON]
# The next session in this project says so (session-start.sh), so a session that starts
# without a handoff because everything was settled is not mistaken for one whose
# handoff failed to save. REASON is text written by the assistant: it is cut to one line
# of 300 characters without control characters, and handed back as data, not instructions.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
dir="${CLAUDE_PROJECT_DIR:-$PWD}"
hdir="$GUARD_HOME/handoffs/$(project_key "$dir")"
mkdir -p "$hdir/archive" || exit 0
reason=$(printf '%s' "$*" | tr '\000-\037\177' ' ' | tr -s ' ' | head -c 300)
[ -n "$reason" ] || reason="nothing to continue"
tmp="$hdir/nothing.md.$$"
{
  echo "created: $(date -u +%FT%TZ)"
  echo "reason: $reason"
} > "$tmp" || exit 0
# mv replaces whatever is at the target, a link included, instead of writing through it.
mv -f "$tmp" "$hdir/nothing.md" || rm -f "$tmp"
log_line "wrap-up had nothing to hand over: $hdir/nothing.md"
exit 0
