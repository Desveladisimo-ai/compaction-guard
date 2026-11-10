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
# On Windows (Git Bash) file modes and symlinks are not POSIX: those checks are skipped,
# and the state lives under the user's profile folder, which Windows restricts by ACL.
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) WIN=1 ;; *) WIN=0 ;; esac
skipwin() { [ "$WIN" = 1 ] || return 1; ok "skipped on Windows: $1"; return 0; }
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
check "tells the assistant a block happened, with the percentage" "blocked an automatic compaction at 24% of the window" "$out"
[ -e "$STATE_DIR/p7.blocked" ] && bad "block record is consumed" "still there" || ok "block record is consumed"
echo 1000000 > "$STATE_DIR/p8.window"; printf '2026-11-06T00:00:00Z 20 200000\n' > "$STATE_DIR/p8.blocked"
out=$(hook_in p8 "$(transcript 200000)" x | sh "$S/prompt.sh"); check "no wrap-up needed at low usage" "No wrap-up is needed" "$out"
printf '{"transcript_path":"%s"}' "$(transcript 150000)" | sh "$S/prompt.sh" >/dev/null 2>&1; eq "missing session id exits quietly" 0 $?

# ---- session start ---------------------------------------------------------------
mkdir -p "$T/proj"
export CLAUDE_CONFIG_DIR="$T/claude"; mkdir -p "$CLAUDE_CONFIG_DIR"
out=$(hook_in o1 "" startup | sh "$S/session-start.sh"); check "gauge offer in the first session" "Start your first reply" "$out"
check "the offer names the skill" "/compaction-guard:status-line" "$out"
out=$(hook_in o2 "" startup | sh "$S/session-start.sh"); check "the offer repeats when no message was sent" "Start your first reply" "$out"
hook_in o2 "" x | sh "$S/prompt.sh" >/dev/null
eq "a first message counts one offer shown" 1 "$(cat "$STATE_DIR/gauge-offer")"
hook_in o2 "" x | sh "$S/prompt.sh" >/dev/null
eq "a second message in the same session counts nothing more" 1 "$(cat "$STATE_DIR/gauge-offer")"
hook_in o3 "" startup | sh "$S/session-start.sh" >/dev/null; hook_in o3 "" x | sh "$S/prompt.sh" >/dev/null
hook_in o4 "" startup | sh "$S/session-start.sh" >/dev/null; hook_in o4 "" x | sh "$S/prompt.sh" >/dev/null
eq "three offers shown" 3 "$(cat "$STATE_DIR/gauge-offer")"
out=$(hook_in o5 "" startup | sh "$S/session-start.sh"); absent "no fourth offer" "Start your first reply" "$out"
rm -f "${STATE_DIR:?}/gauge-offer" "${STATE_DIR:?}/gauge-offer.pending"
printf '{"statusLine":{"type":"command","command":"/x/.claude/compaction-guard/statusline.sh"}}' > "$CLAUDE_CONFIG_DIR/settings.json"
out=$(hook_in o6 "" startup | sh "$S/session-start.sh"); absent "no offer when the gauge is already installed" "Start your first reply" "$out"
eq "state becomes done" done "$(cat "$STATE_DIR/gauge-offer")"
rm -f "${CLAUDE_CONFIG_DIR:?}/settings.json"; echo declined > "$STATE_DIR/gauge-offer"
out=$(hook_in o7 "" startup | sh "$S/session-start.sh"); absent "no offer after the user declined" "Start your first reply" "$out"
hdir="$GUARD_HOME/handoffs/$(project_key "$T/proj")"; mkdir -p "$hdir"
printf '# Handoff\n## Goal\nFinish the report\n## Next step\nRun the tests\n' > "$hdir/pending.md"
out=$(hook_in ss2 "" startup | sh "$S/session-start.sh")
check "pending handoff is injected" "Finish the report" "$out"
check "injection tells the assistant to announce the handoff" "Continuing from the handoff" "$out"
check "the announcement is a statement the user can interrupt" "Say stop if you want something else" "$out"
absent "the announcement does not ask a question it will not wait for" "OK?" "$out"
check "a thin handoff is announced as having nothing to continue" "nothing to continue" "$out"
[ -e "$hdir/pending.md" ] && bad "handoff is archived" "pending still there" || ok "handoff is archived"
[ -n "$(ls "$hdir/archive" 2>/dev/null)" ] && ok "archive holds the handoff" || bad "archive holds the handoff" "empty"
out=$(hook_in ss3 "" startup | sh "$S/session-start.sh"); eq "a consumed handoff is not injected again" "" "$out"
printf '# Handoff\nold\n' > "$hdir/pending.md"; touch -t 202501010000 "$hdir/pending.md"
out=$(hook_in ss4 "" startup | sh "$S/session-start.sh"); eq "an expired handoff is not injected" "" "$out"
rm -f "$hdir/pending.md"
mkdir -p "$GUARD_HOME/handoffs/other-1"; printf '# Handoff\nfor another project\n' > "$GUARD_HOME/handoffs/other-1/pending.md"
out=$(hook_in ss5 "" startup | sh "$S/session-start.sh"); eq "another project's handoff is not injected" "" "$out"

