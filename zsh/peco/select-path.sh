funciton peco-select-path() {
    BUFFER="${BUFFER}$(find . | grep -v '/\.' | peco)"
    CURSOR=$#BUFFER
    zle clear-screen
}
zle -N peco-select-path
bindkey '^x^f' peco-select-path
