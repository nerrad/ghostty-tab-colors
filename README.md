# ghostty-tab-colors

Visual tab state indicators for Claude Code sessions in [Ghostty](https://ghostty.org) terminal.

When running multiple Claude Code agents across Ghostty tabs, this tool shows each agent's state at a glance:

| State | Emoji | Background | Meaning |
|-------|-------|------------|---------|
| Working | 🟠 | Warm orange tint | Agent is actively using tools |
| Waiting | 🟡 | Warm yellow tint | Agent needs your input |
| Completed | 🟢 | Subtle green tint | Agent finished its task |
| Error | 🔴 | Subtle red tint | Agent stopped due to an error |

## How it works

Uses [Claude Code hooks](https://code.claude.com/docs/en/hooks) to detect agent state transitions and writes escape sequences to the terminal:

- **OSC 2** — Sets the tab title with an emoji prefix (e.g., `🟠 Claude Code`)
- **OSC 21** — Sets a subtle background tint via Ghostty's Kitty color protocol support

State is debounced per-session via `/tmp` files so frequent `PostToolUse` events don't cause unnecessary updates.

## Requirements

- [Ghostty](https://ghostty.org) 1.3.0+ on macOS
- [Claude Code](https://code.claude.com) with hooks support
- `jq` (for install/uninstall scripts)
- `zsh` shell

## Install

```bash
git clone https://github.com/nerrad/ghostty-tab-colors.git ~/tools/ghostty-tab-colors
cd ~/tools/ghostty-tab-colors
./install.sh
```

The installer:
1. Symlinks the hook script to `~/.claude/hooks/`
2. Merges hook entries into `~/.claude/settings.json` (preserves existing hooks)
3. Symlinks shell integration to `~/.config/ghostty/`
4. Adds a source line to `~/.zshrc`

Open a new tab to activate shell integration. Hook changes are immediate.

## Uninstall

```bash
cd ~/tools/ghostty-tab-colors
./uninstall.sh
```

Removes all symlinks, hook entries, shell integration, and state files cleanly.

## Limitations

- **Ghostty only** — Uses Ghostty-specific escape sequences (OSC 21). Does not work under tmux, screen, or other terminals.
- **No native tab color dot** — Ghostty 1.3.x has no programmatic API for the tab color indicator. We use emoji in the tab title as a workaround. When Ghostty adds `colorize_tab` support ([PR #11498](https://github.com/ghostty-org/ghostty/pull/11498)), this tool can be upgraded to set actual tab colors.
- **Background tint during TUI** — Claude Code's TUI may obscure the OSC 21 background tint while it's running. The tint is most visible after the agent completes and you return to the shell prompt.
- **Tab title conflicts** — Oh My Zsh's auto-title and Ghostty's shell integration both set the tab title. The hook's emoji prefix may be briefly overwritten during rapid tool use, but it re-asserts on the next state transition.
- **Symlinks break if repo is moved** — The installer symlinks back to this repo. If you move or delete the repo, hooks will fail silently until you re-install or clean up manually.

## How updates work

Since the install uses symlinks back to this repo, pulling updates is simple:

```bash
cd ~/tools/ghostty-tab-colors
git pull
```

No re-install needed unless new hook events are added.

Re-running `./install.sh` is safe — it replaces existing hook entries rather than duplicating them.

## License

MIT
