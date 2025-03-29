# History Settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.cache/zsh/.zhistory
setopt SHARE_HISTORY

# Keybindings
bindkey '^R' history-incremental-search-backward
bindkey "^[[3~" delete-char  # Fix delete key
bindkey '^[[Z' reverse-menu-complete  # Shift+Tab for reverse menu completion
# vi mode
#bindkey -v

# Yank to the system clipboard
function vi-yank-clipboard {
    zle vi-yank
    if type -p xclip &> /dev/null; then
        echo -n "$CUTBUFFER" | xclip -selection clipboard
    elif type -p wl-copy &> /dev/null; then
        echo -n "$CUTBUFFER" | wl-copy
    else
        echo "Clipboard tool (xclip or wl-copy) not found"
    fi
}
zle -N vi-yank-clipboard
bindkey -M vicmd 'y' vi-yank-clipboard  # Assumes vi mode is enabled elsewhere

# Enable colors
autoload -U colors && colors
# Prompt style
PS1="%F{202}[%F{green}%n%f@%F{blue}%m%F{202}]%f%1~%# " 

# Autocomplete
autoload -Uz compinit
zstyle ':completion:*' menu select # tab menu autocompletetion and case insensitive
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' # tab menu autocompletetion and case insensitive
zmodload zsh/complist # make available keymaps like menuselect
compinit
_comp_options+=(globdots) # include hidden files

# Aliases
alias vim="nvim"
alias vi="nvim"
# Cross-platform ls aliases
if [[ $(uname) == "Darwin" ]]; then
    # macOS
    alias ls="ls -a -G"          # -G for colors, -a for all files
    alias ll="ls -lah -G"        # -l for long format, -h for human-readable sizes
else
    # Linux/WSL
    alias ls="ls -a --color=auto"  # --color=auto for colors, -a for all files
    alias ll="ls -lah --color=auto" # -l for long format, -h for human-readable
fi

# Show directory contents after cd
function chpwd() {
    emulate -L zsh
    ls -a
}

# External Tools and Plugins
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden'  # Ensure ripgrep is installed
source <(fzf --zsh)  # fzf key bindings and completion
eval "$(starship init zsh)"  # Starship prompt (overrides PS1)
source "$HOME/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOME/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
