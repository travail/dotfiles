# Completions for aqua-managed CLIs. aqua does not install completion files, so
# generate them once and cache the output (same approach as fzf/init.sh).
# After upgrading a tool, delete its cache file under the directory below.
# The generator is run with `command` to bypass the 1Password gh()/aws()
# wrappers defined in zsh/common/op/init.sh, which would call `op run`.
_comp_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/completions"
mkdir -p "$_comp_cache_dir"

# _comp_source NAME ARGS...: source the completion script printed by `NAME ARGS...`.
_comp_source() {
    local name="$1"; shift
    local bin cache="$_comp_cache_dir/$name.zsh"
    bin="$(whence -p "$name")" || return 0
    if [[ ! -s "$cache" ]] || [[ "$bin" -nt "$cache" ]]; then
        if command "$name" "$@" > "$cache.$$"; then
            mv "$cache.$$" "$cache"
        else
            rm -f "$cache.$$"
        fi
    fi
    [[ -s "$cache" ]] && source "$cache"
}

_comp_source gh completion -s zsh
_comp_source kubectl completion zsh
_comp_source k9s completion zsh
_comp_source github-mcp-server completion zsh

if whence -p aws_completer >/dev/null; then
    autoload -Uz bashcompinit && bashcompinit
    complete -C aws_completer aws
fi

unset -f _comp_source
unset _comp_cache_dir
