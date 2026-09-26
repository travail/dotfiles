.PHONY: all setup link clean

all: setup

setup: link statusline/node_modules/.package-lock.json

link:
	@true

statusline/node_modules/.package-lock.json: statusline/package.json statusline/package-lock.json
	npm --prefix statusline ci

clean:
	@true
