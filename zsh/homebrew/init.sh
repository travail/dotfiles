PAHT=$PAHT:/opt/homebrew/bin
EXECUTABLE_PATH="/opt/homebrew/bin/brew"
if [ -x "$EXECUTABLE_PATH" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "Executable $EXECUTABLE_PATH not found"
fi
