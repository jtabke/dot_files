#!/usr/bin/env bash
# Use the selected chezmoi profile before applying anything to your home.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
chezmoi --source "$repo" execute-template --file \
  "$repo/home/dot_local/bin/executable_dotfiles-setup.tmpl" >"$tmp"
bash "$tmp" "$@"
