#!/usr/bin/env bash
# Validate source state and real chezmoi behavior in isolated temporary paths.
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo"
failures=0
check() {
  if "$@"; then
    printf 'PASS: %s\n' "$*"
  else
    printf 'FAIL: %s\n' "$*" >&2
    failures=$((failures + 1))
  fi
}
fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}
check_not() {
  if ! "$@"; then
    printf 'PASS: not %s\n' "$*"
  else
    printf 'FAIL: not %s\n' "$*" >&2
    failures=$((failures + 1))
  fi
}

check test "$(cat .chezmoiroot)" = home
check test -f home/.chezmoi.toml.tmpl
check test ! -e home/.chezmoidata.toml
check test -f home/.chezmoiignore
check test -f home/dot_zshenv
check test -f home/dot_config/zsh/dot_zshrc
check test -f home/dot_config/nvim/init.lua
check test -f home/dot_vim/dot_vimrc
check test -f home/dot_pi/agent/settings.json
check test -L .pi/agent
check test "$(readlink .pi/agent)" = ../home/dot_pi/agent
check test -f .pi/agent/settings.json
check grep -qF 'promptChoiceOnce . "role" "Machine role"' home/.chezmoi.toml.tmpl
check grep -qF 'promptChoiceOnce . "desktop" "Desktop environment"' home/.chezmoi.toml.tmpl
check grep -qF 'promptBoolOnce . "installPackages" "Install missing packages during apply?"' home/.chezmoi.toml.tmpl
check grep -qF 'promptBoolOnce . "autoTmux" "Automatically attach local interactive shells to tmux?"' home/.chezmoi.toml.tmpl
check_not grep -RIn --exclude-dir=.git -E '\.chezmoi\.kernel([^.]|$)' .
check grep -qF '.chezmoi.kernel.osrelease' home/.chezmoi.toml.tmpl
check grep -qF '.chezmoi.kernel.osrelease' home/.chezmoiignore
check grep -qF '.chezmoi.kernel.osrelease' home/dot_config/zsh/dot_zprofile.tmpl
check grep -qF '.config/hypr' home/.chezmoiignore
check test ! -d home/dot_config/awesome
check grep -qF '.aerospace.toml' home/.chezmoiignore
check grep -qF '.config/sketchybar' home/.chezmoiignore
check_not grep -qF 'dot_config/' home/.chezmoiignore
check_not grep -qF 'dot_aerospace.toml' home/.chezmoiignore
check_not grep -qF 'README.md' home/.chezmoiignore
check_not grep -qF 'docs/' home/.chezmoiignore
check_not grep -qF 'tests/' home/.chezmoiignore
check_not grep -qF 'AGENTS.md' home/.chezmoiignore
check grep -qF 'autoTmux' home/dot_config/zsh/90-tmux.zsh.tmpl
check grep -qF 'SSH_CONNECTION' home/dot_config/zsh/90-tmux.zsh.tmpl
check grep -qF 'path = ~/.config/git/user.inc' home/dot_gitconfig.tmpl
check grep -qF 'command -v brew' home/run_onchange_install-packages.sh.tmpl
check grep -qF '/opt/homebrew/bin/brew' home/run_onchange_install-packages.sh.tmpl
check grep -qF '/usr/local/bin/brew' home/run_onchange_install-packages.sh.tmpl
check grep -qF 'EUID == 0' home/run_onchange_install-packages.sh.tmpl
check grep -qF 'sudo failed while running Pacman' home/run_onchange_install-packages.sh.tmpl
check test -f home/dot_config/kitty/symlink_theme.conf
check test "$(cat home/dot_config/kitty/symlink_theme.conf)" = ./kitty-themes/Galaxy.conf
check test ! -e home/dot_config/kitty/theme.conf

for file in home/dot_pi/agent/scripts/executable_lint-subagent-sessions.mjs \
  home/dot_config/sketchybar/executable_sketchybarrc \
  home/dot_config/sketchybar/plugins/executable_*.sh; do
  check test -x "$file"
done
check test -x hooks/pre-commit

check_no_likely_secrets() {
  ! grep -RInE '\$(USERNAME|EMAIL)|AKIA[0-9A-Z]{16}|BEGIN .*PRIVATE KEY' \
    --exclude-dir=.git --exclude-dir=hooks --exclude='validate-repository.sh' .
}
check check_no_likely_secrets

# Parse JSON and TOML with installed standard tools.
while IFS= read -r -d '' file; do
  check jq empty "$file"
done < <(find home . -path './.git' -prune -o -name '*.json' -print0)
while IFS= read -r -d '' file; do
  check python3 -c 'import sys,tomllib; tomllib.load(open(sys.argv[1], "rb"))' "$file"
done < <(find home . -path './.git' -prune -o -name '*.toml' -print0)

check bash -n hooks/pre-commit
while IFS= read -r -d '' file; do
  check bash -n "$file"
done < <(find home . -path './.git' -prune -o -type f \( -name '*.sh' -o -name '*.bash' \) -print0)
while IFS= read -r -d '' file; do
  check zsh -n "$file"
