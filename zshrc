# -*- mode: Shell-script -*-

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

PROMPT="[%n@%m]%~%% "
RPROMPT="[%D %*]"

autoload -Uz compinit chpwd_recent_dirs cdr add-zsh-hook
compinit -u

# Allow tab completion in the middle of a word
setopt COMPLETE_IN_WORD

# history
# setopt APPEND_HISTORY
# for sharing history between zsh processes
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt INC_APPEND_HISTORY
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt share_history
setopt print_eight_bit

# Completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select=1

# cdr
zstyle ':completion:*:*:cdr:*:*' menu selection
zstyle ':completion:*' recent-dirs-insert both
zstyle ':chpwd:*' recent-dirs-max 500
zstyle ':chpwd:*' recent-dirs-default true
zstyle ':chpwd:*' recent-dirs-file "${XDG_CACHE_HOME:-$HOME/.cache}/shell/chpwd-recent-dirs"
zstyle ':chpwd:*' recent-dirs-pushd true


# Never ever beep ever
setopt NO_BEEP

export PERL_BADLANG=0
export GREP_OPTIONS="--color=auto"
export GPG_TTY=$(tty)

# java
export JAVA_HOME=/usr/java/default

# Set umask
umask 002

PATH=$PATH:~/bin:/opt/homebrew/bin
PROMPT='%D{%Y-%m-%d %H:%M:%S} '
RPROMPT='% %~'

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

