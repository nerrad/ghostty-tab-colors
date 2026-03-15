#!/usr/bin/env bash
# uninstall.sh — Remove Ghostty tab color indicators for Claude Code
set -euo pipefail

HOOK_DST="$HOME/.claude/hooks/ghostty-tab-color.sh"
SHELL_DST="$HOME/.config/ghostty/agent-tab-colors.zsh"
SETTINGS="$HOME/.claude/settings.json"
ZSHRC="$HOME/.zshrc"

# --- Remove symlinks ---

if [[ -L "$HOOK_DST" ]] || [[ -f "$HOOK_DST" ]]; then
    rm -f "$HOOK_DST"
    echo "Removed hook: $HOOK_DST"
else
    echo "Hook not found — skipping"
fi

if [[ -L "$SHELL_DST" ]] || [[ -f "$SHELL_DST" ]]; then
    rm -f "$SHELL_DST"
    echo "Removed shell integration: $SHELL_DST"
else
    echo "Shell integration not found — skipping"
fi

# --- Remove hook entries from settings.json ---

if [[ -f "$SETTINGS" ]] && command -v jq &>/dev/null; then
    if jq -e '.hooks // {} | to_entries[] | .value[]? | .hooks[]? | select(.command and (.command | contains("ghostty-tab-color.sh")))' "$SETTINGS" &>/dev/null; then
        PATCHED=$(jq '
            .hooks //= {} |
            .hooks |= with_entries(
                .value = [
                    .value[]
                    | .hooks = [.hooks[] | select(.command // "" | contains("ghostty-tab-color.sh") | not)]
                    | select(.hooks | length > 0)
                ]
                | select(.value | length > 0)
            )
        ' "$SETTINGS")

        printf '%s\n' "$PATCHED" > "${SETTINGS}.tmp"
        mv "${SETTINGS}.tmp" "$SETTINGS"
        echo "Removed hook entries from settings.json"
    else
        echo "No hook entries found in settings.json — skipping"
    fi
else
    echo "Cannot patch settings.json (missing file or jq) — skipping"
fi

# --- Remove source line from .zshrc ---

if [[ -f "$ZSHRC" ]] && grep -qF "agent-tab-colors.zsh" "$ZSHRC"; then
    # Remove the source line and the comment above it
    sed -i '' '/# Ghostty agent tab color indicators/d' "$ZSHRC"
    sed -i '' '/agent-tab-colors\.zsh/d' "$ZSHRC"
    echo "Removed source line from .zshrc"
else
    echo "Source line not in .zshrc — skipping"
fi

# --- Clean up state files ---

rm -f /tmp/ghostty-tab-* 2>/dev/null || true
echo "Cleaned up state files"

# --- Done ---

echo ""
echo "Uninstall complete."
echo "Open a new terminal tab to fully deactivate shell integration."
