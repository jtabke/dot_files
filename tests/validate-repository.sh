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
check test -f home/private_dot_npmrc
check test ! -e home/dot_npmrc
check grep -qF 'min-release-age=3' home/private_dot_npmrc
check grep -qF 'ignore-scripts=false' home/private_dot_npmrc
check test -f home/dot_config/nvim/lua/plugins/remove_avante.lua
check_not jq -e 'has("avante.nvim") or has("llm.nvim")' home/dot_config/nvim/lazy-lock.json
check test -f home/dot_config/nvim/lua/plugins/remove_codecompanion.lua
check test ! -s home/dot_config/nvim/lua/plugins/remove_codecompanion.lua
check_not jq -e 'has("codecompanion.nvim")' home/dot_config/nvim/lazy-lock.json
check test -f home/dot_config/nvim/lua/plugins/remove_llm.lua
check test -f home/dot_config/nvim/lua/plugins/remove_nvim-ts-autotag.lua
check test -f home/dot_config/nvim/after/ftplugin/remove_typescript.vim
check test -f home/dot_config/nvim/after/ftplugin/remove_python.vim.bak
check test ! -d home/dot_vim
check test -f home/.chezmoitemplates/pi-settings.json
check jq -e '[.packages[] | select(type == "object") | select(.source == "npm:pi-subagents")] | length == 1 and .[0].skills == ["!skills/pi-subagents/**"]' home/.chezmoitemplates/pi-settings.json
check grep -qF '../../npm/node_modules/pi-subagents/docs/tool-reference.md' home/dot_pi/private_agent/skills/pi-subagents/SKILL.md
check grep -qF '../../npm/node_modules/pi-subagents/skills/pi-subagents/references/orchestration.md' home/dot_pi/private_agent/skills/pi-subagents/SKILL.md
check_not grep -qF '../../git/github.com/nicobailon/pi-subagents/' home/dot_pi/private_agent/skills/pi-subagents/SKILL.md
check test -f home/dot_pi/private_agent/modify_settings.json
check_not test -x home/dot_pi/private_agent/modify_settings.json
check test -L .pi/agent
check test "$(readlink .pi/agent)" = ../home/dot_pi/private_agent
check test -f .pi/agent/AGENTS.md
check grep -qF 'promptChoiceOnce . "role" "Machine role"' home/.chezmoi.toml.tmpl
check grep -qF 'promptChoiceOnce . "desktop" "Desktop environment"' home/.chezmoi.toml.tmpl
check grep -qF 'promptBoolOnce . "installPackages" "Install missing packages during apply?"' home/.chezmoi.toml.tmpl
check grep -qF 'promptBoolOnce . "autoTmux" "Automatically open or reconnect to tmux (including SSH)?"' home/.chezmoi.toml.tmpl
check_not grep -RIn -F '.chezmoi.kernel.osrelease' home
check grep -qF 'default "" (index .chezmoi.kernel "osrelease")' home/.chezmoi.toml.tmpl
check grep -qF 'default "" (index .chezmoi.kernel "osrelease")' home/.chezmoiignore
check grep -qF 'default "" (index .chezmoi.kernel "osrelease")' home/dot_config/zsh/dot_zprofile.tmpl
check grep -qF 'or (contains "microsoft" $kernel) (contains "wsl" $kernel)' home/.chezmoi.toml.tmpl
check grep -qF 'or (contains "microsoft" $kernel) (contains "wsl" $kernel)' home/.chezmoiignore
check grep -qF 'or (contains "microsoft" $kernel) (contains "wsl" $kernel)' home/dot_config/zsh/dot_zprofile.tmpl
check grep -qF -- '-z "${TMUX-}"' home/dot_config/zsh/dot_zprofile.tmpl
check grep -qF -- '-z "${SSH_CONNECTION-}"' home/dot_config/zsh/dot_zprofile.tmpl
check grep -qF -- '-z "${SSH_TTY-}"' home/dot_config/zsh/dot_zprofile.tmpl
check grep -qF '"$(tty 2>/dev/null)" == /dev/tty1' home/dot_config/zsh/dot_zprofile.tmpl
check grep -qF '[[ -o zle && -z "${ZSH_EXECUTION_STRING-}" ]]' home/dot_config/zsh/30-platform.zsh
check grep -qF '.config/hypr' home/.chezmoiignore
check grep -qF '.config/fuzzel' home/.chezmoiignore
check grep -qF 'hyprland.local.lua' home/dot_config/hypr/hyprland.lua
check test ! -e home/dot_config/hypr/hyprland.local.lua
check test -f docs/hyprland-local.example.lua
check test ! -d home/dot_config/awesome
check test -f home/dot_config/aerospace/aerospace.toml
check test -f home/remove_dot_aerospace.toml
check test ! -s home/remove_dot_aerospace.toml
check grep -qF '.config/aerospace' home/.chezmoiignore
check grep -qF '.config/sketchybar' home/.chezmoiignore
check_not grep -qF 'dot_config/' home/.chezmoiignore
check_not test -e home/dot_aerospace.toml
check_not grep -qF 'README.md' home/.chezmoiignore
check_not grep -qF 'docs/' home/.chezmoiignore
check_not grep -qF 'tests/' home/.chezmoiignore
check_not grep -qF 'AGENTS.md' home/.chezmoiignore
check grep -qF 'autoTmux' home/dot_config/zsh/90-tmux.zsh.tmpl
check_not grep -qF 'SSH_CONNECTION' home/dot_config/zsh/90-tmux.zsh.tmpl
check grep -qF 'tmux new-session -A -s default' home/dot_config/zsh/90-tmux.zsh.tmpl
check_not grep -qF 'exec tmux' home/dot_config/zsh/90-tmux.zsh.tmpl
check grep -qF 'path = ~/.config/git/user.inc' home/dot_gitconfig.tmpl
check grep -qF 'command -v brew' home/.chezmoitemplates/setup.sh.tmpl
check grep -qF '/opt/homebrew/bin/brew' home/.chezmoitemplates/setup.sh.tmpl
check grep -qF '/usr/local/bin/brew' home/.chezmoitemplates/setup.sh.tmpl
check grep -qF 'EUID != 0' home/.chezmoitemplates/setup.sh.tmpl
check grep -qF 'minimumReleaseAge = 604800' home/dot_bunfig.toml
check_not grep -qF 'minimumReleageAge' home/dot_bunfig.toml
check grep -qF 'Package installation requires root or sudo.' home/.chezmoitemplates/setup.sh.tmpl
check test -x setup
check bash -n setup
check python3 tests/test-setup.py
check test -f home/dot_config/kitty/symlink_theme.conf
check test "$(cat home/dot_config/kitty/symlink_theme.conf)" = ./kitty-themes/Galaxy.conf
check test ! -e home/dot_config/kitty/theme.conf

