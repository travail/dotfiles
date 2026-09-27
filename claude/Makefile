.PHONY: all setup link clean

SETTINGS_JSON := $(HOME)/.claude/settings.json

all: setup

setup: link statusline/node_modules/.package-lock.json
	@if command -v jq >/dev/null 2>&1; then \
		if [ ! -f "$(SETTINGS_JSON)" ] || ! jq -e '.statusLine.type == "command" and .statusLine.command == "ccstatusline"' "$(SETTINGS_JSON)" >/dev/null 2>&1; then \
			echo ""; \
			echo "----------------------------------------------------------------------"; \
			echo "[Action Required] Please configure statusLine in $(SETTINGS_JSON):"; \
			echo ""; \
			echo '"statusLine": {'; \
			echo '  "type": "command",'; \
			echo '  "command": "ccstatusline",'; \
			echo '  "refreshInterval": 60'; \
			echo '}'; \
			echo "----------------------------------------------------------------------"; \
			echo ""; \
		fi; \
	else \
		echo "[Notice] jq is not installed. Please install jq to verify statusLine in $(SETTINGS_JSON)."; \
	fi

link:
	mkdir -p $(HOME)/.config/ccstatusline
	ln -sfn $(CURDIR)/statusline/settings.json $(HOME)/.config/ccstatusline/settings.json

statusline/node_modules/.package-lock.json: statusline/package.json statusline/package-lock.json
	npm --prefix statusline ci

clean:
	rm -f $(HOME)/.config/ccstatusline/settings.json

