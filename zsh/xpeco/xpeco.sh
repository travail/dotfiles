#!/bin/env zsh

local basedir=$(dirname $0)

export FPATH="$FPATH:$basedir/functions"

local fp f
for fp in $(ls $basedir/functions/*); do
    f=$(basename $fp)
    autoload -U $f

    ## TODO: More tidy.
    ## Apply keybinds.
    case $f in
        _*)
            ;;
        xpeco-find)
            zle -N $f
            bindkey '^x^f' $f
            ;;
        xpeco-history)
            zle -N $f
            bindkey '^r' $f
            ;;
    esac
done

compdef _xpeco xpeco

function xpeco {
    readonly local action=$1

    xpeco-help () {
        echo 'Usage: xpeco <command>'
        echo
        echo 'Commands:'
        local fp
        for fp in $(ls $basedir/functions | grep -v _); do
            echo -n '  '
            # trim "xpeco-"
            basename $fp | cut -b 7-
        done
    }

    case $action in
        -h|--help)
            xpeco-help
            return
            ;;
        *)
            if [ $# -gt 0 ]; then
                shift
            fi
            ;;
    esac

    if type "xpeco-$action" > /dev/null 2>&1; then
        "xpeco-$action" $@
    else
        xpeco-help
        echo "Command not found: $action"
    fi
}
