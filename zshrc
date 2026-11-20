# -*- mode: Shell-script -*-

# Common environment variables for both human and AI
export LANG=en_US.UTF-8
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

# Keep PATH entries unique. Scalar `export PATH=...` assignments in the files above
# bypass the -U flag, so the array must be re-assigned once after all of them ran.
typeset -U path
path=($path)

# rm safety wrapper (AI agent only)
! is_human && alias rm=airm

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

# Disable zsh default menu selection to let fzf-tab handle it cleanly.
# Must run after Zim completion module, which sets 'menu select'.
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'

# Keep flat layout and preserve completion candidate order in fzf-tab
zstyle ':completion:*' group-name ''
zstyle ':fzf-tab:*' fzf-flags --tiebreak=index

# fzf-tab sorts candidates with the system `sort` (locale collation, same as `ls`)
# only when list-colors is non-empty; otherwise it falls back to zsh's byte-order sort.
# LS_COLORS is unset on macOS, so fall back to a no-op color ("no=0" resets only)
# to keep the colors visually unchanged while enabling the locale-aware sort.
zstyle ':completion:*' list-colors ${(s.:.)${LS_COLORS:-no=0}}

# Keep the tool-provided order (e.g. recently used branches) for git branch completion
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:git-switch:*' sort false

# Load human-specific interactive configs (aliases, prompts, fzf, git completion)
for file (~/.zsh/human/**/*.sh(N)) do
    source $file
done