# ---- announce monitor --------------------------------------------------------
export COMPACTION_GUARD_MONITOR_ONCE=1 COMPACTION_GUARD_MONITOR_WAIT=1
rm -f "${STATE_DIR:?}"/announce.*
out=$(cd "$T/proj" && sh "$S/announce-monitor.sh"); eq "monitor stays silent without a handoff" "" "$out"
mkdir -p "$T/mproj"; mh="$GUARD_HOME/handoffs/$(project_key "$T/mproj")"; mkdir -p "$mh"
printf '# Handoff\n## Goal\nx\n## Next step\ny\n' > "$mh/pending.md"
printf '{"session_id":"m1","cwd":"%s"}' "$T/mproj" | sh "$S/session-start.sh" >/dev/null
[ -n "$(ls "$STATE_DIR"/announce.* 2>/dev/null)" ] && ok "loading a handoff leaves an announce marker" || bad "loading a handoff leaves an announce marker" "no marker"
out=$(cd "$T/mproj" && sh "$S/announce-monitor.sh"); check "monitor prints one line when a handoff was loaded" "handoff from the previous session is loaded" "$out"
[ -z "$(ls "$STATE_DIR"/announce.* 2>/dev/null)" ] && ok "the marker is consumed" || bad "the marker is consumed" "still there"
out=$(cd "$T/mproj" && sh "$S/announce-monitor.sh"); eq "the line is printed only once" "" "$out"
unset COMPACTION_GUARD_MONITOR_ONCE COMPACTION_GUARD_MONITOR_WAIT

# ---- handoff-path and status line ------------------------------------------------
p=$(cd "$T/proj" && sh "$S/handoff-path.sh")
check "handoff path is under the guard home" "$GUARD_HOME/handoffs/" "$p"
[ -d "$(dirname "$p")/archive" ] && ok "handoff folder created" || bad "handoff folder created" "missing"
: > "$STATE_DIR/sl1.active"
sl=$(printf '{"session_id":"sl1","context_window":{"context_window_size":1000000,"current_usage":{"input_tokens":2,"cache_creation_input_tokens":3000,"cache_read_input_tokens":330000}}}' | sh "$S/statusline.sh")
eq "status line gauge" "ctx 33%  333k/1000k  left 666k" "$sl"
eq "status line records the window" 1000000 "$(cat "$STATE_DIR/sl1.window")"
sl=$(printf '{"session_id":"sl2"}' | sh "$S/statusline.sh"); eq "status line without data" "ctx n/a" "$sl"

