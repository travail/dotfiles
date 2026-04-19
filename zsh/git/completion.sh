# Add descriptions for custom git aliases in tab completion
zstyle ':completion:*:*:git:*' user-commands \
  'lc:checkout local branch with fzf' \
  'rc:checkout remote branch with fzf'
