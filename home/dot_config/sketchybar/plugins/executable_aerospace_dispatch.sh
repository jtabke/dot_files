#!/usr/bin/env bash
# Single dispatcher for all SketchyBar space items.
# - Only reacts to aerospace_workspace_change (no front_app_switched)
# - Uses event-provided FOCUSED_WORKSPACE (no extra focus probes)
# - One windows query for all items, no workspace switching ever

set -euo pipefail

PLUGIN_DIR="${CONFIG_DIR}/plugins"
# shellcheck disable=SC1090
source "$PLUGIN_DIR/icon_map.sh"

# Only run on actual workspace changes
if [[ "${SENDER-}" != "aerospace_workspace_change" ]]; then
  exit 0
fi

# Must have the event-provided focused workspace
FOCUSED="${FOCUSED_WORKSPACE-}"
if [[ -z "$FOCUSED" ]]; then
  exit 0
fi

# Need jq; if missing, quietly skip to avoid flicker
# if ! command -v jq >/dev/null 2>&1; then
#   exit 0
# fi

# # Fetch the whole window inventory once
# windows_json="$(aerospace list-windows --json 2>/dev/null || echo '[]')"
#
# # Get known space ids from SketchyBar items named 'space.<id>'; fallback to AeroSpace
# space_items="$(sketchybar --query 2>/dev/null \
#   | jq -r '.items[]?.name' | awk -F. '/^space\.[0-9]+$/ {print $2}')"
# if [[ -z "$space_items" ]]; then
#   space_items="$(aerospace list-workspaces --all --json 2>/dev/null \
#     | jq -r '.[].workspace' || true)"
# fi
#
# # Update each space item based on current windows_json
# for wsid in $space_items; do
#   [[ -z "$wsid" ]] && continue
#   # Unique app list for this workspace
#   apps="$(printf '%s' "$windows_json" \
#     | jq -r --arg ws "$wsid" '[ .[] | select(.workspaceId == $ws) | .appName ] | unique[]' 2>/dev/null || true)"
#
#   icons=""
#   if [[ -n "$apps" ]]; then
#     # Build icon row
#     while IFS= read -r app; do
#       [[ -z "$app" ]] && continue
#       __icon_map "$app"
#       if [[ -n "${icon_result-}" && "$icon_result" != ":default:" ]]; then
#         icons+="$icon_result"
#       else
#         icons+="􀏜"
#       fi
#     done <<< "$apps"
#   fi
#
#   name="space.$wsid"
#   if [[ "$wsid" == "$FOCUSED" ]]; then
#     if [[ -n "$icons" ]]; then
#       sketchybar --set "$name" background.drawing=on drawing=on icon.drawing=on label.drawing=on label="$icons"
#     else
#       sketchybar --set "$name" background.drawing=on drawing=on icon.drawing=on label.drawing=on label="$wsid"
#     fi
#   else
#     if [[ -n "$icons" ]]; then
#       sketchybar --set "$name" background.drawing=off drawing=on icon.drawing=on label.drawing=on label="$icons"
#     else
#       sketchybar --set "$name" background.drawing=off drawing=off icon.drawing=off label.drawing=off label=""
#     fi
#   fi
# done
# Enumerate workspace ids from AeroSpace (JSON schema: [{"workspace":"1"}, ...])
space_items="$(aerospace list-workspaces --all --json 2>/dev/null \
  | jq -r '.[].workspace' || true)"

# Fallback to AeroSpace JSON if bar has no space items yet
if [[ -z "$space_items" ]]; then
  # Newer AeroSpace returns [{"workspace":"1"}, ...]
  space_items="$(aerospace list-workspaces --all --json 2>/dev/null \
    | jq -r '.[].workspace' || true)"
fi

# Absolute last fallback: plain text list (one ID per line)
if [[ -z "$space_items" ]]; then
  space_items="$(aerospace list-workspaces --all 2>/dev/null || true)"
fi

# If we still have nothing, bail
[[ -z "$space_items" ]] && exit 0

# Update each space.* item
for wsid in $space_items; do
  [[ -z "$wsid" || "$wsid" == "null" ]] && continue

  # Build a unique, ordered list of app names for this workspace using the stable format API
  # (Avoids guessing JSON field names like .workspaceId/.appName which vary across versions)
  apps="$(
    aerospace list-windows --workspace "$wsid" --format "%{app-name}" 2>/dev/null \
      | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
      | awk 'NF && !seen[$0]++'
  )"

  icons=""
  if [[ -n "$apps" ]]; then
    while IFS= read -r app; do
      [[ -z "$app" ]] && continue
      __icon_map "$app"
      if [[ -n "${icon_result-}" && "$icon_result" != ":default:" ]]; then
        icons+="$icon_result"
      else
        icons+="􀏜"
      fi
    done <<< "$apps"
  fi

  name="space.$wsid"

  if [[ "$wsid" == "$FOCUSED" ]]; then
    # Focused: always drawn; icons if present, else show the number
    if [[ -n "$icons" ]]; then
      sketchybar --set "$name" background.drawing=on drawing=on icon.drawing=on label.drawing=on label="$icons"
    else
      sketchybar --set "$name" background.drawing=on drawing=on icon.drawing=on label.drawing=on label="$wsid"
    fi
  else
    # Unfocused: show if non-empty, otherwise hide
    if [[ -n "$icons" ]]; then
      sketchybar --set "$name" background.drawing=off drawing=on icon.drawing=on label.drawing=on label="$icons"
    else
      sketchybar --set "$name" background.drawing=off drawing=off icon.drawing=off label.drawing=off label=""
    fi
  fi
done
