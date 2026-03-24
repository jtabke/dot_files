# History Settings
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.cache/zsh/.zhistory
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS      # skip consecutive duplicates only
setopt HIST_SAVE_NO_DUPS     # don't write duplicates to the history file
setopt HIST_REDUCE_BLANKS    # trim unnecessary blanks before saving
setopt HIST_VERIFY           # show substituted history command before executing

# Directory navigation
setopt AUTO_CD               # type a directory name to cd into it
setopt AUTO_PUSHD            # cd pushes old directory onto the stack
setopt PUSHD_IGNORE_DUPS     # don't push duplicates onto the stack
setopt PUSHD_SILENT          # don't print the directory stack after pushd/popd

# vi mode
bindkey -v
# Keybindings
bindkey -M viins '^?' backward-delete-char   # usual Mac backspace
# Use terminfo when possible (portable across terminals)
if [[ -n ${terminfo[kdch1]} ]]; then
  bindkey -M viins  "${terminfo[kdch1]}" delete-char   # Delete key in insert mode
  bindkey -M vicmd  "${terminfo[kdch1]}" delete-char   # (optional) also in command mode
else
  # Fallback to the raw sequence ESC [ 3 ~
  bindkey -M viins  '^[[3~' delete-char
  bindkey -M vicmd  '^[[3~' delete-char
fi
bindkey '^R' history-incremental-search-backward
bindkey '^[[Z' reverse-menu-complete  # Shift+Tab for reverse menu completion

# Function to switch cursor based on keymap
function zle-keymap-select {
  case $KEYMAP in
    vicmd)   echo -ne '\e[2 q' ;;  # block cursor
    viins|main) echo -ne '\e[6 q' ;;  # line cursor
  esac
}
zle -N zle-keymap-select
# Also fix cursor on new prompt
function zle-line-init {
  echo -ne '\e[6 q'  # start in insert mode with line cursor
}
zle -N zle-line-init
# Yank to the system clipboard
function vi-yank-clipboard {
    zle vi-yank

    if [[ "$OSTYPE" == darwin* ]]; then
        echo -n "$CUTBUFFER" | pbcopy
    elif type -p wl-copy &>/dev/null; then
        echo -n "$CUTBUFFER" | wl-copy
    elif type -p xclip &>/dev/null; then
        echo -n "$CUTBUFFER" | xclip -selection clipboard
    else
        zle -M "No clipboard tool found"
    fi
}
zle -N vi-yank-clipboard
bindkey -M vicmd 'y' vi-yank-clipboard

# vi text objects for brackets and quotes (ci", da(, etc.)
autoload -Uz select-bracketed select-quoted
zle -N select-bracketed
zle -N select-quoted
for km in viopp visual; do
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $km -- $c select-bracketed
  done
  for c in {a,i}${(s..)^:-\'\"\`}; do
    bindkey -M $km -- $c select-quoted
  done
done

# Enable colors
autoload -U colors && colors

# --- Completions ---
autoload -Uz compinit
zmodload zsh/complist

# keep fpath unique
typeset -U fpath

# Homebrew completions (macOS only, uses HOMEBREW_PREFIX from brew shellenv in .zprofile)
if [[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi

# Completion styles
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Only regenerate comp dump once per day
if [[ -n ~/.cache/zsh/.zcompdump(#qN.mh+24) ]]; then
  compinit -d ~/.cache/zsh/.zcompdump
else
  compinit -C -d ~/.cache/zsh/.zcompdump
fi
_comp_options+=(globdots)

# Aliases
alias vim="nvim"
alias vi="nvim"
# Cross-platform ls aliases
if [[ $(uname) == "Darwin" ]]; then
    alias ls="ls -a -G"
    alias ll="ls -lah -G"
else
    alias ls="ls -a --color=auto"
    alias ll="ls -lah --color=auto"
fi

# Show directory contents after cd
function chpwd() {
    emulate -L zsh
    ls -a
}

# External Tools and Plugins
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --glob "!.git/*"'
source <(fzf --zsh)

eval "$(starship init zsh)"

source "$HOME/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOME/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Open tmux (must be last — takes over the terminal for the outer shell)
if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
  tmux attach -t default || tmux new -s default
fi
