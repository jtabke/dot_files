# Portable interactive shell settings.
[[ -o interactive ]] || return 0

HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.cache/zsh/.zhistory"
mkdir -p "${HISTFILE:h}"
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_SAVE_NO_DUPS HIST_REDUCE_BLANKS HIST_VERIFY
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

bindkey -v
bindkey -M viins '^?' backward-delete-char
if [[ -n ${terminfo[kdch1]-} ]]; then
  bindkey -M viins "${terminfo[kdch1]}" delete-char
  bindkey -M vicmd "${terminfo[kdch1]}" delete-char
else
  bindkey -M viins '^[[3~' delete-char
  bindkey -M vicmd '^[[3~' delete-char
fi
bindkey '^R' history-incremental-search-backward
bindkey '^[[Z' reverse-menu-complete

function zle-keymap-select {
  case $KEYMAP in
    vicmd) echo -ne '\e[2 q' ;;
    viins|main) echo -ne '\e[6 q' ;;
  esac
}
zle -N zle-keymap-select
function zle-line-init { echo -ne '\e[6 q' }
zle -N zle-line-init

function vi-yank-clipboard {
  zle vi-yank
  if [[ "$OSTYPE" == darwin* ]] && command -v pbcopy >/dev/null 2>&1; then
    print -rn -- "$CUTBUFFER" | pbcopy
  elif command -v wl-copy >/dev/null 2>&1; then
    print -rn -- "$CUTBUFFER" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    print -rn -- "$CUTBUFFER" | xclip -selection clipboard
  else
    zle -M "No clipboard tool found"
  fi
}
zle -N vi-yank-clipboard
bindkey -M vicmd 'y' vi-yank-clipboard

autoload -Uz select-bracketed select-quoted
zle -N select-bracketed
zle -N select-quoted
for km in viopp visual; do
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do bindkey -M $km -- $c select-bracketed; done
  for c in {a,i}${(s..)^:-\'\"\`}; do bindkey -M $km -- $c select-quoted; done
done

autoload -U colors && colors
