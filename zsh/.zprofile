# Homebrew (macOS only)
if [[ "$OSTYPE" == darwin* ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Start Hyprland at login (Linux only)
if [[ "$OSTYPE" == linux* ]] && [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
  exec Hyprland
fi
