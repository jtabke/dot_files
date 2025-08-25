#!/usr/bin/env bash
# Usage: aerospace_ws.sh <WORKSPACE_ID>
# - Renders app icons for the workspace
# - Highlights the focused workspace using $FOCUSED_WORKSPACE from the event

set -euo pipefail

WS="$1"
PLUGIN_DIR="${CONFIG_DIR}/plugins"
# shellcheck disable=SC1090
source "$PLUGIN_DIR/icon_map.sh"

# --- Figure out who is focused ---
# On aerospace_workspace_change, SketchyBar passes FOCUSED_WORKSPACE.
FOCUSED="${FOCUSED_WORKSPACE-}"

# If we were invoked for a different event (e.g., front_app_switched),
# $FOCUSED_WORKSPACE may be empty. In that case, quickly query focus once.
if [[ -z "$FOCUSED" ]]; then
  if command -v jq >/dev/null 2>&1; then
    FOCUSED="$(aerospace list-workspaces --json 2>/dev/null \
      | jq -r '.[] | select(.focused==true) | .id' | head -n1 || true)"
  else
    # Fallback without jq: parse plain list and pick the line with '*'
    # (works on AeroSpace versions that mark focused with an asterisk)
    FOCUSED="$(aerospace list-workspaces 2>/dev/null | awk '/\*/{print $1; exit}')"
  fi
fi

# --- Highlight background ONLY when focus actually changes ---
# Avoid fighting with ourselves during front_app_switched refreshes.
if [[ "${SENDER-}" == "aerospace_workspace_change" ]]; then
  if [[ "$FOCUSED" == "$WS" ]]; then
    sketchybar --set "$NAME" background.drawing=on
  else
    sketchybar --set "$NAME" background.drawing=off
  fi
fi

# --- Build icon row (no literal \n in format) ---
apps="$(
  aerospace list-windows --workspace "$WS" --format "%{app-name}" 2>/dev/null \
  | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
  | awk 'NF && !seen[$0]++'
)"

icons=""
while IFS= read -r app; do
  [[ -z "$app" ]] && continue
  __icon_map "$app"
  if [[ -n "${icon_result-}" && "$icon_result" != ":default:" ]]; then
    icons+="$icon_result"
  else
    icons+="􀏜"  # fallback SF symbol
  fi
done <<< "$apps"

# --- Visibility: always show focused WS, hide empty others ---
if [[ -n "$icons" ]]; then
  sketchybar --set "$NAME" drawing=on label.drawing=on label="$icons" icon.drawing=on
elif [[ "$FOCUSED" == "$WS" ]]; then
  # FIX: label.drawing should be ON here (was off)
  sketchybar --set "$NAME" drawing=on label.drawing=off label="$WS" icon.drawing=on
else
  sketchybar --set "$NAME" drawing=off label="" label.drawing=off icon.drawing=off
fi
