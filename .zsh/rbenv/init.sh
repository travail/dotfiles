# rbenv
export RBENV_ROOT=/usr/local/rbenv
export PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"
if [ `which rbenv 2> /dev/null` ]; then
    eval "$(rbenv init -)"
fi
