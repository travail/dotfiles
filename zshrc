-*- mode: Shell-script -*-

#
# .zshrc is sourced in interactive shells.
# It should contain commands to set up aliases,
# functions, options, key bindings, etc.
#

# ssh
agent="$HOME/.ssh-agent-`hostname`"
if [ -S "$agent" ]; then
    export SSH_AUTH_SOCK=$agent
elif [ ! -S "$SSH_AUTH_SOCK" ]; then
    export SSH_AUTH_SOCK=$agent
elif [ ! -L "$SSH_AUTH_SOCK" ]; then
    ln -snf "$SSH_AUTH_SOCK" $agent && export SSH_AUTH_SOCK=$agent
fi

printf "\033P\033]0;$USER@$HOSTNAME\007\033\\"

autoload -Uz compinit
compinit

#allow tab completion in the middle of a word
setopt COMPLETE_IN_WORD

## keep background processes at full speed
#setopt NOBGNICE
## restart running processes on exit
#setopt HUP

## history
#setopt APPEND_HISTORY
## for sharing history between zsh processes
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt INC_APPEND_HISTORY
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt share_history
setopt print_eight_bit

## complement
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
#zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z} r:|[-_.]=**'
zstyle ':completion:*' menu select=1

## never ever beep ever
setopt NO_BEEP

## automatically decide when to page a list of completions
#LISTMAX=0

## disable mail checking
#MAILCHECK=0

# autoload -U colors
#colors

export PERL_BADLANG=0
export GREP_OPTIONS="--color=auto"

# java
export JAVA_HOME=/usr/java/default

# set umask
umask 002

for file (`find ~/.zsh/ -type f -name '*.sh'`) do
    if [ -f $file ]; then
        source $file
    fi
done

# Override by local setting
if [ -d ~/.zsh.local ]; then
    for file (`find ~/.zsh.local -type f -name '*.sh'`) do
        if [ -f $file ]; then
            source $file
        fi
    done
fi