done < <(find home . -path './.git' -prune -o -type f \( -name '*.zsh' -o -name 'dot_zshenv' \) -print0)

run_profile() {
  local name=$1 role=$2 desktop=$3
  local tmp dest cache config state dry second
  tmp=$(mktemp -d)
  dest=$tmp/destination
  cache=$tmp/cache
  config=$tmp/config.toml
  state=$tmp/state.db
  mkdir -p "$dest" "$cache"

  # A clean init owns these prompts. Answers are piped to stdin with no TTY.
  printf '%s\n%s\nfalse\nfalse\n' "$role" "$desktop" \
    | chezmoi --source "$repo" --destination "$dest" --cache "$cache" \
      --config "$config" --persistent-state "$state" --no-tty init \
      >"$tmp/init.out" 2>"$tmp/init.err" || {
        cat "$tmp/init.out" "$tmp/init.err" >&2
        fail "$name clean init"
        rm -rf "$tmp"
        return
      }
  check grep -qF "role = \"$role\"" "$config"
  check grep -qF "desktop = \"$desktop\"" "$config"
  check grep -qF 'installPackages = false' "$config"
  check grep -qF 'autoTmux = false' "$config"
  if chezmoi --source "$repo" --destination "$dest" --cache "$cache" \
    --config "$config" --persistent-state "$state" --no-tty init </dev/null; then
    printf 'PASS: %s prompt answers persist\n' "$name"
  else
    fail "$name prompt answers persist"
  fi

  dry=$(chezmoi --source "$repo" --destination "$dest" --cache "$cache" \
    --config "$config" --persistent-state "$state" --no-tty --dry-run --verbose apply)
  if [[ "$role" == workstation && ("$desktop" == auto || "$desktop" == hyprland) ]]; then
    [[ "$dry" == *'.config/hypr/hyprland.lua'* ]] || fail "$name dry-run selects Hyprland"
  else
    [[ "$dry" != *'.config/hypr/hyprland.lua'* ]] || fail "$name dry-run excludes Hyprland"
  fi
  [[ "$dry" != *'.aerospace.toml'* ]] || fail "$name dry-run excludes AeroSpace"
  [[ "$dry" != *'.config/sketchybar/sketchybarrc'* ]] || fail "$name dry-run excludes SketchyBar"

  chezmoi --source "$repo" --destination "$dest" --cache "$cache" \
    --config "$config" --persistent-state "$state" --no-tty --force apply \
    >"$tmp/apply.out" 2>"$tmp/apply.err" || {
      cat "$tmp/apply.out" "$tmp/apply.err" >&2
      fail "$name apply"
      rm -rf "$tmp"
      return
    }
  second=$(chezmoi --source "$repo" --destination "$dest" --cache "$cache" \
    --config "$config" --persistent-state "$state" --no-tty --dry-run apply)
  [[ -z "$second" ]] || fail "$name second apply/diff is clean"

  check test -f "$dest/.zshenv"
  check test -f "$dest/.config/nvim/init.lua"
  check test -f "$dest/.pi/agent/settings.json"
  check test -x "$dest/.pi/agent/scripts/lint-subagent-sessions.mjs"
  check test -L "$dest/.config/kitty/theme.conf"
  check test "$(readlink "$dest/.config/kitty/theme.conf")" = ./kitty-themes/Galaxy.conf
  if [[ "$role" == workstation && "$desktop" == auto && "$OSTYPE" == darwin* ]]; then
    check test -x "$dest/.config/sketchybar/sketchybarrc"
  else
    check_not test -e "$dest/.config/sketchybar"
  fi
  check node --check "$dest/.pi/agent/scripts/lint-subagent-sessions.mjs"

  while IFS= read -r -d '' file; do
    check jq empty "$file"
  done < <(find "$dest" -name '*.json' -print0)
  while IFS= read -r -d '' file; do
    check python3 -c 'import sys,tomllib; tomllib.load(open(sys.argv[1], "rb"))' "$file"
  done < <(find "$dest" -name '*.toml' -print0)
  if [[ "$role" == workstation && ("$desktop" == auto || "$desktop" == hyprland) ]]; then
    check grep -qF 'exec Hyprland' "$dest/.config/zsh/.zprofile"
  else
    check_not grep -qF 'exec Hyprland' "$dest/.config/zsh/.zprofile"
  fi
  check zsh -n "$dest/.zshenv"
  while IFS= read -r -d '' file; do
    check zsh -n "$file"
  done < <(find "$dest/.config/zsh" -type f -print0)
  while IFS= read -r -d '' file; do
    check bash -n "$file"
  done < <(find "$dest/.config/sketchybar" -type f -perm /111 -print0 2>/dev/null || true)

  rm -rf "$tmp"
  printf 'PASS: %s isolated chezmoi profile\n' "$name"
}

run_profile linux-workstation workstation auto
run_profile linux-shell shell none

check git diff --check
if ((failures)); then
  printf '%d validation checks failed.\n' "$failures" >&2
  exit 1
fi
printf 'All repository and isolated chezmoi checks passed.\n'
