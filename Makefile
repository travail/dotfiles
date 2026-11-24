PWD := $(CURDIR)
UNAME := $(shell uname)

MODULES := antigravity

.PHONY: all claude_bootstrap agy_bootstrap brew_bundle bin ln_bin ln_emacs ln_git ln_tmux ln_zshrc ln_gemrc ln_zim zim ln_aqua ln_mise ln_herdr clean_aqua clean_emacs clean cleanall $(MODULES) modules_setup modules_link modules_clean

all: .make/install_packages .make/aqua_install .make/mise_install claude_bootstrap agy_bootstrap ln_bin ln_emacs ln_git ln_tmux ln_zshrc ln_gemrc ln_aqua ln_mise ln_zim ln_herdr modules_setup

antigravity: .make/mise_install
	$(MAKE) -C $@ setup

modules_setup: .make/mise_install
	@for m in $(MODULES); do $(MAKE) -C $$m setup || exit 1; done

modules_link:
	@for m in $(MODULES); do $(MAKE) -C $$m link || exit 1; done

modules_clean:
	@for m in $(MODULES); do $(MAKE) -C $$m clean || exit 1; done

ifeq ($(UNAME), Darwin)
.make/install_packages: Brewfile Brewfile.darwin
else
.make/install_packages: Brewfile
endif
	@mkdir -p .make
ifeq ($(UNAME), Darwin)
	brew bundle install --file=$(PWD)/Brewfile
	brew bundle install --file=$(PWD)/Brewfile.darwin
else
	brew bundle install --file=$(PWD)/Brewfile
endif
	@touch $@

.make/aqua_install: aqua.yaml
	@mkdir -p .make
	aqua install
	@touch $@

.make/mise_install: mise-config.toml ln_mise
	@mkdir -p .make
	mise install
	@touch $@

# Self-updating tools: install only; updates are left to the tool itself.
# These are .PHONY (no stamp): the `command -v` check is the idempotency guard, and
# a failed download must not leave a stamp that blocks the next run.
# The installer is saved to a file first so that a curl failure fails make.
claude_bootstrap:
	@command -v claude >/dev/null 2>&1 || [ -x $(HOME)/.local/bin/claude ] || { \
		tmp=$$(mktemp -d) && \
		curl -fsSL -o $$tmp/install.sh https://claude.ai/install.sh && \
		bash $$tmp/install.sh; \
		rc=$$?; rm -rf $$tmp; exit $$rc; }

# install.sh does not forward --skip-path / --skip-aliases to `agy install`, which
# edits shell profiles that this repository manages. Run it with a throwaway HOME
# so those edits stay in a temporary directory; --dir pins the real install target.
agy_bootstrap:
	@command -v agy >/dev/null 2>&1 || [ -x $(HOME)/.local/bin/agy ] || { \
		tmp=$$(mktemp -d) && \
		curl -fsSL -o $$tmp/install.sh https://antigravity.google/cli/install.sh && \
		HOME=$$tmp bash $$tmp/install.sh --dir $(HOME)/.local/bin; \
		rc=$$?; rm -rf $$tmp; exit $$rc; }

ifeq ($(UNAME), Darwin)
brew_bundle: Brewfile Brewfile.darwin
else
brew_bundle: Brewfile
endif
	brew bundle install --file=$(PWD)/Brewfile
ifeq ($(UNAME), Darwin)
	brew bundle install --file=$(PWD)/Brewfile.darwin
endif

bin: ln_bin

ln_bin:
	@if [ -L $(HOME)/bin ]; then \
		rm -f $(HOME)/bin; \
	fi
	@mkdir -p $(HOME)/bin
	@for f in $(PWD)/bin/*; do \
		[ -e "$$f" ] || continue; \
		ln -sfn "$$f" $(HOME)/bin/$$(basename "$$f"); \
	done

ln_emacs:
	mkdir -p $(HOME)/.config
	rm -f $(HOME)/.emacs.d
	ln -sfn $(PWD)/emacs.d $(HOME)/.config/emacs
	mkdir -p $(PWD)/emacs.d/site-lisp

ln_git: gitconfig gitignore
	mkdir -p $(HOME)/.config/git
	rm -f $(HOME)/.gitconfig $(HOME)/.gitignore $(HOME)/.config/git/ignore
	ln -sfn $(PWD)/gitconfig $(HOME)/.config/git/config
	ln -sfn $(PWD)/gitignore $(HOME)/.config/git/ignore
	ln -sfn $(PWD)/git-hooks $(HOME)/.config/git/hooks

ln_tmux: tmux.conf
	mkdir -p $(HOME)/.config/tmux
	rm -f $(HOME)/.tmux.conf
	ln -sfn $(PWD)/tmux.conf $(HOME)/.config/tmux/tmux.conf

ln_zshrc: zshrc zshenv
	ln -sfn $(PWD)/zshenv ~/.zshenv
	ln -sfn $(PWD)/zshrc ~/.zshrc && ln -sfn $(PWD)/zsh ~/.zsh
	mkdir -p $(HOME)/.cache/shell

ln_gemrc: gemrc
	ln -sfn $(PWD)/gemrc ~/.gemrc

ln_zim: zimrc
	ln -sfn $(PWD)/zimrc ~/.zimrc

zim: ln_zim
	curl -fsSL --create-dirs -o ~/.zim/zimfw.zsh \
		https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
	ZIM_HOME=~/.zim zsh ~/.zim/zimfw.zsh install

ln_aqua: aqua.yaml
	mkdir -p $(HOME)/.config/aquaproj-aqua
	ln -sfn $(PWD)/aqua.yaml $(HOME)/.config/aquaproj-aqua/aqua.yaml

ln_mise: mise-config.toml
	mkdir -p $(HOME)/.config/mise
	ln -sfn $(PWD)/mise-config.toml $(HOME)/.config/mise/config.toml

ln_herdr: herdr-config.toml
	mkdir -p $(HOME)/.config/herdr
	ln -sfn $(PWD)/herdr-config.toml $(HOME)/.config/herdr/config.toml

clean_aqua:
	rm -f ~/.config/aquaproj-aqua/aqua.yaml

clean_emacs:
	rm -rf $(PWD)/emacs.d/elpa
	rm -rf $(PWD)/emacs.d/site-lisp

clean:
	rm -f ~/.emacs.d
	rm -f ~/.git
	rm -f ~/.gitconfig
	rm -f ~/.gitignore
	rm -f ~/.tmux.conf
	@for f in $(PWD)/bin/*; do \
		[ -e "$$f" ] || continue; \
		rm -f $(HOME)/bin/$$(basename "$$f"); \
	done
	rm -f ~/.zshenv
	rm -f ~/.zshrc
	rm -rf ~/.zsh
	rm -f ~/.gemrc
	rm -f ~/.zimrc
	$(MAKE) clean_aqua
	rm -f ~/.config/mise/config.toml
	rm -f ~/.config/herdr/config.toml
	rm -f ~/.config/git/config
	rm -f ~/.config/git/ignore
	rm -f ~/.config/emacs
	rm -rf ~/.config/git/hooks
	rm -f ~/.config/tmux/tmux.conf
	rm -rf $(PWD)/.make
	$(MAKE) modules_clean

cleanall: clean clean_emacs
