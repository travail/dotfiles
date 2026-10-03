agent="$HOME/.ssh-agent-`hostname`"

if [ -S "$agent" ]; then
    export SSH_AUTH_SOCK=$agent
fi

ssh-add -l &>/dev/null
agent_status=$?

if [ $agent_status -eq 2 ]; then
    eval "$(ssh-agent -s)" > /dev/null
    ln -snf "$SSH_AUTH_SOCK" "$agent"
    export SSH_AUTH_SOCK=$agent
    agent_status=1
elif [ ! -L "$agent" ] && [ -S "$SSH_AUTH_SOCK" ]; then
    ln -snf "$SSH_AUTH_SOCK" "$agent"
    export SSH_AUTH_SOCK=$agent
fi

if [ $agent_status -eq 1 ]; then
    if [ "$(uname)" = "Darwin" ]; then
        ssh-add --apple-use-keychain
    else
        ssh-add
    fi
fi