# ---- privacy and identifiers -------------------------------------------------------
mode() { ls -ld "$1" | cut -c1-10; }
rm -rf "$T/home"
hook_in priv1 "$(transcript 150000)" auto | sh "$S/pre-compact.sh" >/dev/null 2>&1
skipwin "state folder is private to the user" || eq "state folder is private to the user" "drwx------" "$(mode "$T/home/state")"
skipwin "state files are private to the user" || eq "state files are private to the user" "-rw-------" "$(mode "$T/home/state/priv1.blocked")"
sh "$S/handoff-path.sh" >/dev/null
skipwin "handoff folder is private to the user" || eq "handoff folder is private to the user" "drwx------" "$(mode "$(find "$T/home/handoffs" -mindepth 1 -maxdepth 1 -type d | head -n 1)")"
# an install made by an earlier version (default umask) is tightened once
mkdir -p "$T/old/state"; chmod 755 "$T/old" "$T/old/state"; echo x > "$T/old/state/f"; chmod 644 "$T/old/state/f"
COMPACTION_GUARD_HOME="$T/old" sh -c '. "$1"' sh "$S/lib.sh"
skipwin "older install: folder tightened" || eq "older install: folder tightened" "drwx------" "$(mode "$T/old/state")"
skipwin "older install: file tightened" || eq "older install: file tightened" "-rw-------" "$(mode "$T/old/state/f")"
# a session id can never form a path
hook_in "../../escape" "$(transcript 150000)" auto | sh "$S/pre-compact.sh" >/dev/null 2>&1
[ -e "$T/escape.blocked" ] || [ -e "$T/../escape.blocked" ] && bad "session id stays inside the state folder" "file written outside" || ok "session id stays inside the state folder"
[ -f "$T/home/state/.._.._escape.blocked" ] && ok "session id is sanitized into one file name" || bad "session id is sanitized into one file name" "$(ls "$T/home/state")"

