# agent-tab-colors.zsh — Reset Ghostty tab state indicators on prompt
# Sourced from .zshrc. Cleans up after Claude Code agent sessions.

# Export shell PID so hooks can find our state file
export GHOSTTY_TAB_PID=$$

_ghostty_agent_reset() {
    [[ "${TERM_PROGRAM:-}" = "ghostty" ]] || return 0
    local state_file="/tmp/ghostty-tab-$$.state"
    if [[ -f "$state_file" ]]; then
        rm -f "$state_file"
        # Reset tab title to default (clears emoji prefix)
        printf '\033]2;%s\007' "${PWD##*/}" > /dev/tty 2>/dev/null
        # Reset OSC 21 background tint to terminal default
        printf '\033]21;background=\033\\' > /dev/tty 2>/dev/null
    fi
}

_ghostty_agent_cleanup() {
    rm -f "/tmp/ghostty-tab-$$.state" 2>/dev/null
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _ghostty_agent_reset
trap '_ghostty_agent_cleanup' EXIT
