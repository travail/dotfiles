export PLENV_ROOT=/usr/local/plenv
export PATH="$PLENV_ROOT/bin:$PLENV_ROOT/shims:$PATH"
EXECUTABLE_PATH="$PLENV_ROOT/bin/plenv"
if [ -x "$EXECUTABLE_PATH" ]; then
    eval "$(plenv init -)"
else
    echo "Executable $EXECUTABLE_PATH not found"
fi
