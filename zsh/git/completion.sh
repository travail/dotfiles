# Add descriptions for custom git aliases in tab completion
zstyle ':completion:*:*:git:*' user-commands \
  'cl:checkout local branch with fzf' \
  'checkout-local:checkout local branch with fzf' \
  'cr:checkout remote branch with fzf' \
  'checkout-remote:checkout remote branch with fzf' \
  'sync:pull origin master and fetch all'
