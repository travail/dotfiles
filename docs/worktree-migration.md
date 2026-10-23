# Git Worktree Migration Investigation (Issue #69)

## Overview

Currently, development on `dotfiles` is performed within a single clone located directly at `~/git/dotfiles`.
To facilitate parallel development on multiple issues and allow safe, isolated testing of dotfile modifications without affecting the daily working environment, this document investigates migrating `dotfiles` to the sibling git worktree layout specified in the `git-worktree` skill.

Similar migrations have been successfully executed and proven stable in related projects (`anv`, `etiage`, and `manglane`).
This document details the feasibility, technical trade-offs, and implementation plan for adopting the sibling worktree layout in `dotfiles`.

---

## Directory Structure

### Target Layout (Sibling Layout)

```text
~/git/dotfiles/
├── .claude/               # [Shared] Shared Claude Code configuration and plans
│   ├── settings.json
│   ├── settings.local.json
│   └── plans/
├── master/                # [Main Clone] Holds .git and checked out to 'master'
│   ├── .git/
│   ├── .github/
│   ├── .gitignore
│   ├── bin/
│   ├── Makefile
│   └── ...
└── issue-N-<slug>/        # [Linked Worktrees] Dedicated worktree per issue/branch
    └── ...
```

---

## Investigation Findings

### 1. Symlink Targets and Counts

* **Current Status**: There are currently 21 symlinks in the user's home directory and `~/.config` that point directly to files or directories under `/Users/travail/git/dotfiles/`:
  - Top-level: `~/bin`, `~/.emacs.d`, `~/.gemrc`, `~/.my.cnf`, `~/.perl`, `~/.perltidyrc`, `~/.php`, `~/.zimrc`, `~/.zsh`, `~/.zshenv`, `~/.zshrc`
  - `.config` and agent paths: `git/config`, `git/hooks`, `git/ignore`, `tmux/tmux.conf`, `aquaproj-aqua/aqua.yaml`, `mise/config.toml`, `herdr/config.toml`, `ccstatusline/settings.json`, `agystatusline/settings.toml`, and `.gemini/antigravity-cli/bin/agystatusline`.
  *(Note: Issue #69 originally noted 17 links; 4 additional links were added for mise, herdr, and statuslines since the issue was opened).*
* **After Migration**: All active daily symlinks will point to `/Users/travail/git/dotfiles/master/...`.
* **Resolution**: The `Makefile` relies on `$(PWD)` / `$(CURDIR)` to construct link targets. Running `make` inside `~/git/dotfiles/master` automatically updates all 21 symlinks to reference the `master` clone in a single invocation.

### 2. Migration Procedure & Safety

* **Risk**: During the transition, moving files from `~/git/dotfiles/` to `~/git/dotfiles/master/` before running `make` introduces a brief window where existing symlinks become dangling pointers. If another terminal pane or daemon attempts to resolve `~/bin` or shell configurations during this window, commands could fail.
* **Mitigation**:
  1. **Execution Timing**: Perform the migration when other panes/agents in Herdr are idle.
  2. **Atomic Transition Command**: Execute directory creation, file moving, and `make` link regeneration in a single sequential execution block so the dangling window is minimized to milliseconds.
  3. **Atomic Symlink Updates**: `ln -sfn` overwrites symlinks atomically, guaranteeing that no partial link state occurs during the `make` run.
  4. **Active Shell Safety**: Running zsh sessions retain built-in commands, functions, and cached paths in memory, preventing active sessions from crashing.

### 3. Files to Move

Everything under `~/git/dotfiles` except `.claude/` must be moved into `master/`.
To ensure dotfiles are not omitted by shell glob expansion, dotglob must be enabled or files explicitly enumerated.
The full list of 30 items consists of:
* **Standard files & directories (25)**: `antigravity`, `aqua-checksums.json`, `aqua.yaml`, `bin`, `Brewfile`, `Brewfile.darwin`, `claude`, `emacs.d`, `gemrc`, `gitconfig`, `gitignore`, `git-hooks`, `herdr-config.toml`, `Makefile`, `mise-config.toml`, `my.cnf`, `perl`, `perltidyrc`, `php`, `README.md`, `tmux.conf`, `zimrc`, `zsh`, `zshenv`, `zshrc`.
* **Hidden files & directories (5)**: `.DS_Store`, `.git`, `.github`, `.gitignore`, `.make`.
* **Retained at container root (1)**: `.claude/`.

### 4. Makefile Behavior and Worktree Isolation

* **Worktree Testing**: When `make` is executed inside a linked worktree (e.g. `~/git/dotfiles/issue-69-investigate-worktree-migration/`), `$(CURDIR)` resolves to that worktree's path. Symlinks are redirected to the worktree, allowing immediate real-world testing of dotfile modifications.
* **Restoration**: Running `make -C ~/git/dotfiles/master` immediately restores all symlinks back to the stable `master` branch.
* **Makefile Improvement**: Replacing `PWD=$(shell pwd)` with `PWD := $(CURDIR)` eliminates unnecessary subshell spawns and provides standard, robust path resolution across make targets.

### 5. Shared `.claude` Directory & `plansDirectory` Resolution

* **Configuration Sharing**: Following the `git-worktree` skill conventions, `.claude/` lives exclusively at the container root (`~/git/dotfiles/.claude`).
* **Settings Discovery**: Claude Code searches upward from the current working directory to find `.claude/settings.json`. Linked worktrees do not contain `.claude/`, so they transparently inherit container-level settings.
* **Gitignore Guard**: `.gitignore` already ignores `.claude/`, `.claude/settings.json`, and `.claude/settings.local.json`, preventing worktrees from inadvertently committing or creating local `.claude` directories.
* **Plan Storage**: Relative path `"plansDirectory": "./.claude/plans"` resolves relative to the discovered `.claude` directory, consolidating all plan files into `~/git/dotfiles/.claude/plans/` across all worktrees (matching empirical observations in `etiage` and `manglane`).

### 6. New Machine Bootstrap Flow

The bootstrap instructions in `README.md` will be updated to clone directly into the sibling layout:

```sh
mkdir -p ~/git/dotfiles
git clone https://github.com/travail/dotfiles.git ~/git/dotfiles/master
cd ~/git/dotfiles/master
make
```

---

## Conclusion & Recommendation

Migrating `dotfiles` to the sibling worktree layout is **fully feasible, safe, and recommended**.
It aligns `dotfiles` with all other active projects (`anv`, `etiage`, `manglane`), ensures standard compatibility with multi-agent workflows, and provides a safe mechanism for testing dotfile changes in isolated worktrees before merging.

---

## Migration Execution Runbook

When executing the actual migration, run the following commands sequentially:

```bash
# 1. Create the master clone directory
mkdir -p ~/git/dotfiles/master

# 2. Move all repository contents into master (excluding .claude)
shopt -s dotglob
for item in ~/git/dotfiles/*; do
  base=$(basename "$item")
  if [ "$base" != "master" ] && [ "$base" != ".claude" ]; then
    mv "$item" ~/git/dotfiles/master/
  fi
done
shopt -u dotglob

# 3. Immediately regenerate symlinks to point to master
make -C ~/git/dotfiles/master
```
