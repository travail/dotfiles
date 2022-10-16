PWD=$(shell pwd)

CARTON_PATH=$(shell which carton 2>/dev/null)
COMPOSER_PATH=$(shell which composer 2>/dev/null)

all: check mkdir_bin install_perl_lib install_php_lib ln_emacs ln_git ln_mysql ln_perltidyrc ln_tmux ln_zshrc ln_gemrc ln_perl ln_php

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

mkdir_bin:
	mkdir -p ~/bin

ln_emacs:
	ln -s $(PWD)/emacs.d ~/.emacs.d
	mkdir -p $(PWD)/emacs.d/site-lisp

ln_git: gitconfig gitignore
	ln -s $(PWD)/gitconfig ~/.gitconfig && ln -s $(PWD)/gitignore ~/.gitignore

ln_mysql: my.cnf
	ln -s $(PWD)/my.cnf ~/.my.cnf

ln_perltidyrc: perltidyrc
	ln -s $(PWD)/perltidyrc ~/.perltidyrc

ln_tmux: tmux.conf
	ln -s $(PWD)/tmux.conf ~/.tmux.conf

ln_zshrc: zshrc
	ln -s $(PWD)/zshrc ~/.zshrc && ln -s $(PWD)/zsh ~/.zsh
	mkdir -p $(HOME)/.cache/shell

ln_gemrc: gemrc
	ln -s $(PWD)/gemrc ~/.gemrc

ln_perl:
	ln -s $(PWD)/perl ~/.perl

ln_php:
	ln -s $(PWD)/php ~/.php

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
	rm -f ~/.zshrc
	rm -rf ~/.zsh
	rm -f ~/.gemrc
	rm -f ~/.perl
	rm -f ~/.php

cleanall: clean clean_emacs clean_perl_lib clean_php_lib
