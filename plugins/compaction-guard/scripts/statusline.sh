#!/bin/sh
# Optional status line. Prints the context gauge and records the exact window size
# so the hooks stop guessing. Installed by /compaction-guard:status-line.
GUARD_HOME="${COMPACTION_GUARD_HOME:-$HOME/.claude/compaction-guard}"
umask 077
IN=$(cat | tr -d '\n')
num() { printf '%s' "$IN" | sed -n "s/.*\"$1\" *: *\\([0-9][0-9]*\\).*/\\1/p" | head -n 1; }
sid=$(printf '%s' "$IN" | sed -n 's/.*"session_id" *: *"\([^"]*\)".*/\1/p' | head -n 1 | tr -c 'A-Za-z0-9._-' '_')
window=$(num context_window_size)
i=$(num input_tokens); c=$(num cache_creation_input_tokens); r=$(num cache_read_input_tokens)
used=$(( ${i:-0} + ${c:-0} + ${r:-0} ))
if [ -n "$window" ] && [ "$window" -gt 0 ]; then
  if [ -n "$sid" ]; then
    mkdir -p "$GUARD_HOME/state" 2>/dev/null
    echo "$window" > "$GUARD_HOME/state/$sid.window" 2>/dev/null
  fi
  # Tokens already used but no sign that the hooks ever ran in this session: the plugin
  # was installed after the session started. Say so.
  guard=""
  if [ -n "$sid" ] && [ "$used" -gt 0 ] && [ ! -f "$GUARD_HOME/state/$sid.active" ]; then
    guard="  guard OFF: run /reload-plugins"
  fi
  printf 'ctx %s%%  %sk/%sk  left %sk%s' $(( used * 100 / window )) $(( used / 1000 )) $(( window / 1000 )) $(( (window - used) / 1000 )) "$guard"
else
  printf 'ctx n/a'
fi