for file in home/dot_pi/private_agent/scripts/executable_lint-subagent-sessions.mjs \
  home/dot_config/sketchybar/executable_sketchybarrc \
  home/dot_config/sketchybar/plugins/executable_*.sh; do
  check test -x "$file"
done
check test -x hooks/pre-commit

pi_agent_mode() {
  if [[ "$(uname -s)" == Darwin ]]; then
    stat -f '%Lp' "$1"
  else
    stat -c '%a' "$1"
  fi
}
check test "$(pi_agent_mode home/dot_pi/private_agent/modify_settings.json)" = 644

check_no_likely_secrets() {
  ! grep -RInE '\$(USERNAME|EMAIL)|AKIA[0-9A-Z]{16}|BEGIN .*PRIVATE KEY' \
    --exclude-dir=.git --exclude-dir=hooks --exclude='validate-repository.sh' .
}
check check_no_likely_secrets

check_non_zle_zsh_startup() {
  local tmp output
  tmp=$(mktemp -d)
  if ! HOME="$tmp" ZDOTDIR="$tmp" DOTFILES_REPO="$repo" zsh -f -ic \
    'source "$DOTFILES_REPO/home/dot_config/zsh/30-platform.zsh"; print -r -- NON_ZLE_STARTUP_OK' \
    >"$tmp/stdout" 2>"$tmp/stderr"; then
    cat "$tmp/stdout" "$tmp/stderr" >&2
    rm -rf "$tmp"
    return 1
  fi
  output=$(<"$tmp/stdout")
  if [[ "$output" != NON_ZLE_STARTUP_OK || -s "$tmp/stderr" ]]; then
    cat "$tmp/stdout" "$tmp/stderr" >&2
    rm -rf "$tmp"
    return 1
  fi
  rm -rf "$tmp"
}
check check_non_zle_zsh_startup

