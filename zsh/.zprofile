# Homebrew (macOS only)
if [[ "$OSTYPE" == darwin* ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Keep provider prompt caches available for resumed Pi subagents
export PI_CACHE_RETENTION=long

# Start Hyprland at login (Linux only)
if [[ "$OSTYPE" == linux* ]] && [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
  exec Hyprland
fi
