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

## AI Agent Optimization

The shell environment is configured as AI agent-first with human opt-in:

- **`~/.zshenv` (`zshenv`)**: Evaluates `is_human` (checking for TTY and agent environment variables such as `CLAUDECODE`, `AI_AGENT`, and `ANTIGRAVITY_APP_DATA_DIR`). Non-human / AI agent shells export fail-fast settings (`EDITOR=true`, `PAGER=cat`, `GIT_TERMINAL_PROMPT=0`) to avoid hanging on interactive prompts.
- **`~/.zshrc` (`zshrc`)**: Structured into `zsh/common` (tools, PATH, 1Password wrappers for `gh` and `aws`) before an early return guard (`is_human || return 0`), and `zsh/human` (interactive prompt, completion, Zim, aliases) after the guard. This prevents heavy plugins and interactive confirmation aliases (`cp -i`, `mv -i`) from leaking into agent snapshots and slowing down shell execution.
- **`airm` (`bin/airm`)**: Safe replacement for `rm` mapped via `alias rm=airm` across both human and agent environments. Instead of permanent deletion, files are moved into timestamped session directories under `~/.cache/airm/trash/`. It includes automatic pruning (run synchronously after each successful removal) of session directories older than 30 days and a manual `airm --clean [days]` command.

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
| [fd](https://github.com/sharkdp/fd) | Simple, fast user-friendly alternative to find |
| [yq](https://github.com/mikefarah/yq) | Portable command-line YAML processor |
| [shellcheck](https://github.com/koalaman/shellcheck) | Shell script static analysis tool |
| [shfmt](https://github.com/mvdan/sh) | Shell script formatter |
| [ast-grep](https://github.com/ast-grep/ast-grep) | Fast and polyglot tool for code searching and rewriting |
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

## Modules and Directory Structure

To keep tool-specific configurations modular and cohesive, ecosystem-specific files are organized under top-level module directories (e.g. `claude/`, `antigravity/`). Each module provides a standalone `Makefile` conforming to a common interface:

- `setup`: complete module environment setup (includes `link` and any tool-specific dependency installation; the default target `all` depends on it).
- `link`: create symlinks for module-managed files and scripts.
- `clean`: remove the symlinks the module created, and only when they still point into this repository; real files and installed dependencies (e.g. `node_modules`) are left in place.

The root `Makefile` orchestrates these modules via `modules_setup`, `modules_link`, and `modules_clean`, and provides individual module shortcuts such as `make claude` and `make antigravity`.

## Claude Code Status Line

The Claude Code status line is powered by [`ccstatusline`](https://github.com/sammcj/ccstatusline).
Its configuration is managed under `claude/statusline/settings.json` and symlinked to
`~/.config/ccstatusline/settings.json`. `bin/ccstatusline` is a symlink into
`claude/statusline/node_modules/.bin/ccstatusline`, allowing `ccstatusline` to be
called from `~/bin`.

In addition, `bin/claude-statusline-enterprise-credit` (a symlink to
`claude/statusline/enterprise-credit.js`) formats the 5h/7d or usage-credit
segment for `ccstatusline` via a `custom-command` widget, replacing
ccstatusline's own built-in `session-usage`/`weekly-usage`/reset-timer
widgets. Those built-in widgets call `/api/oauth/usage` directly, which
returns 429 for an Enterprise seat, so this command fetches usage through
the Claude Agent SDK instead (reusing `usage.js` and `plan-usage-line.js`)
and renders whichever shape the account's response reports: `5h: N% (...)
· 7d: N% (...)` (either window may be absent on its own), or `credit: 42%
($4/$10)` for a monthly usage-credit allowance. It exits cleanly with no
output on fetch failure.

(Legacy status line: `bin/claude-statusline`, a symlink to
`claude/statusline/index.js`, is also provided as the previous custom
script implementation. It shares the same `plan-usage-line.js` formatting.)

To install dependencies and link the configuration (or after pulling a change to
`claude/statusline/package.json`):

```sh
make claude
# or: make modules_setup
```

Registering the status line takes one manual step. `~/.claude/settings.json`
holds machine-specific entries such as the permission allowlist, so it is
deliberately kept outside this repository and `make` cannot write to it.
`make claude` will prompt you with the required snippet if `statusLine` is
missing or improperly configured. Add the `statusLine` field by hand:

```json
"statusLine": {
  "type": "command",
  "command": "ccstatusline",
  "refreshInterval": 60
}
```

Without `refreshInterval` the command runs only on Claude Code's own events, and
the time remaining on each rate limit window goes stale while the session sits
idle. The value is in seconds.

## Antigravity CLI Status Line

The Antigravity CLI (agy) status line is powered by `yuys13/agystatusline`, a Go-based status line generator supporting Powerline and Solarized styling. Its configuration is managed under `antigravity/settings.toml` and symlinked to `~/.config/agystatusline/settings.toml`. A wrapper script in `bin/agystatusline` synchronizes current edit modes (`default`, `accept-edits`, `plan`) into the status line pill and inverts quota percentages to display usage consumption matching `ccstatusline`.

To install the binary and link the configuration:

```sh
make antigravity
# or: make modules_setup
```

Registering the status line takes one manual step. `~/.gemini/antigravity-cli/settings.json`
holds machine-specific entries such as the permission allowlist, so it is
deliberately kept outside this repository and `make` cannot write to it.
`make antigravity` will prompt you with the required snippet if `statusLine` is
missing or improperly configured. Add the `statusLine` field by hand:

```json
"statusLine": {
  "type": "command",
  "command": "agystatusline",
  "enabled": true
}
```

