# dotfiles

Personal dotfiles for macOS.

## Requirements

- [Homebrew](https://brew.sh)

## Installation

### 1. Install Homebrew packages

```sh
brew bundle install --file=Brewfile
```

This installs all required tools including aqua and Docker Desktop.

### 2. Install CLI tools via aqua

```sh
aqua install
```

### 3. Symlink dotfiles

```sh
make
```

## Zsh Setup

### Zim

[Zim](https://github.com/zimfw/zimfw) is used as the zsh framework. It manages the following modules:

- `zsh-users/zsh-completions` — additional completion definitions
- `zsh-users/zsh-syntax-highlighting` — command syntax highlighting
- `zsh-users/zsh-autosuggestions` — fish-like history suggestions

After symlinking `zimrc` to `~/.zimrc`, install Zim:

```sh
ln -sf $(pwd)/zimrc ~/.zimrc
curl -fsSL --create-dirs -o ~/.zim/zimfw.zsh \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
source ~/.zshrc
```

### fzf

[fzf](https://github.com/junegunn/fzf) is managed by aqua. The zsh integration is set up automatically via `fzf --zsh` with caching on first shell startup.

#### Key bindings

| Key | Description |
| --- | ----------- |
| `Ctrl+R` | Search command history |
| `Ctrl+X f` | Search files (multi-select with `Tab`) |
| `Alt+C` | Change directory with fuzzy search |
| `Tab` | Context-aware fuzzy completion |
| `Ctrl+X d` | Change directory using cdr |
| `Ctrl+X b` | Switch git branch |
| `Ctrl+X l` | Search git log and insert commit hash |
| `Ctrl+X p` | Select process ID |

## CLI Tools (aqua)

The following tools are managed by aqua (see `aqua.yaml`):

| Tool | Description |
| ---- | ----------- |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder |
| [jq](https://github.com/jqlang/jq) | JSON processor |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast grep |
| [peco](https://github.com/peco/peco) | Interactive filter |
| [uv](https://github.com/astral-sh/uv) | Python package manager |
| [delta](https://github.com/dandavison/delta) | Git diff pager |
| [lazygit](https://github.com/jesseduffield/lazygit) | TUI git client (`lg`) |
| [Node.js](https://nodejs.org) | JavaScript runtime |
| [Go](https://go.dev) | Go toolchain |
| [1Password CLI](https://developer.1password.com/docs/cli/) | Secret management |

## GPG Signed Commits

Git is configured to sign all commits with GPG (`commit.gpgsign = true`).

### Setup

1. Install GnuPG and pinentry-mac (included in Brewfile):

```sh
brew bundle install --file=Brewfile
```

1. Configure gpg-agent to use pinentry-mac:

```sh
mkdir -p ~/.gnupg
echo "pinentry-program /opt/homebrew/bin/pinentry-mac" > ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```

1. Generate a new GPG key:

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

1. Find the key ID:

```sh
gpg --list-secret-keys --keyid-format=long
```

1. Set the key in git config:

```sh
git config --global user.signingkey <KEY_ID>
```

1. To register with GitHub, export the public key and add it to Settings → SSH and GPG keys → New GPG key:

```sh
gpg --armor --export <KEY_ID>
```

### Restoring keys from 1Password

```sh
# Sign in to 1Password
eval $(op signin)

# Import secret key
op item get GPG-Secret-Key-Git-Signing --fields private_key | gpg --import

# Import public key
op item get GPG-Public-Key-Git-Signing --fields public_key | gpg --import
```
