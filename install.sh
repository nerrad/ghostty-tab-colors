#!/usr/bin/env bash
# install.sh — Install Ghostty tab color indicators for Claude Code
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SRC="$SCRIPT_DIR/hooks/ghostty-tab-color.sh"
HOOK_DST="$HOME/.claude/hooks/ghostty-tab-color.sh"
SHELL_SRC="$SCRIPT_DIR/shell/agent-tab-colors.zsh"
SHELL_DST="$HOME/.config/ghostty/agent-tab-colors.zsh"
SETTINGS="$HOME/.claude/settings.json"
ZSHRC="$HOME/.zshrc"
SOURCE_LINE='[[ -f ~/.config/ghostty/agent-tab-colors.zsh ]] && source ~/.config/ghostty/agent-tab-colors.zsh'

# --- Prerequisites ---

if ! command -v jq &>/dev/null; then
    echo "Error: jq is required. Install with: brew install jq" >&2
    exit 1
fi

if [[ ! -f "$SETTINGS" ]]; then
    echo "Error: ~/.claude/settings.json not found. Is Claude Code installed?" >&2
    exit 1
fi

if [[ ! -f "$HOOK_SRC" ]]; then
    echo "Error: hooks/ghostty-tab-color.sh not found. Run from the project directory." >&2
    exit 1
fi

# --- Symlink hook ---

mkdir -p "$(dirname "$HOOK_DST")"
ln -sf "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_SRC"
echo "Linked hook: $HOOK_DST -> $HOOK_SRC"

# --- Patch settings.json ---

# Define the hook entries to add
HOOK_ENTRIES=$(cat <<'HOOKJSON'
{
  "SessionStart": [{
    "matcher": "startup",
    "hooks": [{
      "type": "command",
      "command": "~/.claude/hooks/ghostty-tab-color.sh working",
      "timeout": 2000
    }]
  }],
  "PreToolUse": [{
    "matcher": "AskUserQuestion",
    "hooks": [{
      "type": "command",
      "command": "~/.claude/hooks/ghostty-tab-color.sh waiting",
      "timeout": 2000
    }]
  }],
  "PostToolUse": [{
    "matcher": "",
    "hooks": [{
      "type": "command",
      "command": "~/.claude/hooks/ghostty-tab-color.sh working",
      "timeout": 2000
    }]
  }],
  "Notification": [{
    "matcher": "",
    "hooks": [{
      "type": "command",
      "command": "~/.claude/hooks/ghostty-tab-color.sh notification",
      "timeout": 2000
    }]
  }],
  "Stop": [{
    "matcher": "",
    "hooks": [{
      "type": "command",
      "command": "~/.claude/hooks/ghostty-tab-color.sh completed",
      "timeout": 2000
    }]
  }]
}
HOOKJSON
)

# Idempotent merge: remove any existing ghostty-tab-color entries first, then append ours.
# This makes repeated installs safe (no duplicate hooks).
PATCHED=$(jq --argjson new "$HOOK_ENTRIES" '
    .hooks //= {} |
    # Strip existing ghostty-tab-color entries from all event arrays
    .hooks |= with_entries(
        .value = [(.value // [])[] | select(
            (.hooks // []) | all(.command // "" | contains("ghostty-tab-color.sh") | not)
        )]
    ) |
    # Append our entries
    reduce ($new | to_entries[]) as $entry (.;
        .hooks[$entry.key] = (.hooks[$entry.key] // []) + $entry.value
    )
' "$SETTINGS")

# Validate before writing — never overwrite with empty/invalid JSON
if [[ -z "$PATCHED" ]] || ! printf '%s\n' "$PATCHED" | jq empty 2>/dev/null; then
    echo "Error: jq produced invalid output — settings.json not modified" >&2
    exit 1
fi

printf '%s\n' "$PATCHED" > "${SETTINGS}.tmp"
mv "${SETTINGS}.tmp" "$SETTINGS"
echo "Patched settings.json with hook entries"

# --- Symlink shell integration ---

mkdir -p "$(dirname "$SHELL_DST")"
ln -sf "$SHELL_SRC" "$SHELL_DST"
echo "Linked shell integration: $SHELL_DST -> $SHELL_SRC"

# --- Patch .zshrc ---

if [[ -f "$ZSHRC" ]] && grep -qF "agent-tab-colors.zsh" "$ZSHRC"; then
    echo "Source line already in .zshrc — skipping"
else
    printf '\n# Ghostty agent tab color indicators\n%s\n' "$SOURCE_LINE" >> "$ZSHRC"
    echo "Added source line to .zshrc"
fi

# --- Done ---

echo ""
echo "Installation complete."
echo "Open a new terminal tab to activate shell integration."
echo "Claude Code hooks are active immediately for new sessions."
