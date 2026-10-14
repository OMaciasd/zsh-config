#!/usr/bin/env zsh
set -u

root=${0:A:h:h}
source "$root/config/prompt.zsh"

fail() {
    print -u2 "FAIL: $*"
    exit 1
}

foreign_precmd() {
    # Mimic a third-party precmd hook that changes $? after running.
    true
}

# Registration must keep _opsa_capture_exit first, even for late hooks.
precmd_functions+=( foreign_precmd )

# A failing command followed by a hook that clobbers $? must keep the
# original failure symbol.
( exit 127 )
for _opsa_hook in $precmd_functions; do
    "$_opsa_hook"
done
[[ "$OPSA_PROMPT_ERROR" == '%F{yellow}🔎%f' ]] || fail "foreign precmd changed reported status (expected 127 symbol)"

# A successful command stays cleared even if a later hook fails.
( exit 0 ) || true
foreign_precmd() { false; }
for _opsa_hook in $precmd_functions; do
    "$_opsa_hook"
done
[[ -z "$OPSA_PROMPT_ERROR" ]] || fail "successful command should clear indicator"

# No duplicate hooks after re-sourcing.
source "$root/config/prompt.zsh"
source "$root/config/prompt.zsh"
local capture_count=0 hook
for hook in $precmd_functions; do
    [[ "$hook" == "_opsa_capture_exit" ]] && (( capture_count++ ))
done
[[ "$capture_count" -eq 1 ]] || fail "duplicate capture hook ($capture_count)"

print "PASS: precmd integration"
