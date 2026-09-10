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

## Updates

### Homebrew

```sh
brew update && brew upgrade && brew upgrade --cask
```

- `brew update` — update Homebrew recipes
- `brew upgrade` — upgrade all installed formulae
- `brew upgrade --cask` — upgrade all installed casks
- `brew cleanup` — remove old versions and cached downloads

### aqua

```sh
aqua update
```

Updates all tools defined in `aqua.yaml` to their latest versions.

### uv tools

```sh
uv tool upgrade --all
```

Upgrades all uv-managed tools (e.g. `claude-monitor`).

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
| [uv](https://github.com/astral-sh/uv) | Python package manager |
| [delta](https://github.com/dandavison/delta) | Git diff pager |
| [lazygit](https://github.com/jesseduffield/lazygit) | TUI git client (`lg`) |
| [Node.js](https://nodejs.org) | JavaScript runtime |
| [Go](https://go.dev) | Go toolchain |
| [1Password CLI](https://developer.1password.com/docs/cli/) | Secret management |

## mise (Dev environment manager)

[mise](https://mise.jdx.dev) manages language versions, environment variables, and tasks per project.

### mise Setup

After running `brew bundle install`, activate mise in zsh (already included in `zshrc`):

```sh
eval "$(mise activate zsh)"
```

### Install Ruby

```sh
mise install ruby@latest
mise use -g ruby@latest   # set globally
```

### Per-project version

```sh
cd ~/git/your-project
mise use ruby@3.4         # creates .mise.toml
```

### mise Updates

```sh
mise upgrade ruby
```

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

## Claude Code Status Line

`bin/claude-statusline` prints the Claude Code status line: model and branch on
the first line, context window usage, rate limit windows and this run's cost on
the second. It is a symlink into `claude-statusline/index.js`, a Node script split
across three files: `index.js` (entry point: reads stdin and git, renders the
two lines), `usage.js` (calls the Claude Agent SDK's
`usage_EXPERIMENTAL_MAY_CHANGE_DO_NOT_RELY_ON_THIS_API_YET()` for the plan
rate-limit numbers and decides which window to show), and `format.js` (colors,
percentages, the countdown format). The SDK call takes the same path `/usage`
itself takes, so the numbers are always current instead of depending on some
other action having refreshed a cache first. That method name is Anthropic's
own warning that the API is unstable and may change or disappear without
notice. `make ln_bin` symlinks `bin` to `~/bin`, carrying the inner symlink
along with it, so the script needs no link of its own.

The Node dependencies are not committed, so after cloning (or after pulling a
change to `claude-statusline/package.json`), install them once:

```sh
cd claude-statusline && npm install
```

Registering the status line takes one manual step. `~/.claude/settings.json`
holds machine-specific entries such as the permission allowlist, so it is
deliberately kept outside this repository and `make` cannot write to it. Add
the `statusLine` field by hand:

```json
"statusLine": {
  "type": "command",
  "command": "~/bin/claude-statusline",
  "refreshInterval": 60
}
```

Without `refreshInterval` the command runs only on Claude Code's own events, and
the time remaining on each rate limit window goes stale while the session sits
idle. The value is in seconds.

Each render pays for a Node startup and an SDK round trip -- around a second in
practice -- since the rate-limit numbers come from that live call rather than
the stdin JSON Claude Code hands the command.

See the comment at the top of `claude-statusline/index.js` for what each
number means -- in particular, the trailing `run $N` tracks the running
Claude Code process, not the conversation: confirmed by observation, it
resets to `$0.00` on `/exit` + `/resume`, even when resuming the very same
conversation (same `session_id` and all).
