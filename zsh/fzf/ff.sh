_ff() {
    local subcommands=(
        'ps:Select a process and print its PID'
        'kill:Select a process and kill it (default: SIGTERM)'
        'cd:Select a directory from cdr history and cd into it'
        'env:Select an environment variable and print its name'
        'ssh:Select a host from ~/.ssh/config and connect'
        'man:Select a man page and open it'
        'alias:Select an alias and execute it'
        'bindkey:Select a key binding and print it'
        'help:Show help message'
    )
    if (( CURRENT == 2 )); then
        _describe 'subcommand' subcommands
    fi
}
compdef _ff ff

ff() {
    local cmd="$1"
    shift
    case "$cmd" in
        ps)
            ps aux | fzf --header-lines=1 --prompt="ps> " | awk '{print $2}'
            ;;
        kill)
            local sig="${1:--TERM}"
            local pid
            pid=$(ps aux | fzf --header-lines=1 --prompt="kill> " | awk '{print $2}')
            [ -n "$pid" ] && kill "$sig" "$pid"
            ;;
        cd)
            local dir
            dir=$(cdr -l | sed 's/^[0-9]* *//' | fzf --prompt="cd> ")
            [ -n "$dir" ] && cd "$dir"
            ;;
        env)
            env | fzf --prompt="env> " | cut -d= -f1
            ;;
        ssh)
            local host
            host=$(grep -i "^Host " "${HOME}/.ssh/config" 2>/dev/null \
                | grep -v '\*' \
                | awk '{print $2}' \
                | fzf --prompt="ssh> ")
            [ -n "$host" ] && ssh "$host"
            ;;
        man)
            local page
            page=$(man -k . 2>/dev/null | fzf --prompt="man> " | awk '{print $1}')
            [ -n "$page" ] && man "$page"
            ;;
        alias)
            local selected
            selected=$(alias | fzf --prompt="alias> " | cut -d= -f2- | tr -d "'\"")
            [ -n "$selected" ] && eval "$selected"
            ;;
        bindkey)
            bindkey | fzf --prompt="bindkey> "
            ;;
        help|--help|-h|"")
            echo "Usage: ff <subcommand> [options]"
            echo ""
            echo "Subcommands:"
            echo "  ps             Select a process and print its PID"
            echo "  kill [-SIG]    Select a process and kill it (default: SIGTERM)"
            echo "  cd             Select a directory from cdr history and cd into it"
            echo "  env            Select an environment variable and print its name"
            echo "  ssh            Select a host from ~/.ssh/config and connect"
            echo "  man            Select a man page and open it"
            echo "  alias          Select an alias and execute it"
            echo "  bindkey        Select a key binding and print it"
            echo "  help           Show this help message"
            ;;
        *)
            echo "ff: unknown subcommand '$cmd'" >&2
            echo "Run 'ff help' for usage." >&2
            return 1
            ;;
    esac
}
