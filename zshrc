# -*- mode: Shell-script -*-

# Common environment variables for both human and AI
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PERL_BADLANG=0
umask 002

PATH=$PATH:~/bin

# Load common zsh configs (tools, PATH, wrappers)
for file (~/.zsh/common/**/*.sh(N)) do
    source $file
done

# Override by local setting (common)
if [ -d ~/.zsh.local ]; then
    for file (~/.zsh.local/**/*.sh(N)) do
        source $file
    done
fi

# rm safety wrapper
alias rm=airm

# Early return for AI / non-human shell
is_human || return 0

# Human interactive shell settings
export EDITOR=vim
export PAGER=less
# Ensure emacs keybindings even when EDITOR is vi/vim
bindkey -e
# Required for GPG to find the TTY for passphrase input.
# Redundant since pinentry-mac handles it via GUI dialog, but kept as a fallback.
export GPG_TTY=$(tty)

# history
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt INC_APPEND_HISTORY
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt share_history
setopt print_eight_bit

# Completion
setopt COMPLETE_IN_WORD
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select=1

# make: suggest targets and variables, not local files
# Both tags in one string so they are offered together; separate arguments would
# mean "fall back to variables only when targets yields nothing".
zstyle ':completion:*:*:make:*' tag-order 'targets variables'

# cdr
zstyle ':completion:*:*:cdr:*:*' menu selection
zstyle ':completion:*' recent-dirs-insert both
zstyle ':chpwd:*' recent-dirs-max 500
zstyle ':chpwd:*' recent-dirs-default true
zstyle ':chpwd:*' recent-dirs-file "${XDG_CACHE_HOME:-$HOME/.cache}/shell/chpwd-recent-dirs"
zstyle ':chpwd:*' recent-dirs-pushd true

autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs

# Never ever beep ever
setopt NO_BEEP

# zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Zim
ZSH_DISABLE_COMPFIX=true
ZIM_HOME=~/.zim
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi
if [[ ! ${ZIM_HOME}/init.zsh -nt ~/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi
source ${ZIM_HOME}/init.zsh

autoload -Uz compinit
# Always use cached dump (-C). Run `compinit && exec zsh` to rebuild after installing new tools.
compinit -C -u

# Load human-specific interactive configs (aliases, prompts, fzf, git completion)
for file (~/.zsh/human/**/*.sh(N)) do
    source $file
done
