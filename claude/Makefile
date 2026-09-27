.PHONY: all setup link clean

all: setup

setup: link statusline/node_modules/.package-lock.json

link:
	mkdir -p $(HOME)/.config/ccstatusline
	ln -sfn $(CURDIR)/statusline/settings.json $(HOME)/.config/ccstatusline/settings.json

statusline/node_modules/.package-lock.json: statusline/package.json statusline/package-lock.json
	npm --prefix statusline ci

clean:
	rm -f $(HOME)/.config/ccstatusline/settings.json

