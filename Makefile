PWD=$(shell pwd)

all: mkdir_bin ln_emacs ln_git ln_mysql ln_perltidyrc ln_tmux ln_zshrc ln_gemrc ln_perl install_perl_lib

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

ln_gemrc: gemrc
	ln -s $(PWD)/gemrc ~/.gemrc

ln_perl:
	ln -s $(PWD)/perl ~/.perl

install_perl_lib: perl/cpanfile perl/cpanfile.snapshot
	cd $(PWD)/perl && carton install --cached --deployment

clean_emacs:
	rm -rf $(PWD)/emacs.d/elpa
	rm -rf $(PWD)/emacs.d/site-lisp

clean_perl_lib:
	rm -rf $(PWD)/perl/local

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

cleanall: clean clean_emacs clean_perl_lib
