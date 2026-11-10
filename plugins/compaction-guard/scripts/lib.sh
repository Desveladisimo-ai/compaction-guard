#!/bin/sh
# shellcheck disable=SC2034  # the settings below are used by the scripts that source this file
# Shared helpers for the Compaction Guard hooks. POSIX sh. Needs only sed, grep,
# tail, awk, date, cksum and find, which every macOS and Linux install has.

# Where state and handoffs live. Stable across plugin updates and uninstalls.
GUARD_HOME="${COMPACTION_GUARD_HOME:-$HOME/.claude/compaction-guard}"
# A path with a quote, dollar, backtick, backslash or newline would break the shell text
# this plugin hands to the assistant; use the default instead.
case "$GUARD_HOME" in
  *[\"\'\$\`\\]*|*"
"*) GUARD_HOME="$HOME/.claude/compaction-guard" ;;
esac
STATE_DIR="$GUARD_HOME/state"

# Everything the plugin writes is private to the user: handoffs hold what was worked on
# and are read back into the assistant's context, so nobody else may read or change them.
umask 077
# Tighten a folder created by an earlier version (default umask), once.
# Only a real folder owned by the current user is touched; a symlink or someone else's is not.
if [ -d "$GUARD_HOME" ] && [ ! -L "$GUARD_HOME" ] && [ ! -f "$GUARD_HOME/.private" ] \
  && [ -n "$(find "$GUARD_HOME" -maxdepth 0 -user "$(id -un)" 2>/dev/null)" ]; then
  chmod -R go-rwx "$GUARD_HOME" 2>/dev/null && : > "$GUARD_HOME/.private"
fi

# mark_active SID: records that the hooks run in this session. The optional status line
# reads it, so a session that never loaded the plugin (one opened before the install)
# can say so instead of looking protected.
mark_active() {
  [ -n "$1" ] || return 0
  mkdir -p "$STATE_DIR" 2>/dev/null
  : > "$STATE_DIR/$1.active" 2>/dev/null
  return 0
}

# safe_id VALUE: VALUE reduced to letters, digits, dot, dash and underscore, so an
# identifier from outside can never form a path.
safe_id() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'
}

# num_or VALUE DEFAULT MIN: VALUE as a plain whole number of at least MIN (leading zeros
# dropped), otherwise DEFAULT. Settings come from the environment, so nothing is trusted
# to be a number before it reaches arithmetic.
num_or() {
  v=$(printf '%s' "$1" | sed 's/^0*\([0-9]\)/\1/')
  case "$v" in ''|*[!0-9]*) echo "$2"; return 0 ;; esac
  if [ "$v" -ge "$3" ] 2>/dev/null; then echo "$v"; else echo "$2"; fi
}

# regular_file PATH: a plain file that is not a symlink (never a pipe, folder or link).
regular_file() {
  [ -f "$1" ] && [ ! -L "$1" ]
}

# Thresholds, in percent of the context window. Override with environment variables.
STEP_TOKENS=$(num_or "${COMPACTION_GUARD_STEP_TOKENS:-}" 100000 1)
WARN_PCT=$(num_or "${COMPACTION_GUARD_WARN_PCT:-}" 70 1)
ALERT_PCT=$(num_or "${COMPACTION_GUARD_ALERT_PCT:-}" 85 1)
CEILING_PCT=$(num_or "${COMPACTION_GUARD_CEILING_PCT:-}" 95 1)
HANDOFF_MAX_DAYS=$(num_or "${COMPACTION_GUARD_HANDOFF_DAYS:-}" 14 1)
OFFER_MAX=$(num_or "${COMPACTION_GUARD_OFFER_MAX:-}" 3 0)
MONITOR_WAIT=$(num_or "${COMPACTION_GUARD_MONITOR_WAIT:-}" 15 1)
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

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
  if regular_file "$f"; then
    w=$(num_or "$(head -n 1 "$f")" "" 1)
    if [ -n "$w" ]; then echo "$w exact"; return 0; fi
  fi
  w=$(num_or "$(to_tokens "${CLAUDE_CODE_AUTO_COMPACT_WINDOW:-}")" "" 1)
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
  # Keep the log small: past 200 KB, keep the last 500 lines.
  if regular_file "$GUARD_HOME/guard.log" && [ "$(wc -c < "$GUARD_HOME/guard.log" | tr -d ' ')" -gt 200000 ]; then
    tail -n 500 "$GUARD_HOME/guard.log" > "$GUARD_HOME/guard.log.tmp" 2>/dev/null \
      && mv "$GUARD_HOME/guard.log.tmp" "$GUARD_HOME/guard.log" 2>/dev/null
  fi
  printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" >> "$GUARD_HOME/guard.log" 2>/dev/null
  return 0
}

# gauge_installed: true when the user's settings already point at the gauge script.
gauge_installed() {
  grep -q 'compaction-guard/statusline.sh' "$CLAUDE_DIR/settings.json" 2>/dev/null
}

# phys_key DIR: project_key of the physical path, so the hook and the monitor agree
# even when one of them sees a symbolic link (for example /tmp and /private/tmp).
phys_key() {
  project_key "$(cd "$1" 2>/dev/null && pwd -P || echo "$1")"
}

