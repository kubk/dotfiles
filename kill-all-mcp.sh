#!/usr/bin/env bash
set -euo pipefail

script_path="$(realpath "${BASH_SOURCE[0]}")"
script_dir="$(cd -- "$(dirname -- "$script_path")" && pwd)"
self="$script_path"
found=false

for script in "$script_dir"/kill-*-mcp.sh; do
  [[ -e "$script" ]] || continue
  [[ "$script" == "$self" ]] && continue

  found=true
  "$script"
done

if [[ "$found" == false ]]; then
  echo "No MCP cleanup scripts found"
fi
