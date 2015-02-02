# rbenv
export RBENV_ROOT=/usr/local/rbenv
export PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"
EXECUTABLE_PATH="$RBENV_ROOT/bin/rbenv"
if [ -x "$EXECUTABLE_PATH" ]; then
    eval "$(rbenv init -)"
else
    echo "Executable $EXECUTABLE_PATH not found"
fi
