# Called on each precmd hook to update _git_prompt
_git_prompt_update() {
  local git_dir branch action flags="" info=""

  # Clear prompt and exit if not inside a git repository
  if ! git_dir=$(git rev-parse --git-dir 2>/dev/null); then
    _git_prompt=""
    return
  fi

  # Branch name, or commit hash when in detached HEAD state
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

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

  _git_prompt=$info
}

# Remove any leftover vcs_info hook from previous configurations
precmd_functions=( ${precmd_functions:#precmd_vcs_info} )
# Register hook, guarded against duplicate registration on re-source
if (( ! ${precmd_functions[(Ie)_git_prompt_update]} )); then
  precmd_functions+=( _git_prompt_update )
fi

setopt prompt_subst

# Left: timestamp + ❯ colored by last exit status
PROMPT='%D{%Y-%m-%d %H:%M:%S} %(?:%F{green}:%F{red})❯%f '
# Right: git info + current directory
RPROMPT='${_git_prompt:+${_git_prompt} }%F{cyan}%~%f'
