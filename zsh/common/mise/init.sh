if is_human; then
    eval "$(mise activate zsh)"
else
    # Use shims for non-human / AI agent shells so per-project versions resolve without
    # chpwd/precmd hooks, and keep shims ahead of paths added by /etc/zprofile (path_helper).
    eval "$(mise activate zsh --shims)"
    _mise_shims_dir="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"
    if [[ -d "$_mise_shims_dir" ]]; then
        path=("$_mise_shims_dir" ${path:#$_mise_shims_dir})
    fi
    unset _mise_shims_dir
fi
