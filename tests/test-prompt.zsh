#!/usr/bin/env zsh
set -u

root=${0:A:h:h}
source "$root/config/prompt.zsh"

fail() {
    print -u2 "FAIL: $*"
    exit 1
}

check_code() {
    local code=$1 expected=$2
    ( exit "$code" )
    _opsa_capture_exit
    if [[ "$OPSA_PROMPT_ERROR" != "$expected" ]]; then
        fail "code $code expected [$expected] got [$OPSA_PROMPT_ERROR]"
    fi
}

check_code 0 ''
check_code 1 '%F{red}❌%f'
check_code 2 '%F{yellow}⚠️%f'
check_code 126 '%F{red}🚫%f'
check_code 127 '%F{yellow}🔎%f'
check_code 130 '%F{yellow}🛑%f'
check_code 137 '%F{red}💀%f'
check_code 143 '%F{yellow}🔴%f'
check_code 99 '%F{red}✗%f'

# successful command clears a previous failure
( exit 127 )
_opsa_capture_exit
[[ "$OPSA_PROMPT_ERROR" == '%F{yellow}🔎%f' ]] || fail "setup failed for clear test"
true
_opsa_capture_exit
[[ -z "$OPSA_PROMPT_ERROR" ]] || fail "successful command did not clear indicator"

# reload must not duplicate hooks
source "$root/config/prompt.zsh"
local count=0 entry
for entry in $precmd_functions; do
    [[ "$entry" == "_opsa_capture_exit" ]] && (( count++ ))
done
[[ "$count" -eq 1 ]] || fail "duplicate _opsa_capture_exit hook ($count)"

# update prompt works without get_git_custom_status
if (( $+functions[get_git_custom_status] )); then
    unset -f get_git_custom_status
fi
_opsa_update_prompt
[[ -n "$PROMPT" ]] || fail "PROMPT not set"

print "PASS: prompt behavior"