# Keep the existing Waybar tests outside source state. Decode helpers into a
# disposable directory so tests never import or execute the live-home scripts.
check_waybar_helpers() {
  local tmp file result=0
  tmp=$(mktemp -d)
  for file in home/dot_config/waybar/scripts/executable_*.py; do
    cp "$file" "$tmp/${file##*/executable_}"
  done
  cp tests/waybar/test_*.py "$tmp/"
  python3 -c 'import ast,pathlib,sys; [ast.parse(p.read_text(), filename=str(p)) for p in pathlib.Path(sys.argv[1]).glob("*.py")]' "$tmp" || result=$?
  HOME="$tmp" XDG_CACHE_HOME="$tmp/cache" PYTHONDONTWRITEBYTECODE=1 \
    python3 -m unittest discover -s "$tmp" -p 'test_*.py' || result=$?
  rm -rf "$tmp"
  return "$result"
}
check check_waybar_helpers

# Parse JSON and TOML with installed standard tools.
while IFS= read -r -d '' file; do
  check jq empty "$file"
done < <(find home . -path './.git' -prune -o -name '*.json' \
  ! -name 'modify_*.json' -print0)
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

check_kernel_classification() {
  local name=$1 expected=$2 override=$3 actual
  actual=$(chezmoi --source "$repo" --no-tty --override-data "$override" \
    execute-template '{{ $kernel := lower (default "" (index .chezmoi.kernel "osrelease")) }}{{ if (or (contains "microsoft" $kernel) (contains "wsl" $kernel)) }}true{{ else }}false{{ end }}')
  check test "$actual" = "$expected"
}
check_kernel_classification 'Microsoft kernel is WSL' true \
  '{"chezmoi":{"kernel":{"osrelease":"5.15.90.1-MICROSOFT-standard"}}}'
check_kernel_classification 'WSL kernel is WSL' true \
  '{"chezmoi":{"kernel":{"osrelease":"6.1.21.2-standard-WSL2"}}}'
check_kernel_classification 'ordinary kernel is not WSL' false \
  '{"chezmoi":{"kernel":{"osrelease":"6.8.0-31-generic"}}}'

# Exercise Pi's WSL filtering on every host, including runtime-state preservation.
check_pi_platform_settings() {
  local is_wsl=$1 rendered
  rendered=$(chezmoi --source "$repo" --no-tty \
    --override-data "{\"isWSL\":$is_wsl,\"chezmoi\":{\"stdin\":\"{\\\"lastChangelogVersion\\\":\\\"platform-sentinel\\\"}\"}}" \
    execute-template < home/dot_pi/private_agent/modify_settings.json)
  jq -e --argjson wsl "$is_wsl" --slurpfile baseline home/.chezmoitemplates/pi-settings.json '
    .lastChangelogVersion == "platform-sentinel" and
    if $wsl then
      .packages == ($baseline[0].packages | map(
        select(. != "git:github.com/jtabke/pi-companion") |
        if . == "git:github.com/jtabke/pi-extensions" then
          {source: ., extensions: ["!extensions/ollama*/**"]}
        else . end))
    else .packages == $baseline[0].packages end
  ' <<<"$rendered" >/dev/null
}
check check_pi_platform_settings true
check check_pi_platform_settings false
check_not jq -e 'any(.packages[]; (if type == "string" then . else .source end) | contains("lolipopshock/pi-clm"))' home/.chezmoitemplates/pi-settings.json
# Pi GitHub shorthand resolves to HTTPS; never require SSH keys for package clones.
check_not grep -nE 'git:git@|git:ssh://' home/.chezmoitemplates/pi-settings.json home/dot_pi/private_agent/modify_settings.json

