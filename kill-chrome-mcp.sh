#!/usr/bin/env bash
set -euo pipefail

pids="$(
  ps -axo pid=,ppid=,command= | awk -v self="$$" '
    {
      pid = $1
      ppid = $2
      cmd = $0
      order[++n] = pid
      parent[pid] = ppid

      if (cmd ~ /chrome-devtools-mcp/ && cmd !~ /kill-chrome-mcp/) {
        killme[pid] = 1
      }
    }

    END {
      changed = 1
      while (changed) {
        changed = 0
        for (i = 1; i <= n; i++) {
          pid = order[i]
          if (!killme[pid] && killme[parent[pid]]) {
            killme[pid] = 1
            changed = 1
          }
        }
      }

      for (i = 1; i <= n; i++) {
        pid = order[i]
        if (killme[pid] && pid != self) {
          print pid
        }
      }
    }
  '
)"

if [[ -z "$pids" ]]; then
  echo "No chrome-devtools-mcp processes found."
  exit 0
fi

count="$(wc -l <<< "$pids" | tr -d ' ')"

echo "$pids" | xargs kill -TERM 2>/dev/null || true
sleep 1

survivors=""
for pid in $pids; do
  if kill -0 "$pid" 2>/dev/null; then
    survivors="$survivors $pid"
  fi
done

if [[ -n "$survivors" ]]; then
  # shellcheck disable=SC2086
  kill -KILL $survivors 2>/dev/null || true
fi

echo "Killed $count chrome-devtools-mcp process(es)."
