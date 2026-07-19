if [[ -f ~/.config/op/service-account-token ]]; then
    export OP_SERVICE_ACCOUNT_TOKEN="$(<~/.config/op/service-account-token)"
    gh() { op run --env-file="$HOME/.zsh/op/gh.env" -- gh "$@" }
    aws() { op run --env-file="$HOME/.zsh/op/aws.env" -- aws "$@" }
elif command -v op &>/dev/null; then
    echo "1Password service account token not found. Save it to:"
    echo "  ~/.config/op/service-account-token (chmod 600)"
fi
