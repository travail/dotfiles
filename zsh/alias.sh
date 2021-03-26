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
alias ec='emacsclient -nw -a "emacs --daemon"'
