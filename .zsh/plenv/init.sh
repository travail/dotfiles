# plenv
export PLENV_ROOT=/usr/local/plenv
export PATH="$PLENV_ROOT/bin:$PLENV_ROOT/shims:$PATH"
if [ `which plenv 2> /dev/null` ]; then
    eval "$(plenv init -)"
fi
