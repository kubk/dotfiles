source ~/projects/dotfiles/aliases

# History settings
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS      # Don't save duplicate commands
setopt SHARE_HISTORY         # Share history between terminal sessions

export HOMEBREW_NO_AUTO_UPDATE=1

alert() {
    local message="$1"
    local delay=${2:-0}

    # Remove 'm' from delay and convert it to seconds
    delay=${delay%m} 
    delay=$((delay * 60))

    # Use sleep for the delay and then show the notification
    (sleep "$delay"; osascript -e "display notification \"$message\"") &
}


# Find and set branch name var if in git repository.
function git_branch_name()
{
  branch=$(git symbolic-ref HEAD 2> /dev/null | awk 'BEGIN{FS="/"} {print $NF}')
  if [[ $branch == "" ]];
  then
    :
  else
    echo '- ('$branch')'
  fi
}

# Enable substitution in the prompt.
setopt prompt_subst

# Config for prompt. PS1 synonym.
prompt='%2/ $(git_branch_name) > '

export PATH="$PATH:/Users/egor/projects/flutter/bin:/opt/homebrew/opt/postgresql@13/bin:$HOME/.composer/vendor/bin"
export PATH="/opt/homebrew/opt/php@7.4/bin:$PATH"
export PATH="/opt/homebrew/opt/php@7.4/sbin:$PATH"
export PATH="/opt/homebrew/opt/php@8.1/bin:$PATH"
export PATH="/opt/homebrew/opt/php@8.1/sbin:$PATH"

export PATH="/Users/egor/.local/bin:$PATH"


# opencode
export PATH=/Users/egor/.opencode/bin:$PATH

. "$HOME/.acton/bin/env"

# SellCodebase CLI
export PATH="/Users/egor/.sellcodebase/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/egor/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Added by the Hunk installer (https://hunk.dev)
export PATH='/Users/egor/.hunk/bin':"$PATH"
