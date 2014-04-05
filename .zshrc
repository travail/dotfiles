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

autoload -U compinit
compinit
setopt auto_pushd

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

# rbenv
export RBENV_ROOT=/usr/local/rbenv
export PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"
if [ `which rbenv 2> /dev/null` ]; then
    eval "$(rbenv init -)"
fi

# set aliases
case ${OSTYPE} in
    darwin*)
        alias ls='ls -G'
        ;;
    linux*)
        alias ls='ls -F --color=auto'
        ;;
esac
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias eng='LANG=C LANGUAGE=C LC_ALL=C'

# set umask
umask 002

# plenv
export PLENV_ROOT=/usr/local/plenv
export PATH="$PLENV_ROOT/bin:$PLENV_ROOT/shims:$PATH"
if [ `which plenv 2> /dev/null` ]; then
    eval "$(plenv init -)"
fi
