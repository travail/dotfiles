# Async git prompt using SIGUSR1 pattern
_git_prompt=""
_git_async_tmpfile=$(mktemp -t git_prompt.XXXXXX)

_git_prompt_update() {
  local git_dir branch action flags="" info=""

  # Get git dir and branch in one call; exit if not in a git repository
  local rev_out
  rev_out=$(git rev-parse --git-dir --abbrev-ref HEAD 2>/dev/null) || {
    echo "" > "$_git_async_tmpfile"
    return
  }
  git_dir=${rev_out%%$'\n'*}
  branch=${rev_out##*$'\n'}

  # Detached HEAD: fall back to short commit hash
  [[ "$branch" == "HEAD" ]] && branch=$(git rev-parse --short HEAD 2>/dev/null)

  # Detect in-progress operations (rebase, merge, etc.)
  if [[ -f "$git_dir/rebase-merge/interactive" ]]; then action="rebase-i"
  elif [[ -d "$git_dir/rebase-merge" ]]; then action="rebase-m"
  elif [[ -d "$git_dir/rebase-apply" ]]; then action="rebase"
  elif [[ -f "$git_dir/MERGE_HEAD" ]]; then action="merge"
  elif [[ -f "$git_dir/CHERRY_PICK_HEAD" ]]; then action="cherry-pick"
  fi

  # --no-optional-locks must appear before the subcommand, not after
  local status_out
  status_out=$(git --no-optional-locks status --porcelain 2>/dev/null)
  grep -q '^.[^ ?]' <<< "$status_out" && flags+=" %F{red}●%f"     # unstaged
  grep -q '^[^ ?]'  <<< "$status_out" && flags+=" %F{green}○%f"  # staged
  grep -q '^??'      <<< "$status_out" && flags+=" %F{yellow}…%f" # untracked

  # Build prompt string with Solarized colors
  info="%F{blue}${branch}%f"
  [[ -n $action ]] && info+="%F{magenta}|${action}%f"
  info+="${flags}"

  echo "$info" > "$_git_async_tmpfile"
}

# SIGUSR1 handler: read result from tmp file and redraw prompt
TRAPUSR1() {
  _git_prompt=$(cat "$_git_async_tmpfile")
  zle reset-prompt 2>/dev/null
  return 0
}

# Launch git prompt update in background, signal parent when done
_git_prompt_start_async() {
  {
    _git_prompt_update
    kill -USR1 $$
  } &!
}

# Remove any leftover vcs_info hook from previous configurations
precmd_functions=( ${precmd_functions:#precmd_vcs_info} )
precmd_functions=( ${precmd_functions:#_git_prompt_update} )
# Register async hook, guarded against duplicate registration on re-source
if (( ! ${precmd_functions[(Ie)_git_prompt_start_async]} )); then
  precmd_functions+=( _git_prompt_start_async )
fi

setopt prompt_subst

# Left: timestamp + ❯ colored by last exit status
PROMPT='%D{%Y-%m-%d %H:%M:%S} %(?:%F{green}:%F{red})❯%f '
# Right: git info + current directory
RPROMPT='${_git_prompt:+${_git_prompt} }%F{cyan}%~%f'
