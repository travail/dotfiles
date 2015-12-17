#!/bin/env zsh

function _on-complete() {
    if zle; then
        BUFFER=$1
        CURSOR=$#BUFFER
    else
        print -z $1
    fi
}
