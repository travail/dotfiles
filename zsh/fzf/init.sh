_fzf_cache="${XDG_CACHE_HOME:-$HOME/.cache}/fzf-init.zsh"
if [[ ! -f "$_fzf_cache" ]] || [[ "$(command -v fzf)" -nt "$_fzf_cache" ]]; then
    fzf --zsh > "$_fzf_cache"
fi
source "$_fzf_cache"
unset _fzf_cache
