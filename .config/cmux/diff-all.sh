#!/bin/zsh
# Terminal diff of the working tree including untracked files (no index changes).
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Not a git repository: $PWD"
  exec "$SHELL" -l
fi
{
  git diff --color=always
  git ls-files --others --exclude-standard -z | xargs -0 -n1 git diff --no-index --color=always -- /dev/null
} | less -RFX
exec "$SHELL" -l