# ---- hardening: settings, file types, text handed to the assistant ----------------
# a bad number never blocks or breaks a hook (it used to: arithmetic errors exit with 2)
rm -rf "$T/hard"; export COMPACTION_GUARD_HOME="$T/hard"; mkdir -p "$T/hard/state"
echo 0 > "$T/hard/state/hz1.window"
hook_in hz1 "$(transcript 195000)" auto | sh "$S/pre-compact.sh" >/dev/null 2>&1; eq "a zero window file is ignored: above the ceiling it allows" 0 $?
hook_in hz2 "$(transcript 195000)" auto | COMPACTION_GUARD_CEILING_PCT=x sh "$S/pre-compact.sh" >/dev/null 2>&1; eq "a bad ceiling falls back to 95 and allows above it" 0 $?
printf '{"session_id":"hz3","transcript_path":"%s","trigger":"auto"}' "$(transcript 195000)" | COMPACTION_GUARD_CEILING_PCT='a[$(touch '"$T"'/pwned)]' sh "$S/pre-compact.sh" >/dev/null 2>&1
[ -e "$T/pwned" ] && bad "a setting cannot run a command" "pwned" || ok "a setting cannot run a command"
hook_in hz4 "$(transcript 150000)" x | COMPACTION_GUARD_STEP_TOKENS='a[$(touch '"$T"'/pwned2)]' sh "$S/prompt.sh" >/dev/null 2>&1; eq "prompt hook ends in success with a hostile setting" 0 $?
[ -e "$T/pwned2" ] && bad "step setting cannot run a command" "pwned" || ok "step setting cannot run a command"
eq "STEP_TOKENS=0 falls back to the default" 100000 "$(COMPACTION_GUARD_STEP_TOKENS=0 sh -c '. "$1"; echo $STEP_TOKENS' sh "$S/lib.sh")"
eq "a number with a leading zero is read as decimal" 8 "$(COMPACTION_GUARD_WARN_PCT=08 sh -c '. "$1"; echo $WARN_PCT' sh "$S/lib.sh")"
eq "OFFER_MAX=0 is honoured" 0 "$(COMPACTION_GUARD_OFFER_MAX=0 sh -c '. "$1"; echo $OFFER_MAX' sh "$S/lib.sh")"
# a state path with shell characters is not used
eq "a home path with a dollar sign is replaced by the default" "$T/hm/.claude/compaction-guard" "$(HOME="$T/hm" COMPACTION_GUARD_HOME='/tmp/x$(id)y' sh -c '. "$1"; echo $GUARD_HOME' sh "$S/lib.sh")"
# the record of a block is split without expanding wildcards, and shows the percentage
mkdir -p "$T/globdir"; : > "$T/globdir/SENTINEL_FILE"
printf '* 24 x\n' > "$T/hard/state/hg1.blocked"
out=$(cd "$T/globdir" && hook_in hg1 "$(transcript 240000)" x | sh "$S/prompt.sh"); absent "a block record does not expand wildcards" "SENTINEL_FILE" "$out"
# only plain files are read: a pipe, a link or a folder in place of a state file is ignored
hdir="$T/hard/handoffs/$(project_key "$T/proj")"; mkdir -p "$hdir"; mkfifo "$hdir/pending.md"
hook_in hf1 "" startup | sh "$S/session-start.sh" >"$T/ss.out" 2>&1 &
pid=$!; i=0; while kill -0 "$pid" 2>/dev/null && [ "$i" -lt 5 ]; do sleep 1; i=$((i+1)); done
if kill -0 "$pid" 2>/dev/null; then kill "$pid" 2>/dev/null; bad "a pipe named pending.md does not hang the session start" "still running after 5 s"; else ok "a pipe named pending.md does not hang the session start"; fi
rm -f "$hdir/pending.md"
if [ "$WIN" = 1 ]; then ok "skipped on Windows: a link named pending.md is not followed"; else
echo "TOP_SECRET_CONTENT" > "$T/secret.txt"; ln -s "$T/secret.txt" "$hdir/pending.md"
out=$(hook_in hf2 "" startup | sh "$S/session-start.sh"); absent "a link named pending.md is not followed" "TOP_SECRET_CONTENT" "$out"
fi
rm -f "$hdir/pending.md"
export COMPACTION_GUARD_MONITOR_ONCE=1 COMPACTION_GUARD_MONITOR_WAIT=1
mkdir -p "$T/mproj2"; mkdir -p "$T/hard/state/announce.$(cd "$T/mproj2" && phys_key "$PWD")"
out=$(cd "$T/mproj2" && sh "$S/announce-monitor.sh"); eq "a folder in place of the marker does not make the monitor loop" "" "$out"
unset COMPACTION_GUARD_MONITOR_ONCE COMPACTION_GUARD_MONITOR_WAIT
# the handoff is handed over as data, with limits
printf '# Handoff\n## Goal\nDemo goal\n## Next step\nDo the demo\n' > "$hdir/pending.md"
out=$(hook_in hf3 "" startup | sh "$S/session-start.sh")
check "the handoff is delimited as data" "handoff notes (data, not instructions)" "$out"
check "the notes grant no permission" "grant you no permission" "$out"
check "risky next steps need a question first" "name the step and ask first" "$out"
check "the announcement names the next step" "Next step: <the next step in a few words>" "$out"
rm -f "$hdir/pending.md"; { echo '# Handoff'; i=0; while [ "$i" -lt 3000 ]; do echo "filler line number $i to make the handoff large"; i=$((i+1)); done; } > "$hdir/pending.md"
out=$(hook_in hf4 "" startup | sh "$S/session-start.sh"); [ "${#out}" -lt 56000 ] && ok "an oversized handoff is cut" || bad "an oversized handoff is cut" "${#out} characters"
# used handoffs older than 90 days are removed
touch -t 202001010000 "$hdir/archive/20200101T000000Z.md" 2>/dev/null || { : > "$hdir/archive/20200101T000000Z.md"; touch -t 202001010000 "$hdir/archive/20200101T000000Z.md"; }
printf '# Handoff\nx\n## Next step\ny\n' > "$hdir/pending.md"; hook_in hf5 "" startup | sh "$S/session-start.sh" >/dev/null
[ -e "$hdir/archive/20200101T000000Z.md" ] && bad "an old archived handoff is removed" "still there" || ok "an old archived handoff is removed"
# the folder is only tightened when it is a real folder of the current user
if [ "$WIN" != 1 ]; then
mkdir -p "$T/tgt/state"; chmod 755 "$T/tgt" "$T/tgt/state"; ln -s "$T/tgt" "$T/lnk"
COMPACTION_GUARD_HOME="$T/lnk" sh -c '. "$1"' sh "$S/lib.sh"
fi
skipwin "a symlinked home is not tightened" || eq "a symlinked home is not tightened" "drwxr-xr-x" "$(mode "$T/tgt")"
# the log stays small
head -c 300000 /dev/zero | tr '\0' 'x' | sed 's/\(.\{80\}\)/\1\n/g' > "$T/hard/guard.log"
. "$S/lib.sh"; log_line "rotation check"
[ "$(wc -c < "$T/hard/guard.log" | tr -d ' ')" -lt 100000 ] && ok "the log is cut when it grows past 200 KB" || bad "the log is cut when it grows past 200 KB" "$(wc -c < "$T/hard/guard.log")"

