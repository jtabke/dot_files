# ZDOTDIR must be set here — .zshenv is the only file sourced for all zsh invocations
export ZDOTDIR="$HOME/.config/zsh"

# Default programs
export EDITOR="nvim"
export BROWSER="firefox"
export TERMINAL="ghostty"

# Prevent PATH duplicates in nested shells
typeset -U PATH path

# PATH
export PATH="$HOME/.local/bin:$HOME/.local/share/nvim/mason/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="${PATH}:/opt/rocm/bin"

# Ensure history directory exists
mkdir -p "$HOME/.cache/zsh"

# Disable Next.js telemetry
export NEXT_TELEMETRY_DISABLED=1

# Source env setup (cargo/rustup, etc.)
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