# Render Linux/WSL profiles even on macOS. Execution tests use mocked adapters.
check_package_profile() {
  local name=$1 os=$2 kernel=$3 role=$4 desktop=$5 enabled=$6 expected=$7
  local override rendered
  override=$(jq -nc --arg os "$os" --arg kernel "$kernel" \
    --arg role "$role" --arg desktop "$desktop" --argjson enabled "$enabled" \
    '{chezmoi:{os:$os,kernel:{osrelease:$kernel}},role:$role,desktop:$desktop,installPackages:$enabled,osReleaseID:"ubuntu"}')
  rendered=$(chezmoi --source "$repo" --no-tty --override-data "$override" \
    execute-template "$(<home/run_onchange_install-packages.sh.tmpl)")
  check bash -n <<<"$rendered"
  if [[ "$expected" == true ]]; then
    check grep -qF 'packages+=(fuzzel:fuzzel)' <<<"$rendered"
  else
    check_not grep -qF 'fuzzel:fuzzel' <<<"$rendered"
  fi
  check grep -qF "install_enabled=$enabled" <<<"$rendered"
  printf 'PASS: %s package profile rendered (not executed)\n' "$name"
}
check_package_profile linux-auto linux 6.8.0 workstation auto true true
check_package_profile linux-hyprland linux 6.8.0 workstation hyprland true true
check_package_profile linux-shell linux 6.8.0 shell auto true false
check_package_profile linux-none linux 6.8.0 workstation none true false
check_package_profile wsl-shell linux 6.1-WSL2 shell none true false
check_package_profile wsl-workstation linux 5.15-MICROSOFT workstation hyprland true false
check_package_profile macos darwin 24.0 workstation auto true false
check_package_profile packages-disabled linux 6.1-WSL2 shell none false false