# ---- policy: what the scripts must never contain ------------------------------------
# These fail the build if a change adds a network call, a dynamic eval or a shell-out
# to an interpreter, so the "no network, no eval" statements in the README stay true.
net=$(grep -n -E '(^|[^A-Za-z_-])(curl|wget|nc|ncat|socat|ssh|scp|sftp|telnet|ftp)( |$)|/dev/(tcp|udp)/' "$S"/*.sh | grep -v '^[^:]*:[0-9]*:[[:space:]]*#' )
eq "scripts make no network calls" "" "$net"
ev=$(grep -n -E '(^|[;&|[:space:]])eval[[:space:]]' "$S"/*.sh | grep -v '^[^:]*:[0-9]*:[[:space:]]*#')
eq "scripts never use eval" "" "$ev"
sudo_use=$(grep -n -E '(^|[^A-Za-z_-])(sudo|su|doas)( |$)' "$S"/*.sh | grep -v '^[^:]*:[0-9]*:[[:space:]]*#')
eq "scripts never escalate privileges" "" "$sudo_use"

# ---- an inactive session is visible (sessions open before the install) -------------
slin='{"session_id":"%s","context_window":{"context_window_size":1000000,"current_usage":{"input_tokens":2,"cache_creation_input_tokens":3000,"cache_read_input_tokens":330000}}}'
rm -rf "$T/act"; export COMPACTION_GUARD_HOME="$T/act"; STATE_DIR="$T/act/state"
sl=$(printf "$slin" ia1 | sh "$S/statusline.sh"); check "no sign of the hooks in a session with tokens: status line says guard OFF" "guard OFF: run /reload-plugins" "$sl"
printf '{"session_id":"ia1","hook_event_name":"SessionStart","source":"startup"}' | sh "$S/mark-active.sh"; eq "mark-active prints nothing" "" "$(printf '{"session_id":"ia1"}' | sh "$S/mark-active.sh")"
sl=$(printf "$slin" ia1 | sh "$S/statusline.sh"); absent "after the SessionStart hook ran, no guard OFF" "guard OFF" "$sl"
sl=$(printf "$slin" ia2 | sh "$S/statusline.sh"); check "a second session without the hooks is flagged" "guard OFF" "$sl"
hook_in ia2 "$(transcript 50000)" x | sh "$S/prompt.sh" >/dev/null
sl=$(printf "$slin" ia2 | sh "$S/statusline.sh"); absent "after a prompt (for example after /reload-plugins) no guard OFF" "guard OFF" "$sl"
sl=$(printf '{"session_id":"ia3","context_window":{"context_window_size":1000000,"current_usage":{"input_tokens":0,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}' | sh "$S/statusline.sh"); absent "a session with no tokens yet is not flagged" "guard OFF" "$sl"
printf '{"session_id":"../../ia4"}' | sh "$S/mark-active.sh"; [ -f "$T/act/state/.._.._ia4.active" ] && ok "mark-active sanitizes the session id" || bad "mark-active sanitizes the session id" "$(ls "$T/act/state")"
skipwin "marker files are private to the user" || eq "marker files are private to the user" "-rw-------" "$(mode "$T/act/state/ia1.active")"
touch -t 202001010000 "$T/act/state/old.active" "$T/act/state/old.step"; echo keep > "$T/act/state/gauge-offer"; touch -t 202001010000 "$T/act/state/gauge-offer"
printf '{"session_id":"ia5"}' | sh "$S/mark-active.sh"
[ -e "$T/act/state/old.active" ] || [ -e "$T/act/state/old.step" ] && bad "old per-session files are removed" "still there" || ok "old per-session files are removed"
[ -e "$T/act/state/gauge-offer" ] && ok "the gauge offer counter is kept" || bad "the gauge offer counter is kept" "removed"
manifest=$(cat "$ROOT/plugins/compaction-guard/hooks/hooks.json"); check "hooks.json registers mark-active for SessionStart" "mark-active.sh" "$manifest"

echo; echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
