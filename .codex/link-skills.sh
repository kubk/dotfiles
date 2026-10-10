#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${1:-$HOME/projects/dotfiles/.codex/skills}"
shift || true
TARGET_DIRS=("$@")
if [ ${#TARGET_DIRS[@]} -eq 0 ]; then
  TARGET_DIRS=("$HOME/.codex/skills" "$HOME/.claude/skills")
fi

for target_dir in "${TARGET_DIRS[@]}"; do
  mkdir -p "$target_dir"

  for skill_path in "$SOURCE_DIR"/*; do
    if [ ! -e "$skill_path" ]; then
      continue
    fi

    skill_name="$(basename "$skill_path")"
    ln -sfn "$skill_path" "$target_dir/$skill_name"
  done
done
