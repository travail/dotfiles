.PHONY: all setup link clean

all: setup

setup: link
	go install github.com/yuys13/agystatusline@latest

link:
	mkdir -p $(HOME)/.config/agystatusline
	ln -sfn $(CURDIR)/settings.toml $(HOME)/.config/agystatusline/settings.toml

clean:
	rm -f $(HOME)/.config/agystatusline/settings.toml
