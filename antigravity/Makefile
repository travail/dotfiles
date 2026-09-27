.PHONY: all setup link clean

SETTINGS_JSON := $(HOME)/.gemini/antigravity-cli/settings.json

all: setup

setup: link
	go install github.com/yuys13/agystatusline@latest
	@if [ -f "$(SETTINGS_JSON)" ]; then \
		tmp=$$(mktemp "$${SETTINGS_JSON}.tmp.XXXXXX") && \
		jq '.statusLine = {"type": "command", "command": "agystatusline", "enabled": true}' "$(SETTINGS_JSON)" > "$$tmp" && \
		mv "$$tmp" "$(SETTINGS_JSON)"; \
	fi

link:
	mkdir -p $(HOME)/.config/agystatusline
	ln -sfn $(CURDIR)/settings.toml $(HOME)/.config/agystatusline/settings.toml

clean:
	rm -f $(HOME)/.config/agystatusline/settings.toml
