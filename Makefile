PWD=$(shell pwd)

CARTON_PATH=$(shell which carton 2>/dev/null)
COMPOSER_PATH=$(shell which composer 2>/dev/null)

all: check ln_bin brew_bundle install_perl_lib install_php_lib ln_emacs ln_git ln_mysql ln_perltidyrc ln_tmux ln_zshrc ln_gemrc ln_perl ln_php ln_aqua

check:
ifneq ($(CARTON_PATH),)
	@printf "\033[0;32mFound command %s\033[0m\n" $(CARTON_PATH)
else
	@printf "\033[0;31mCommand not found: carton in %s\033[0m\n" $(PATH) && exit 1
endif

ifneq ($(COMPOSER_PATH),)
	@printf "\033[0;32mFound command %s\033[0m\n" $(COMPOSER_PATH)
else
	@printf "\033[0;31mCommand not found: composer in %s\033[0m\n" $(PATH) && exit 1
endif

install_perl_lib: perl/cpanfile
	cd $(PWD)/perl && carton install

install_php_lib: php/composer.lock
	cd $(PWD)/php && composer install

brew_bundle: Brewfile
	brew bundle install --file=$(PWD)/Brewfile

bin: ln_bin

ln_bin:
	ln -sfn $(PWD)/bin ~/bin

ln_emacs:
	ln -sfn $(PWD)/emacs.d ~/.emacs.d
	mkdir -p $(PWD)/emacs.d/site-lisp

ln_git: gitconfig gitignore
	ln -sfn $(PWD)/gitconfig ~/.gitconfig && ln -sfn $(PWD)/gitignore ~/.gitignore

ln_mysql: my.cnf
	ln -sfn $(PWD)/my.cnf ~/.my.cnf

ln_perltidyrc: perltidyrc
	ln -sfn $(PWD)/perltidyrc ~/.perltidyrc

ln_tmux: tmux.conf
	ln -sfn $(PWD)/tmux.conf ~/.tmux.conf

ln_zshrc: zshrc
	ln -sfn $(PWD)/zshrc ~/.zshrc && ln -sfn $(PWD)/zsh ~/.zsh
	mkdir -p $(HOME)/.cache/shell

ln_gemrc: gemrc
	ln -sfn $(PWD)/gemrc ~/.gemrc

ln_perl:
	ln -sfn $(PWD)/perl ~/.perl

ln_php:
	ln -sfn $(PWD)/php ~/.php

ln_zim: zimrc
	ln -sfn $(PWD)/zimrc ~/.zimrc

zim: ln_zim
	curl -fsSL --create-dirs -o ~/.zim/zimfw.zsh \
		https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
	ZIM_HOME=~/.zim zsh ~/.zim/zimfw.zsh install

ln_aqua: aqua.yaml
	mkdir -p $(HOME)/.config/aquaproj-aqua
	ln -sfn $(PWD)/aqua.yaml $(HOME)/.config/aquaproj-aqua/aqua.yaml

clean_aqua:
	rm -f ~/.config/aquaproj-aqua/aqua.yaml
	rm -f $(PWD)/aqua-checksums.json

clean_emacs:
	rm -rf $(PWD)/emacs.d/elpa
	rm -rf $(PWD)/emacs.d/site-lisp

clean_perl_lib:
	rm -rf $(PWD)/perl/local

clean_php_lib:
	rm -rf $(PWD)/php/vendor

clean:
	rm -f ~/.emacs.d
	rm -f ~/.git
	rm -f ~/.gitconfig
	rm -f ~/.gitignore
	rm -f ~/.my.cnf
	rm -f ~/.perltidyrc
	rm -f ~/.tmux.conf
	rm -f ~/bin
	rm -f ~/.zshrc
	rm -rf ~/.zsh
	rm -f ~/.gemrc
	rm -f ~/.perl
	rm -f ~/.php
	rm -f ~/.config/aquaproj-aqua/aqua.yaml
	rm -f $(PWD)/aqua-checksums.json

cleanall: clean clean_emacs clean_perl_lib clean_php_lib
