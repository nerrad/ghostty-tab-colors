# agent-tab-colors.zsh — Reset Ghostty tab state indicators on prompt
# Sourced from .zshrc. Cleans up after Claude Code agent sessions.

# Export shell PID so hooks can find our state file
export GHOSTTY_TAB_PID=$$

_ghostty_agent_reset() {
    [[ "${TERM_PROGRAM:-}" = "ghostty" ]] || return 0
    local state_file="/tmp/ghostty-tab-$$.state"
    if [[ -f "$state_file" ]]; then
        local current_state
        current_state="$(cat "$state_file" 2>/dev/null)"
        # Only reset the "working" state (orange tint from active tool use).
        # Completed, error, and waiting states persist until the next
        # SessionStart hook overwrites them or the shell exits.
        if [[ "$current_state" = "working" ]]; then
            rm -f "$state_file"
            printf '\033]2;%s\007' "${PWD##*/}" > /dev/tty 2>/dev/null
            printf '\033]21;background=\033\\' > /dev/tty 2>/dev/null
        fi
    fi
}

_ghostty_agent_cleanup() {
    rm -f "/tmp/ghostty-tab-$$.state" 2>/dev/null
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _ghostty_agent_reset
trap '_ghostty_agent_cleanup' EXIT
