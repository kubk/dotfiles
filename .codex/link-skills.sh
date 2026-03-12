#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${1:-$HOME/projects/dotfiles/.codex/skills}"
TARGET_DIR="${2:-$HOME/.codex/skills}"

mkdir -p "$TARGET_DIR"

for skill_path in "$SOURCE_DIR"/*; do
  if [ ! -e "$skill_path" ]; then
    continue
  fi

  skill_name="$(basename "$skill_path")"
  ln -sfn "$skill_path" "$TARGET_DIR/$skill_name"
done
