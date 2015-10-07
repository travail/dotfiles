PWD=$(shell pwd)
all: link_emacs link_git link_mysql link_perltidyrc link_tmux link_zshrc link_gemrc link_perl install_perl_lib

link_emacs:
	ln -s $(PWD)/emacs.d ~/.emacs.d
	mkdir -p $(PWD)/emacs.d/site-lisp

link_git: gitconfig gitignore
	ln -s $(PWD)/gitconfig ~/.gitconfig && ln -s $(PWD)/gitignore ~/.gitignore

link_mysql: my.cnf
	ln -s $(PWD)/my.cnf ~/.my.cnf

link_perltidyrc: perltidyrc
	ln -s $(PWD)/perltidyrc ~/.perltidyrc

link_tmux: tmux.conf
	ln -s $(PWD)/tmux.conf ~/.tmux.conf

link_zshrc: zshrc
	ln -s $(PWD)/zshrc ~/.zshrc && ln -s $(PWD)/zsh ~/.zsh

link_gemrc: gemrc
	ln -s $(PWD)/gemrc ~/.gemrc

link_perl:
	ln -s $(PWD)/perl ~/.perl

install_perl_lib: perl/cpanfile
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
