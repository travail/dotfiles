COMMAND=brew
PATH=$PATH:/opt/homebrew/bin
if type $COMMAND > /dev/null 2>&1; then
    eval "$($COMMAND shellenv)"
else
    echo "$COMMAND not found"
fi
