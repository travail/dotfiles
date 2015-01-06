funciton peco-select-history() {
    BUFFER=$(history -r -n 1 | peco --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle clear-screen
}
zle -N peco-select-history
bindkey '^r' peco-select-history
