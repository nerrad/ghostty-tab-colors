# agent-tab-colors.zsh — Reset Ghostty tab state indicators on prompt
# Sourced from .zshrc. Cleans up after Claude Code agent sessions.

_ghostty_agent_reset() {
    [[ "${TERM_PROGRAM:-}" = "ghostty" ]] || return 0
    local state_file="/tmp/ghostty-tab-$$.state"
    if [[ -f "$state_file" ]]; then
        rm -f "$state_file"
        # Reset OSC 21 background tint to terminal default
        printf '\033]21;background\033\\' > /dev/tty 2>/dev/null
    fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _ghostty_agent_reset
