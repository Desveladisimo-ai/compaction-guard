#!/bin/sh
# Shared helpers for the Compaction Guard hooks. POSIX sh. Needs only sed, grep,
# tail, awk, date, cksum and find, which every macOS and Linux install has.

# Where state and handoffs live. Stable across plugin updates and uninstalls.
GUARD_HOME="${COMPACTION_GUARD_HOME:-$HOME/.claude/compaction-guard}"
STATE_DIR="$GUARD_HOME/state"

# Thresholds, in percent of the context window. Override with environment variables.
STEP_TOKENS="${COMPACTION_GUARD_STEP_TOKENS:-100000}"
WARN_PCT="${COMPACTION_GUARD_WARN_PCT:-70}"
ALERT_PCT="${COMPACTION_GUARD_ALERT_PCT:-85}"
CEILING_PCT="${COMPACTION_GUARD_CEILING_PCT:-95}"
HANDOFF_MAX_DAYS="${COMPACTION_GUARD_HANDOFF_DAYS:-14}"

# json_str KEY: first string value of KEY in the JSON on stdin ("" if absent).
json_str() {
  sed -n "s/.*\"$1\" *: *\"\\([^\"]*\\)\".*/\\1/p" | head -n 1
}

# json_num KEY: first number value of KEY in the JSON on stdin.
json_num() {
  sed -n "s/.*\"$1\" *: *\\([0-9][0-9]*\\).*/\\1/p" | head -n 1
}

# context_used TRANSCRIPT: tokens the next request will carry (input plus cache),
# from the last main-conversation assistant message. Prints nothing if unknown.
context_used() {
  [ -r "$1" ] || return 0
  usage=$(tail -c 800000 "$1" 2>/dev/null \
    | grep '"type":"assistant"' | grep '"isSidechain":false' | tail -n 1 \
    | grep -o '"usage":{[^}]*}' | head -n 1)
  [ -n "$usage" ] || return 0
  i=$(printf '%s' "$usage" | json_num input_tokens)
  c=$(printf '%s' "$usage" | json_num cache_creation_input_tokens)
  r=$(printf '%s' "$usage" | json_num cache_read_input_tokens)
  [ -n "$i$c$r" ] || return 0
  echo $(( ${i:-0} + ${c:-0} + ${r:-0} ))
}

# to_tokens VALUE: "200000", "200k" or "1M" to a plain number (empty if not valid).
to_tokens() {
  case "$1" in
    ''|*[!0-9kKmM]*) return 0 ;;
    *[kK]) n=${1%[kK]}; case "$n" in ''|*[!0-9]*) return 0 ;; esac; echo $(( n * 1000 )) ;;
    *[mM]) n=${1%[mM]}; case "$n" in ''|*[!0-9]*) return 0 ;; esac; echo $(( n * 1000000 )) ;;
    *) echo "$1" ;;
  esac
}

# window_size SESSION USED: prints "WINDOW SOURCE" where SOURCE is exact or assumed.
# Order: value written by the status line, the auto-compact window variable, then a
# guess (1,000,000 once the context is past 200,000, otherwise 200,000).
window_size() {
  f="$STATE_DIR/$1.window"
  if [ -r "$f" ]; then
    w=$(head -n 1 "$f")
    case "$w" in ''|*[!0-9]*) ;; *) echo "$w exact"; return 0 ;; esac
  fi
  w=$(to_tokens "${CLAUDE_CODE_AUTO_COMPACT_WINDOW:-}")
  if [ -n "$w" ]; then echo "$w exact"; return 0; fi
  if [ "$2" -gt 200000 ]; then echo "1000000 assumed"; else echo "200000 assumed"; fi
}

# project_key DIR: readable and stable name for a project folder.
project_key() {
  base=$(basename "$1" | tr -c 'A-Za-z0-9._-' '_')
  sum=$(printf '%s' "$1" | cksum | cut -d' ' -f1)
  echo "$base-$sum"
}

# notify TITLE MESSAGE: best-effort desktop notification; silent when unsupported.
notify() {
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$2\" with title \"$1\"" >/dev/null 2>&1
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send "$1" "$2" >/dev/null 2>&1
  fi
  return 0
}

log_line() {
  mkdir -p "$GUARD_HOME" 2>/dev/null || return 0
  printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" >> "$GUARD_HOME/guard.log" 2>/dev/null
  return 0
}
