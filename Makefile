PWD=$(shell pwd)
all: emacs git mysql perltidyrc tmux zshrc gemrc

emacs:
	ln -s $(PWD)/.emacs.d ~/.emacs.d
	mkdir -p $(PWD)/.emacs.d/site-lisp

git:
	ln -s $(PWD)/.gitconfig ~/.gitconfig
	ln -s $(PWD)/.gitignore ~/.gitignore

mysql:
	ln -s $(PWD)/.my.cnf ~/.my.cnf

perltidyrc:
	ln -s $(PWD)/.perltidyrc ~/.perltidyrc

tmux:
	ln -s $(PWD)/.tmux.conf ~/.tmux.conf

zshrc:
	ln -s $(PWD)/.zshrc ~/.zshrc
	ln -s $(PWD)/.zsh ~/.zsh

gemrc:
	ln -s $(PWD)/.gemrc ~/.gemrc

clean_emacs:
	rm -rf $(PWD)/.emacs.d/elpa
	rm -rf $(PWD)/.emacs.d/site-lisp

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

cleanall: clean clean_emacs
