#!/usr/bin/env bash
# ghostty-tab-color.sh — Claude Code hook for Ghostty tab state indicators
# Usage: ghostty-tab-color.sh <working|waiting|completed|notification>
# Stdin: JSON from Claude Code hook system (drained to avoid broken pipe)
set -euo pipefail

# Only run in Ghostty
[[ "${TERM_PROGRAM:-}" = "ghostty" ]] || exit 0

STATE="${1:-}"
[[ -n "$STATE" ]] || exit 0

# Drain stdin (Claude Code sends JSON; ignoring it causes broken pipe)
INPUT=$(cat)

# For notification events, only act on permission_prompt / idle_prompt
if [[ "$STATE" = "notification" ]]; then
    NTYPE=$(printf '%s' "$INPUT" | grep -o '"notification_type":"[^"]*"' | head -1 | cut -d'"' -f4)
    case "$NTYPE" in
        permission_prompt|idle_prompt) STATE="waiting" ;;
        *) exit 0 ;;
    esac
fi

# State debouncing — only act on transitions
STATE_FILE="/tmp/ghostty-tab-${PPID}.state"
if [[ -f "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE")" = "$STATE" ]]; then
    exit 0
fi
printf '%s' "$STATE" > "$STATE_FILE"

# Map state to emoji and background tint
case "$STATE" in
    working)
        EMOJI=$'\xf0\x9f\x9f\xa0'  # 🟠
        BG_TINT="#1f1608"
        ;;
    waiting)
        EMOJI=$'\xf0\x9f\x9f\xa1'  # 🟡
        BG_TINT="#1f1a08"
        ;;
    completed)
        EMOJI=$'\xf0\x9f\x9f\xa2'  # 🟢
        BG_TINT="#0d1f0d"
        ;;
    *)
        exit 0
        ;;
esac

# Layer 1: Tab title emoji prefix via OSC 2
printf '\033]2;%s Claude Code\007' "$EMOJI" > /dev/tty 2>/dev/null || true

# Layer 2: Surface background tint via OSC 21 (Kitty color protocol)
printf '\033]21;background=%s\033\\' "$BG_TINT" > /dev/tty 2>/dev/null || true
