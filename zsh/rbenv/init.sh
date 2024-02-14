COMMAND=rbenv
export RBENV_ROOT=/usr/local/rbenv
export PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"
if type $COMMAND > /dev/null 2>&1; then
    eval "$($COMMAND init -)"
 else
    echo "$COMMAND not found"
fi
