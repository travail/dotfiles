# dotfiles

Personal dotfiles for macOS.

## Requirements

- [Homebrew](https://brew.sh)
- carton
- composer
- gnupg (`brew install gnupg`)

## Installation

```sh
make
```

This will symlink all dotfiles to your home directory.

## Zsh Setup

### Zim

[Zim](https://github.com/zimfw/zimfw) is used as the zsh framework. It manages the following modules:

- `zsh-users/zsh-completions` — additional completion definitions
- `zsh-users/zsh-autosuggestions` — fish-like history suggestions

After symlinking `zimrc` to `~/.zimrc`, install Zim:

```sh
ln -sf $(pwd)/zimrc ~/.zimrc
curl -fsSL --create-dirs -o ~/.zim/zimfw.zsh \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
source ~/.zshrc
```

### fzf

[fzf](https://github.com/junegunn/fzf) is used for fuzzy searching.

Install via Homebrew and set up zsh integration:

```sh
brew install fzf
$(brew --prefix)/opt/fzf/install
```

When prompted, answer `y` to enable key bindings and fuzzy completion.

## GPG Signed Commits

Git is configured to sign all commits with GPG (`commit.gpgsign = true`).

### Setup

1. Install GnuPG:

```sh
brew install gnupg
```

2. Generate a new GPG key:

```sh
gpg --batch --gen-key <<EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Key-Usage: sign
Name-Real: <your name>
Name-Email: <your email>
Expire-Date: 0
%commit
EOF
```

3. Find the key ID:

```sh
gpg --list-secret-keys --keyid-format=long
```

4. Set the key in git config:

```sh
git config --global user.signingkey <KEY_ID>
```

5. To register with GitHub, export the public key and add it to Settings → SSH and GPG keys → New GPG key:

```sh
gpg --armor --export <KEY_ID>
```

#### Key bindings

| Key | Description |
|-----|-------------|
| `Ctrl+R` | Search command history |
| `Ctrl+X f` | Search files (multi-select with `Tab`) |
| `Alt+C` | Change directory with fuzzy search |
| `Tab` | Context-aware fuzzy completion |
| `Ctrl+X d` | Change directory using cdr |
| `Ctrl+X b` | Switch git branch |
| `Ctrl+X l` | Search git log and insert commit hash |
| `Ctrl+X p` | Select process ID |
