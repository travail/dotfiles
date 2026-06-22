if [[ -f ~/.config/op/plugins.sh ]]; then
    source ~/.config/op/plugins.sh
elif command -v op &>/dev/null; then
    echo "1Password shell plugins not initialized. Run the following:"
    echo "  op plugin init aws"
    echo "  op plugin init gh"
fi
