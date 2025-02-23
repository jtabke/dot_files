# Set History File location
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.cache/zsh/.zhistory
setopt SHARE_HISTORY

# vi mode
#bindkey -v
bindkey '^R' history-incremental-search-backward
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
bindkey -M vicmd 'y' vi-yank-clipboard

bindkey "^[[3~" delete-char #make delete key work

# Enable colors
autoload -U colors && colors
# Prompt style
PS1="%F{202}[%F{green}%n%f@%F{blue}%m%F{202}]%f%1~%# " 

# Autocomplete
autoload -Uz compinit
zstyle ':completion:*' menu select # tab menu autocompletetion and case insensitive
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' # tab menu autocompletetion and case insensitive
zmodload zsh/complist # make available keymaps like menuselect
bindkey '^[[Z' reverse-menu-complete # shift tab to go back through menu
#bindkey -M menuselect '^[[Z' reverse-menu-complete # shift tab to go back through menu
compinit
_comp_options+=(globdots) # include hidden files

## Alias

alias vim="nvim"
alias vi="nvim"

alias ll="ls -lah"
alias ls="ls -a --color=auto"

# show folder after change directory
function chpwd() {
    emulate -L zsh
    ls -a
}

## Plugins

# zsh-vi-mode
#source "$HOME/.config/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh"

#fzf key bindings
# source "/usr/share/fzf/key-bindings.zsh"
# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
# For a more efficient version of find you should prune directories, then (optionally) filter out specific files
# export FZF_DEFAULT_COMMAND='find . \! \( -type d -path ./.git -prune \) \! -type d \! -name '\''*.tags'\'' -printf '\''%P\n'\'
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden'

# starship prompt
eval "$(starship init zsh)"

# zsh-autosuggestions
source "$HOME/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Load zsh-syntax-highlighitng; should be sourced last
source "$HOME/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
