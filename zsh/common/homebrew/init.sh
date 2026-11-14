[[ "$(uname)" != "Darwin" ]] && return

# Locate brew (Apple Silicon first, then Intel) and let it export its own environment.
for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [[ -x "$brew_bin" ]]; then
    eval "$("$brew_bin" shellenv)"
    break
  fi
done
unset brew_bin
