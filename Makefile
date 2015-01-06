PWD=$(shell pwd)
all: emacs git mysql perltidyrc tmux zshrc gemrc

emacs: .emacs.d
	ln -s $(PWD)/.emacs.d ~/.emacs.d

git: .gitignore .gitconfig
	ln -s $(PWD)/.gitconfig ~/.gitconfig
	ln -s $(PWD)/.gitignore ~/.gitignore

mysql: .my.cnf
	ln -s $(PWD)/.my.cnf ~/.my.cnf

perltidyrc: .perltidyrc
	ln -s $(PWD)/.perltidyrc ~/.perltidyrc

tmux: .tmux.conf
	ln -s $(PWD)/.tmux.conf ~/.tmux.conf

zshrc: .zshrc
	ln -s $(PWD)/.zshrc ~/.zshrc
	ln -s $(PWD)/.zsh ~/.zsh

gemrc: .gemrc
	ln -s $(PWD)/.gemrc ~/.gemrc

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
