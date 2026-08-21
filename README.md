# dot_files

Al dente configs. Firm, never mushy.

## Setup

After cloning, enable the pre-commit hook:

```sh
git config core.hooksPath hooks
```

This runs a scan on every commit that checks for:
- Leaked secrets (API keys, tokens, private keys)
- Suspicious Unicode (bidi overrides, zero-width chars) used in trojan source attacks

## Linux config trees

Portable Pi files use the home-relative path `~/.pi/agent/` and are stored here:
`.pi/agent/AGENTS.md`, `.pi/agent/settings.json`,
`.pi/agent/extensions/subagent/config.json`, and
`.pi/agent/scripts/lint-subagent-sessions.mjs`.

Portable Hyprland files use `~/.config/hypr/` and are stored here:
`.config/hypr/hyprland.lua`, `.config/hypr/hypridle.conf`, and
`.config/hypr/hyprlock.conf`.

Install only these tracked files so local runtime state and unrelated files stay
untouched:

```sh
install -Dm644 .pi/agent/AGENTS.md "$HOME/.pi/agent/AGENTS.md"
install -Dm644 .pi/agent/settings.json "$HOME/.pi/agent/settings.json"
install -Dm644 .pi/agent/extensions/subagent/config.json \
  "$HOME/.pi/agent/extensions/subagent/config.json"
install -Dm755 .pi/agent/scripts/lint-subagent-sessions.mjs \
  "$HOME/.pi/agent/scripts/lint-subagent-sessions.mjs"
install -Dm644 .config/hypr/hyprland.lua "$HOME/.config/hypr/hyprland.lua"
install -Dm644 .config/hypr/hypridle.conf "$HOME/.config/hypr/hypridle.conf"
install -Dm644 .config/hypr/hyprlock.conf "$HOME/.config/hypr/hyprlock.conf"
```
