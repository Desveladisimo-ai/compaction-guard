#!/bin/sh
# Tests for the Compaction Guard scripts. Run: sh tests/run-tests.sh
# Uses a temporary COMPACTION_GUARD_HOME and fake transcripts; touches nothing else.
ROOT=$(cd "$(dirname "$0")/.." && pwd)
S="$ROOT/plugins/compaction-guard/scripts"
PASS=0; FAIL=0
T=$(mktemp -d) || exit 1
trap 'rm -rf "${T:?}"' EXIT
export COMPACTION_GUARD_HOME="$T/home"
unset CLAUDE_CODE_AUTO_COMPACT_WINDOW

ok()   { PASS=$((PASS+1)); echo "ok   $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL $1"; echo "     $2"; }
check() { # name, expected substring, actual
  case "$3" in *"$2"*) ok "$1" ;; *) bad "$1" "expected to contain: $2 | got: $3" ;; esac
}
absent() { # name, forbidden substring, actual
  case "$3" in *"$2"*) bad "$1" "must not contain: $2 | got: $3" ;; *) ok "$1" ;; esac
}
eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1" "expected [$2] got [$3]"; }

# transcript USED_TOKENS -> path of a fake transcript whose last message used that many
transcript() {
  f="$T/t-$1.jsonl"
  {
    echo '{"type":"user","message":{"content":"hi"}}'
    printf '{"type":"assistant","isSidechain":false,"message":{"usage":{"input_tokens":2,"cache_creation_input_tokens":1000,"cache_read_input_tokens":%s,"output_tokens":5},"model":"m"}}\n' $(( $1 - 1002 ))
    echo '{"type":"permission-mode","permissionMode":"auto"}'
  } > "$f"
  echo "$f"
}
hook_in() { # session transcript trigger_or_source
  printf '{"session_id":"%s","transcript_path":"%s","cwd":"%s","hook_event_name":"X","trigger":"%s","source":"%s"}' "$1" "$2" "$T/proj" "$3" "$3"
}

# ---- context_used / window_size -------------------------------------------------
. "$S/lib.sh"
eq "context_used sums input and cache" 150000 "$(context_used "$(transcript 150000)")"
eq "context_used is empty for a missing file" "" "$(context_used "$T/none.jsonl")"
printf '{"type":"assistant","isSidechain":true,"message":{"usage":{"input_tokens":1,"cache_creation_input_tokens":1,"cache_read_input_tokens":9}}}\n' > "$T/side.jsonl"
eq "context_used ignores subagent lines" "" "$(context_used "$T/side.jsonl")"
eq "window assumed 200k below 200k" "200000 assumed" "$(window_size s1 150000)"
eq "window assumed 1M above 200k" "1000000 assumed" "$(window_size s1 250000)"
CLAUDE_CODE_AUTO_COMPACT_WINDOW=500k; eq "window from the environment variable" "500000 exact" "$(window_size s1 150000)"; unset CLAUDE_CODE_AUTO_COMPACT_WINDOW
mkdir -p "$STATE_DIR"; echo 1000000 > "$STATE_DIR/s2.window"
eq "window from the status line file" "1000000 exact" "$(window_size s2 150000)"
eq "project_key is stable" "$(project_key /a/b)" "$(project_key /a/b)"

# ---- pre-compact -----------------------------------------------------------------
out=$(hook_in s3 "$(transcript 150000)" manual | sh "$S/pre-compact.sh" 2>&1); rc=$?
eq "manual compaction is allowed" 0 "$rc"
out=$(hook_in s3 "$(transcript 150000)" auto | sh "$S/pre-compact.sh" 2>&1 >/dev/null); rc=$?
eq "auto compaction at 75% is blocked (exit 2)" 2 "$rc"
check "block message goes to stderr" "blocked an automatic compaction at 75%" "$out"
[ -r "$STATE_DIR/s3.blocked" ] && ok "block record written" || bad "block record written" "missing"
hook_in s4 "$(transcript 195000)" auto | sh "$S/pre-compact.sh" >/dev/null 2>&1; eq "auto compaction at 97% (above ceiling) is allowed" 0 $?
hook_in s5 "$T/missing.jsonl" auto | sh "$S/pre-compact.sh" >/dev/null 2>&1; eq "unknown context size fails open" 0 $?
echo 1000000 > "$STATE_DIR/s6.window"
hook_in s6 "$(transcript 150000)" auto | sh "$S/pre-compact.sh" >/dev/null 2>&1; eq "exact 1M window: 15% is blocked" 2 $?
hook_in s7 "$(transcript 960000)" auto | sh "$S/pre-compact.sh" >/dev/null 2>&1; eq "above 95% of an assumed 1M window is allowed" 0 $?
check "log records the block" "blocked: automatic compaction at 75%" "$(cat "$GUARD_HOME/guard.log")"

