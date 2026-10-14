# Zsh prompt with Git status, an optional Trivy indicator, and the previous
# command exit status.
#
# Source this file from ~/.zshrc.
#
# Dependencies:
#   - get_git_custom_status (optional): if defined, its output is embedded in
#     the prompt. When it is missing, the Git segment is omitted silently.
#   - TRIVY_PROMPT_ICON (optional): when set, its value is appended.
autoload -Uz add-zsh-hook

typeset -g OPSA_PROMPT_ERROR=""

_opsa_capture_exit() {
    local rc=$?
    case "$rc" in
        0)   OPSA_PROMPT_ERROR="" ;;
        1)   OPSA_PROMPT_ERROR="%F{red}❌%f" ;;
        2)   OPSA_PROMPT_ERROR="%F{yellow}⚠️%f" ;;
        126) OPSA_PROMPT_ERROR="%F{red}🚫%f" ;;
        127) OPSA_PROMPT_ERROR="%F{yellow}🔎%f" ;;
        130) OPSA_PROMPT_ERROR="%F{yellow}🛑%f" ;;
        137) OPSA_PROMPT_ERROR="%F{red}💀%f" ;;
        143) OPSA_PROMPT_ERROR="%F{yellow}🔴%f" ;;
        *)   OPSA_PROMPT_ERROR="%F{red}✗%f" ;;
    esac
}

_opsa_update_prompt() {
    local git_status=""
    if (( $+functions[get_git_custom_status] )); then
        git_status="$(get_git_custom_status)"
    fi

    local prompt_extra=""
    [[ -n "${TRIVY_PROMPT_ICON:-}" ]] && prompt_extra+=" ${TRIVY_PROMPT_ICON}"
    [[ -n "$OPSA_PROMPT_ERROR" ]] && prompt_extra+=" ${OPSA_PROMPT_ERROR}"

    local git_segment=""
    [[ -n "$git_status" ]] && git_segment=" ${git_status}"

    PROMPT="%F{cyan}%n@%m%f:%F{yellow}%~%f${git_segment}${prompt_extra} %# "
}

# Keep reloads idempotent: remove any previously registered hooks first.
add-zsh-hook -d precmd _opsa_capture_exit 2>/dev/null || true
add-zsh-hook -d precmd _opsa_update_prompt 2>/dev/null || true
add-zsh-hook precmd _opsa_capture_exit
add-zsh-hook precmd _opsa_update_prompt
