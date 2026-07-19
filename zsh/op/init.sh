# A stale `alias gh=...`/`alias aws=...` from an older shell plugin setup makes
# zsh error out when redefining them as functions below. zsh resolves aliases
# while parsing, so this must run as its own statement before the `if` block
# below is parsed, not just before it runs.
unalias gh aws 2>/dev/null

if [[ -f ~/.config/op/service-account-token ]]; then
    export OP_SERVICE_ACCOUNT_TOKEN="$(<~/.config/op/service-account-token)"
    gh() { op run --env-file="$HOME/.zsh/op/gh.env" -- gh "$@" }
    aws() { op run --env-file="$HOME/.zsh/op/aws.env" -- aws "$@" }
elif command -v op &>/dev/null; then
    echo "1Password service account token not found. Save it to:"
    echo "  ~/.config/op/service-account-token (chmod 600)"
fi