# ---- prompt hook -----------------------------------------------------------------
out=$(hook_in p1 "$(transcript 50000)" x | sh "$S/prompt.sh"); eq "silent below the first step" "" "$out"
out=$(hook_in p2 "$(transcript 120000)" x | sh "$S/prompt.sh"); check "step line when 100k is crossed" "crossed 100k tokens" "$out"
out=$(hook_in p2 "$(transcript 130000)" x | sh "$S/prompt.sh"); eq "step line is not repeated" "" "$out"
out=$(hook_in p3 "$(transcript 150000)" x | sh "$S/prompt.sh"); check "warning at 70%" "CONTEXT WARNING" "$out"
check "warning carries the gate check" "compaction-guard:wrap-up" "$out"
out=$(hook_in p4 "$(transcript 175000)" x | sh "$S/prompt.sh"); check "alert at 85%" "CONTEXT ALERT" "$out"
out=$(hook_in p5 "$(transcript 150000)" x | sh "$S/prompt.sh"); check "assumed window is disclosed" "window size is assumed" "$out"
echo 1000000 > "$STATE_DIR/p6.window"
out=$(hook_in p6 "$(transcript 150000)" x | sh "$S/prompt.sh"); absent "no assumption note with an exact window" "assumed" "$out"
printf '2026-11-06T00:00:00Z 24 240000\n' > "$STATE_DIR/p7.blocked"
out=$(hook_in p7 "$(transcript 240000)" x | sh "$S/prompt.sh")
check "tells the assistant a block happened" "blocked an automatic compaction at 2026-11-06T00:00:00Z" "$out"
[ -e "$STATE_DIR/p7.blocked" ] && bad "block record is consumed" "still there" || ok "block record is consumed"
echo 1000000 > "$STATE_DIR/p8.window"; printf '2026-11-06T00:00:00Z 20 200000\n' > "$STATE_DIR/p8.blocked"
out=$(hook_in p8 "$(transcript 200000)" x | sh "$S/prompt.sh"); check "no wrap-up needed at low usage" "No wrap-up is needed" "$out"
printf '{"transcript_path":"%s"}' "$(transcript 150000)" | sh "$S/prompt.sh" >/dev/null 2>&1; eq "missing session id exits quietly" 0 $?

# ---- session start ---------------------------------------------------------------
mkdir -p "$T/proj"
out=$(hook_in ss1 "" startup | sh "$S/session-start.sh"); check "first run notice" "Compaction Guard is active" "$out"
out=$(hook_in ss1 "" startup | sh "$S/session-start.sh"); eq "first run notice only once" "" "$out"
hdir="$GUARD_HOME/handoffs/$(project_key "$T/proj")"; mkdir -p "$hdir"
printf '# Handoff\n## Goal\nFinish the report\n## Next step\nRun the tests\n' > "$hdir/pending.md"
out=$(hook_in ss2 "" startup | sh "$S/session-start.sh")
check "pending handoff is injected" "Finish the report" "$out"
check "injection asks for a one-line confirmation" "Continuing from the handoff" "$out"
[ -e "$hdir/pending.md" ] && bad "handoff is archived" "pending still there" || ok "handoff is archived"
[ -n "$(ls "$hdir/archive" 2>/dev/null)" ] && ok "archive holds the handoff" || bad "archive holds the handoff" "empty"
out=$(hook_in ss3 "" startup | sh "$S/session-start.sh"); eq "a consumed handoff is not injected again" "" "$out"
printf '# Handoff\nold\n' > "$hdir/pending.md"; touch -t 202501010000 "$hdir/pending.md"
out=$(hook_in ss4 "" startup | sh "$S/session-start.sh"); eq "an expired handoff is not injected" "" "$out"
rm -f "$hdir/pending.md"
mkdir -p "$GUARD_HOME/handoffs/other-1"; printf '# Handoff\nfor another project\n' > "$GUARD_HOME/handoffs/other-1/pending.md"
out=$(hook_in ss5 "" startup | sh "$S/session-start.sh"); eq "another project's handoff is not injected" "" "$out"

# ---- handoff-path and status line ------------------------------------------------
p=$(cd "$T/proj" && sh "$S/handoff-path.sh")
check "handoff path is under the guard home" "$GUARD_HOME/handoffs/" "$p"
[ -d "$(dirname "$p")/archive" ] && ok "handoff folder created" || bad "handoff folder created" "missing"
sl=$(printf '{"session_id":"sl1","context_window":{"context_window_size":1000000,"current_usage":{"input_tokens":2,"cache_creation_input_tokens":3000,"cache_read_input_tokens":330000}}}' | sh "$S/statusline.sh")
eq "status line gauge" "ctx 33%  333k/1000k  left 666k" "$sl"
eq "status line records the window" 1000000 "$(cat "$STATE_DIR/sl1.window")"
sl=$(printf '{"session_id":"sl2"}' | sh "$S/statusline.sh"); eq "status line without data" "ctx n/a" "$sl"

echo; echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
