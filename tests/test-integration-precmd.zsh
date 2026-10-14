#!/usr/bin/env zsh
set -u

root=${0:A:h:h}
config="$root/config/prompt.zsh"

fail() {
    print -u2 "FAIL: $*"
    exit 1
}

command -v script >/dev/null 2>&1 || fail "required command not found: script"

workdir=$(mktemp -d 2>/dev/null) || fail "mktemp failed"
trap 'rm -rf "$workdir"' EXIT

zdot="$workdir/zdot"
mkdir -p "$zdot" || fail "mkdir failed"
cat > "$zdot/.zshrc" <<'INNEREOF'
autoload -Uz add-zsh-hook
foreign_precmd() {
    if [[ "${FOREIGN_MODE:-true}" == true ]]; then
        true
    else
        false
    fi
}
add-zsh-hook precmd foreign_precmd
source "${OPSA_CONFIG:?}"
INNEREOF

cat > "$workdir/session-true.cmd" <<'INNEREOF'
missing_command_127_test_value
print "MARKER_MISSING_127_RESULT=${OPSA_PROMPT_ERROR}EXITSTATUS127=$?"
true
print "MARKER_SUCCESS_RESULT=${OPSA_PROMPT_ERROR}EXITSTATUS0=$?"
false
print "MARKER_ORIGINAL_FALSE_TRUEHOOK_RESULT=${OPSA_PROMPT_ERROR}EXITSTATUS1=$?"
source "${OPSA_CONFIG}"
source "${OPSA_CONFIG}"
source "${OPSA_CONFIG}"
() {
    local capture_count=0 update_count=0 hook
    for hook in $precmd_functions; do
        [[ "$hook" == "_opsa_capture_exit" ]] && (( capture_count++ ))
        [[ "$hook" == "_opsa_update_prompt" ]] && (( update_count++ ))
    done
    print "IDEMPOTENCY_COUNTS=${capture_count}:${update_count}"
}
exit
INNEREOF

cat > "$workdir/session-false.cmd" <<'INNEREOF'
true
print "MARKER_SUCCESS_FALSEHOOK_RESULT=${OPSA_PROMPT_ERROR}EXITSTATUS0=$?"
exit
INNEREOF

run_session() {
    local mode=$1 outfile=$2 cmdfile=$3
    local session_status
    FOREIGN_MODE="$mode" OPSA_CONFIG="$config" ZDOTDIR="$zdot" \
        script -e -q -c "env ZDOTDIR=$zdot FOREIGN_MODE=$mode OPSA_CONFIG=$config zsh -i" "$outfile" \
        <"$cmdfile" >/dev/null 2>&1
    session_status=$?
    (( session_status == 0 )) || fail "script could not run Zsh (exit status $session_status)"
    [[ -s "$outfile" ]] || fail "script produced no output"
    tr -d '\r' < "$outfile" > "${outfile}.clean"
}

true_out="$workdir/session-true.out"
false_out="$workdir/session-false.out"
run_session true "$true_out" "$workdir/session-true.cmd"
run_session false "$false_out" "$workdir/session-false.cmd"

true_clean="${true_out}.clean"
false_clean="${false_out}.clean"

grep -Eq '^MARKER_MISSING_127_RESULT=.*🔎.*EXITSTATUS127=127$' "$true_clean" \
    || fail "code 127 was not shown by precmd or its previous exit status was not 127"
grep -Eq '^MARKER_SUCCESS_RESULT=EXITSTATUS0=0$' "$true_clean" \
    || fail "successful command did not clear the indicator"
grep -Eq '^MARKER_ORIGINAL_FALSE_TRUEHOOK_RESULT=.*❌.*EXITSTATUS1=1$' "$true_clean" \
    || fail "posterior true hook changed the indicator for a failing command"
grep -Eq '^MARKER_SUCCESS_FALSEHOOK_RESULT=EXITSTATUS0=0$' "$false_clean" \
    || fail "posterior false hook changed the indicator for a successful command"
grep -Eq '^IDEMPOTENCY_COUNTS=1:1$' "$true_clean" \
    || fail "reloading config did not leave exactly one of each OpsAuto hook"

print "PASS: precmd integration"
