# Set zsh config location
export ZDOTDIR="$HOME/.config/zsh"

# Adds `~/.local/bin` and folders to $PATH
export PATH="$PATH:${$(find ~/.local/bin -type d -printf %p:)%%:}"
export PATH="$PATH:$HOME/Applications"
export PATH="${PATH}:/opt/rocm/bin/" 
export PATH=~/.npm-global/bin:$PATH

# Default programs
export EDITOR="nvim"
export BROWSER="firefox"
export TERMINAL="kitty"

# StartX at Login
# Keep at bottom
# if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
# 	exec startx
# fi
exec Hyprland
