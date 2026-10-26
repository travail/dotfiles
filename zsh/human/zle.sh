# -*- mode: Shell-script -*-
# ZLE (Zsh Line Editor) custom widgets and keybindings

autoload -Uz match-words-by-style

# Delete backward by subword (camelCase, snake_case, path segments, etc.)
backward-kill-subword() {
    local curcontext=":zle:$WIDGET"
    local -a matched_words
    integer count=${NUMERIC:-1}

    if (( count < 0 )); then
        (( NUMERIC = -count ))
        zle kill-word
        return
    fi

    local done
    while (( count-- )); do
        match-words-by-style
        local word="$matched_words[2]$matched_words[3]"

        if [[ -n $word ]]; then
            if [[ -n $done || $LASTWIDGET = *kill* ]]; then
                CUTBUFFER="$word$CUTBUFFER"
            else
                zle copy-region-as-kill -- "$word"
            fi
            LBUFFER=$matched_words[1]
        elif [[ -n $LBUFFER ]]; then
            local trailing="${LBUFFER[-1]}"
            if [[ -n $done || $LASTWIDGET = *kill* ]]; then
                CUTBUFFER="$trailing$CUTBUFFER"
            else
                zle copy-region-as-kill -- "$trailing"
            fi
            LBUFFER="${LBUFFER[1,-2]}"
        else
            return 1
        fi
        done=1
    done

    zle -f 'kill'
    return 0
}

zle -N backward-kill-subword
zstyle ':zle:backward-kill-subword' word-style standard-subword
zstyle ':zle:backward-kill-subword' word-chars ''
zstyle ':zle:backward-kill-subword' skip-whitespace-first true

# Bind Ctrl+W to subword backward-kill
bindkey '^W' backward-kill-subword
