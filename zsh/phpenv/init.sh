export PHPENV_ROOT=/usr/local/phpenv
export PATH="$PHPENV_ROOT/bin:$PHPENV_ROOT/shims:$PATH"
EXECUTABLE_PATH="$PHPENV_ROOT/bin/phpenv"
if [ -x "$EXECUTABLE_PATH" ]; then
    eval "$(phpenv init -)"
else
    echo "Executable $EXECUTABLE_PATH not found"
fi
