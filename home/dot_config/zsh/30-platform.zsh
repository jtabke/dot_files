# Platform setup and optional integrations.
[[ -o interactive ]] || return 0

autoload -Uz compinit
zmodload zsh/complist
typeset -U fpath PATH path
if [[ -n "${HOMEBREW_PREFIX-}" && -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
if [[ -n ~/.cache/zsh/.zcompdump(#qN.mh+24) ]]; then
  compinit -d ~/.cache/zsh/.zcompdump
else
  compinit -C -d ~/.cache/zsh/.zcompdump
fi
_comp_options+=(globdots)

alias vim='nvim'
alias vi='nvim'
if [[ "$OSTYPE" == darwin* ]]; then
  alias ls='ls -a -G'
  alias ll='ls -lah -G'
else
  alias ls='ls -a --color=auto'
  alias ll='ls -lah --color=auto'
fi
function chpwd { emulate -L zsh; ls -a }

if command -v fzf >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --glob "!.git/*"'
  source <(fzf --zsh)
fi
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Restore GUI/session variables when the tmux server outlives the desktop
# session. update-environment refreshes these values when clients attach.
if [[ -n "${TMUX-}" ]]; then
  for variable in WAYLAND_DISPLAY DISPLAY XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS XDG_SESSION_TYPE; do
    assignment=$(tmux show-environment -g "$variable" 2>/dev/null)
    [[ "$assignment" == "$variable="* ]] && export "$assignment"
  done
  unset variable assignment
fi

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

if [[ "$OSTYPE" == linux* ]] && command -v xdg-open >/dev/null 2>&1; then
  alias open='xdg-open'
fi

[[ -r "$HOME/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$HOME/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -r "$HOME/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$HOME/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
