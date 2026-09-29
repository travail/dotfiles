.PHONY: all setup link clean

SETTINGS_JSON := $(HOME)/.gemini/antigravity-cli/settings.json

all: setup

setup: link
	go install github.com/yuys13/agystatusline@latest
	@if command -v jq >/dev/null 2>&1; then \
		if [ ! -f "$(SETTINGS_JSON)" ] || ! jq -e '.statusLine.type == "command" and .statusLine.command == "agystatusline" and .statusLine.enabled == true' "$(SETTINGS_JSON)" >/dev/null 2>&1; then \
			echo ""; \
			echo "----------------------------------------------------------------------"; \
			echo "[Action Required] Please configure statusLine in $(SETTINGS_JSON):"; \
			echo ""; \
			echo '"statusLine": {'; \
			echo '  "type": "command",'; \
			echo '  "command": "agystatusline",'; \
			echo '  "enabled": true'; \
			echo '}'; \
			echo "----------------------------------------------------------------------"; \
			echo ""; \
		fi; \
	else \
		echo "[Notice] jq is not installed. Please install jq to verify statusLine in $(SETTINGS_JSON)."; \
	fi

link:
	mkdir -p $(HOME)/.config/agystatusline
	ln -sfn $(CURDIR)/settings.toml $(HOME)/.config/agystatusline/settings.toml
	mkdir -p $(HOME)/.gemini/antigravity-cli/bin
	ln -sfn $(CURDIR)/../bin/agystatusline $(HOME)/.gemini/antigravity-cli/bin/agystatusline

clean:
	rm -f $(HOME)/.config/agystatusline/settings.toml
	rm -f $(HOME)/.gemini/antigravity-cli/bin/agystatusline
