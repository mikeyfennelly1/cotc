#!/bin/bash
# Installs git hooks by symlinking from scripts/hooks/ into .git/hooks/
# Usage: install-hooks.sh [--init]
#   --init  Also create VERSION (0.1.0) and CHANGELOG.md if they don't exist

set -e

INIT=false
for arg in "$@"; do
    [ "$arg" = "--init" ] && INIT=true
done

REPO_ROOT=$(git rev-parse --show-toplevel)
HOOKS_SRC="$REPO_ROOT/scripts/hooks"
HOOKS_DEST="$REPO_ROOT/.git/hooks"

for hook in "$HOOKS_SRC"/*; do
    name=$(basename "$hook")
    dest="$HOOKS_DEST/$name"

    chmod +x "$hook"

    if [ -L "$dest" ]; then
        rm "$dest"
    elif [ -f "$dest" ]; then
        echo "WARNING: Backing up existing $name hook to $dest.bak"
        mv "$dest" "$dest.bak"
    fi

    ln -s "$hook" "$dest"
    echo "Installed $name hook"
done

echo "Done. Hooks installed."

if [ "$INIT" = true ]; then
    if [ ! -f "$REPO_ROOT/VERSION" ]; then
        echo "0.1.0" > "$REPO_ROOT/VERSION"
        echo "Initialized VERSION (0.1.0)"
    else
        echo "VERSION already exists, skipping"
    fi

    if [ ! -f "$REPO_ROOT/CHANGELOG.md" ]; then
        cat > "$REPO_ROOT/CHANGELOG.md" <<'EOF'
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]
EOF
        echo "Initialized CHANGELOG.md"
    else
        echo "CHANGELOG.md already exists, skipping"
    fi
fi
