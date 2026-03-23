#!/usr/bin/env bash

set -e

BASEDIR=$(readlink -e "$(dirname "$0")/")
PROJECT_DIR="${BASEDIR}/.."

# --------------------------------------------------
# Deps check
# --------------------------------------------------

if ! command -v gum &>/dev/null; then
  echo "ERROR: gum is not installed. See https://github.com/charmbracelet/gum"
  exit 1
fi

# --------------------------------------------------
# Header
# --------------------------------------------------

gum style \
  --foreground 212 --border-foreground 212 --border double \
  --align center --width 50 --margin "1 2" \
  "cotc  version form"

# --------------------------------------------------
# 1. Select component
# --------------------------------------------------

COMPONENT=$(gum choose \
  --header "Select component to version:" \
  "cotccli" \
  "cotccollector" \
  "cotcgui" \
  "cotcsubscriber" \
  "libcotc")

# Resolve the changelog path for the selected component
case "$COMPONENT" in
  cotccli)       CHANGELOG="${PROJECT_DIR}/cotccli/CHANGELOG.md" ;;
  cotccollector) CHANGELOG="${PROJECT_DIR}/cotccollector/CHANGELOG.md" ;;
  cotcgui)       CHANGELOG="${PROJECT_DIR}/cotcgui/CHANGELOG.md" ;;
  cotcsubscriber) CHANGELOG="${PROJECT_DIR}/cotcsubscriber/CHANGELOG.md" ;;
  libcotc)       CHANGELOG="${PROJECT_DIR}/libcotc/CHANGELOG.md" ;;
esac

# --------------------------------------------------
# 2. Version number
# --------------------------------------------------

NEW_VERSION=$(gum input \
  --placeholder "e.g. 1.4.0" \
  --prompt "New version for ${COMPONENT}: ")

if [[ -z "$NEW_VERSION" ]]; then
  echo "No version entered. Exiting."
  exit 1
fi

TODAY=$(date +%Y-%m-%d)

# --------------------------------------------------
# 3. Change sections (multi-select)
# --------------------------------------------------

SECTIONS=$(gum choose \
  --no-limit \
  --header "Select change categories (space to toggle, enter to confirm):" \
  "Features" \
  "Bug Fixes" \
  "Breaking Changes" \
  "Performance" \
  "Refactor" \
  "Documentation" \
  "Chore")

if [[ -z "$SECTIONS" ]]; then
  echo "No sections selected. Exiting."
  exit 1
fi

# --------------------------------------------------
# 4. Collect entries per section
# --------------------------------------------------

declare -A SECTION_ENTRIES

while IFS= read -r SECTION; do
  gum style --foreground 99 "  ${SECTION}"
  ENTRIES=()

  while true; do
    ENTRY=$(gum input \
      --placeholder "Describe change (leave blank to finish section)" \
      --prompt "> ")

    [[ -z "$ENTRY" ]] && break
    ENTRIES+=("$ENTRY")
  done

  if [[ ${#ENTRIES[@]} -gt 0 ]]; then
    JOINED=$(printf "* %s\n" "${ENTRIES[@]}")
    SECTION_ENTRIES["$SECTION"]="$JOINED"
  fi
done <<< "$SECTIONS"

# --------------------------------------------------
# 5. Build changelog block
# --------------------------------------------------

NEW_BLOCK="# [${NEW_VERSION}] - ${TODAY}"$'\n'
NEW_BLOCK+=$'\n'

while IFS= read -r SECTION; do
  if [[ -n "${SECTION_ENTRIES[$SECTION]+x}" ]]; then
    NEW_BLOCK+="### ${SECTION}"$'\n'
    NEW_BLOCK+="${SECTION_ENTRIES[$SECTION]}"$'\n'
    NEW_BLOCK+=$'\n'
  fi
done <<< "$SECTIONS"

# --------------------------------------------------
# 6. Preview
# --------------------------------------------------

gum style --border normal --margin "1 2" --padding "1 2" \
  --border-foreground 212 \
  "$(echo -e "Preview for ${COMPONENT} CHANGELOG:\n\n${NEW_BLOCK}")"

# --------------------------------------------------
# 7. Confirm and write
# --------------------------------------------------

if gum confirm "Write this entry to ${CHANGELOG}?"; then
  # Create CHANGELOG if it doesn't exist yet
  if [[ ! -f "$CHANGELOG" ]]; then
    echo "# Changelog" > "$CHANGELOG"
    echo "" >> "$CHANGELOG"
  fi

  # Prepend new block after the first line (the "# Changelog" header) if present,
  # otherwise just prepend to the top.
  HEADER_LINE=$(head -1 "$CHANGELOG")
  if [[ "$HEADER_LINE" == "# Changelog"* ]]; then
    TAIL=$(tail -n +2 "$CHANGELOG")
    printf '%s\n\n%s\n%s' "# Changelog" "$NEW_BLOCK" "$TAIL" > "$CHANGELOG"
  else
    EXISTING=$(cat "$CHANGELOG")
    printf '%s\n%s' "$NEW_BLOCK" "$EXISTING" > "$CHANGELOG"
  fi

  gum style --foreground 82 "  Written to ${CHANGELOG}"
else
  gum style --foreground 196 "  Aborted. No changes written."
  exit 0
fi