run_profile() {
  local name=$1 role=$2 desktop=$3
  local tmp dest baseline_dest cache config state dry second chezmoi_os is_wsl
  local expected_hyprland=false expected_fuzzel=false expected_aerospace=false expected_sketchybar=false
  tmp=$(mktemp -d)
  dest=$tmp/destination
  cache=$tmp/cache
  config=$tmp/config.toml
  state=$tmp/state.db
  mkdir -p "$dest" "$cache"

  # Only ask relevant questions: WSL skips both role and desktop; shell skips desktop.
  local kernel answers
  kernel=$(uname -r | tr '[:upper:]' '[:lower:]')
  if [[ "$kernel" == *microsoft* || "$kernel" == *wsl* ]]; then
    role=shell; desktop=none
    answers=$(printf 'false\nfalse\n')
  elif [[ "$role" == shell ]]; then
    answers=$(printf '%s\nfalse\nfalse\n' "$role")
  else
    answers=$(printf '%s\n%s\nfalse\nfalse\n' "$role" "$desktop")
  fi
  printf '%s\n' "$answers" \
    | chezmoi --source "$repo" --destination "$dest" --cache "$cache" \
      --config "$config" --persistent-state "$state" --no-tty init \
      >"$tmp/init.out" 2>"$tmp/init.err" || {
        cat "$tmp/init.out" "$tmp/init.err" >&2
        fail "$name clean init"
        rm -rf "$tmp"
        return
      }
  printf 'PASS: %s clean init\n' "$name"
  check grep -qF "role = \"$role\"" "$config"
  check grep -qF "desktop = \"$desktop\"" "$config"
  check grep -qF 'installPackages = false' "$config"
  check grep -qF 'autoTmux = false' "$config"
  chezmoi_os=$(chezmoi --source "$repo" --destination "$dest" --cache "$cache" \
    --config "$config" --persistent-state "$state" --no-tty \
    execute-template '{{ .chezmoi.os }}')
  is_wsl=$(awk -F= '$1 ~ /isWSL/ {gsub(/[[:space:]]/, "", $2); print $2}' "$config")
  check test "$chezmoi_os" = linux -o "$chezmoi_os" = darwin
  check test "$is_wsl" = true -o "$is_wsl" = false
  if [[ "$chezmoi_os" == linux && "$is_wsl" == false \
    && "$role" == workstation \
    && ("$desktop" == auto || "$desktop" == hyprland) ]]; then
    expected_hyprland=true
    expected_fuzzel=true
  fi
  if [[ "$chezmoi_os" == darwin && "$is_wsl" == false \
    && "$role" == workstation \
    && ("$desktop" == auto || "$desktop" == aerospace) ]]; then
    expected_aerospace=true
    expected_sketchybar=true
  fi
  if chezmoi --source "$repo" --destination "$dest" --cache "$cache" \
    --config "$config" --persistent-state "$state" --no-tty init </dev/null; then
    printf 'PASS: %s prompt answers persist\n' "$name"
  else
    fail "$name prompt answers persist"
  fi

  # Apply once without a pre-existing Pi target to prove the baseline does not
  # invent runtime-owned changelog or device identifiers. Use a separate destination so
  # the main dry-run still previews the complete profile before seeded apply.
  baseline_dest=$tmp/baseline-destination
  mkdir -p "$baseline_dest"
  chezmoi --source "$repo" --destination "$baseline_dest" --cache "$cache" \
    --config "$config" --persistent-state "$state" --no-tty --force apply \
    >"$tmp/baseline.out" 2>"$tmp/baseline.err" || {
      cat "$tmp/baseline.out" "$tmp/baseline.err" >&2
      fail "$name baseline apply"
      rm -rf "$tmp"
      return
    }
  check test -f "$baseline_dest/.pi/agent/settings.json"
  if [[ "$is_wsl" == true ]]; then
    check jq -e 'all(.packages[]; . != "git:github.com/jtabke/pi-companion")' \
      "$baseline_dest/.pi/agent/settings.json"
  else
    check jq -e 'any(.packages[]; . == "git:github.com/jtabke/pi-companion")' \
      "$baseline_dest/.pi/agent/settings.json"
  fi
  check test "$(pi_agent_mode "$baseline_dest/.pi/agent")" = 700
  check jq -e --slurpfile baseline home/.chezmoitemplates/pi-settings.json \
    '.theme == $baseline[0].theme and .defaultProvider == $baseline[0].defaultProvider and .subagents.defaultModel == $baseline[0].subagents.defaultModel and .tuiMode == $baseline[0].tuiMode and (has("lastChangelogVersion") | not) and (has("deviceId") | not)' \
    "$baseline_dest/.pi/agent/settings.json"

  # Seed obsolete files and Pi runtime state to prove source attributes converge
  # an existing home without overwriting runtime-owned changelog/device state.
  mkdir -p "$dest/.config/nvim/lua/plugins" "$dest/.config/nvim/after/ftplugin" \
    "$dest/.pi/agent"
  printf '%s\n' '{"lastChangelogVersion":"validation-sentinel","deviceId":"device-sentinel","theme":"runtime-value"}' \
    >"$dest/.pi/agent/settings.json"
  touch "$dest/.aerospace.toml" \
    "$dest/.config/nvim/lua/plugins/avante.lua" \
    "$dest/.config/nvim/lua/plugins/codecompanion.lua" \
    "$dest/.config/nvim/lua/plugins/llm.lua" \
    "$dest/.config/nvim/lua/plugins/nvim-ts-autotag.lua" \
    "$dest/.config/nvim/after/ftplugin/typescript.vim" \
    "$dest/.config/nvim/after/ftplugin/python.vim.bak"

  dry=$(chezmoi --source "$repo" --destination "$dest" --cache "$cache" \
    --config "$config" --persistent-state "$state" --no-tty --dry-run --verbose apply)
  if [[ "$expected_hyprland" == true ]]; then
    [[ "$dry" == *'.config/hypr/hyprland.lua'* ]] || fail "$name dry-run selects Hyprland"
  else
    [[ "$dry" != *'.config/hypr/hyprland.lua'* ]] || fail "$name dry-run excludes Hyprland"
  fi
  if [[ "$expected_fuzzel" == true ]]; then
    [[ "$dry" == *'.config/fuzzel/fuzzel.ini'* ]] || fail "$name dry-run selects Fuzzel"
  else
    [[ "$dry" != *'.config/fuzzel/fuzzel.ini'* ]] || fail "$name dry-run excludes Fuzzel"
  fi
  if [[ "$expected_aerospace" == true ]]; then
    [[ "$dry" == *'.config/aerospace/aerospace.toml'* ]] || fail "$name dry-run selects AeroSpace"
  else
    [[ "$dry" != *'.config/aerospace/aerospace.toml'* ]] || fail "$name dry-run excludes AeroSpace"
  fi
  if [[ "$expected_sketchybar" == true ]]; then
    [[ "$dry" == *'.config/sketchybar/sketchybarrc'* ]] || fail "$name dry-run selects SketchyBar"
  else
    [[ "$dry" != *'.config/sketchybar/sketchybarrc'* ]] || fail "$name dry-run excludes SketchyBar"
  fi

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
  check test -x "$dest/.local/bin/dotfiles-setup"
  check bash -n "$dest/.local/bin/dotfiles-setup"
  check test -f "$dest/.config/nvim/init.lua"
  check test -f "$dest/.npmrc"
  check grep -qF 'min-release-age=3' "$dest/.npmrc"
  check grep -qF 'ignore-scripts=false' "$dest/.npmrc"
  check test "$(pi_agent_mode "$dest/.npmrc")" = 600
  check_not test -e "$dest/.aerospace.toml"
  if [[ "$expected_hyprland" == true ]]; then
    check test -f "$dest/.config/hypr/hyprland.lua"
    check python3 -c 'import json,sys; json.loads("".join(line for line in open(sys.argv[1]) if not line.lstrip().startswith("//")))' "$dest/.config/waybar/config.jsonc"
    check test -f "$dest/.config/waybar/style.css"
    check test -f "$dest/.config/waybar/mocha.css"
    for helper in wifi_waybar bluetooth_waybar tailscale_waybar power_menu updates_waybar; do
      check test -x "$dest/.config/waybar/scripts/$helper.py"
    done
    check_not test -e "$dest/.config/waybar/scripts/test_waybar_helpers.py"
    check_not test -e "$dest/.config/waybar/scripts/test_tailscale_waybar.py"
  else
    check_not test -e "$dest/.config/hypr"
    check_not test -e "$dest/.config/waybar"
  fi
  if [[ "$expected_fuzzel" == true ]]; then
    check test -f "$dest/.config/fuzzel/fuzzel.ini"
  else
    check_not test -e "$dest/.config/fuzzel"
  fi
  if [[ "$expected_aerospace" == true ]]; then
    check test -f "$dest/.config/aerospace/aerospace.toml"
  else
    check_not test -e "$dest/.config/aerospace"
  fi
  if [[ "$expected_sketchybar" == true ]]; then
    check test -x "$dest/.config/sketchybar/sketchybarrc"
  else
    check_not test -e "$dest/.config/sketchybar"
  fi
  check_not test -e "$dest/.config/nvim/lua/plugins/avante.lua"
  check_not test -e "$dest/.config/nvim/lua/plugins/codecompanion.lua"
  check_not test -e "$dest/.config/nvim/lua/plugins/llm.lua"
  check_not test -e "$dest/.config/nvim/lua/plugins/nvim-ts-autotag.lua"
  check_not test -e "$dest/.config/nvim/after/ftplugin/typescript.vim"
  check_not test -e "$dest/.config/nvim/after/ftplugin/python.vim.bak"
  check test -f "$dest/.pi/agent/settings.json"
  check test "$(pi_agent_mode "$dest/.pi/agent")" = 700
  check_not test -x "$dest/.pi/agent/settings.json"
  check jq -e '.lastChangelogVersion == "validation-sentinel" and .deviceId == "device-sentinel"' \
    "$dest/.pi/agent/settings.json"
  check jq empty "$dest/.pi/agent/settings.json"
  check jq -e --slurpfile baseline home/.chezmoitemplates/pi-settings.json \
    '.theme == $baseline[0].theme and .defaultProvider == $baseline[0].defaultProvider and .subagents.defaultModel == $baseline[0].subagents.defaultModel and .tuiMode == $baseline[0].tuiMode' \
    "$dest/.pi/agent/settings.json"
  check test -x "$dest/.pi/agent/scripts/lint-subagent-sessions.mjs"
  check test -L "$dest/.config/kitty/theme.conf"
  check test "$(readlink "$dest/.config/kitty/theme.conf")" = ./kitty-themes/Galaxy.conf
  check node --check "$dest/.pi/agent/scripts/lint-subagent-sessions.mjs"

  while IFS= read -r -d '' file; do
    check jq empty "$file"
  done < <(find "$dest" -name '*.json' -print0)
  while IFS= read -r -d '' file; do
    check python3 -c 'import sys,tomllib; tomllib.load(open(sys.argv[1], "rb"))' "$file"
  done < <(find "$dest" -name '*.toml' -print0)
  if [[ "$expected_hyprland" == true ]]; then
    check grep -qF 'exec Hyprland' "$dest/.config/zsh/.zprofile"
    check grep -qF -- '-z "${TMUX-}"' "$dest/.config/zsh/.zprofile"
    check grep -qF -- '-z "${SSH_CONNECTION-}"' "$dest/.config/zsh/.zprofile"
    check grep -qF '"$(tty 2>/dev/null)" == /dev/tty1' "$dest/.config/zsh/.zprofile"
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

run_profile workstation-auto workstation auto
run_profile shell-none shell none

check git diff --check
if ((failures)); then
  printf '%d validation checks failed.\n' "$failures" >&2
  exit 1
fi
printf 'All repository and isolated chezmoi checks passed.\n'
