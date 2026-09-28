.PHONY: all setup link clean

SRC_FILE := $(CURDIR)/AGENTS.md
CLAUDE_TARGETS := $(HOME)/.claude/AGENTS.md $(HOME)/.claude/CLAUDE.md
GEMINI_TARGET := $(HOME)/.gemini/config/AGENTS.md

all: setup

setup: link

link:
	@mkdir -p $(HOME)/.claude
	@if [ ! -f "$(HOME)/.claude/CLAUDE.local.md" ]; then \
		touch "$(HOME)/.claude/CLAUDE.local.md"; \
	fi
	@for target in $(CLAUDE_TARGETS); do \
		if [ -L "$$target" ]; then \
			ln -sfn "$(SRC_FILE)" "$$target"; \
		elif [ -f "$$target" ]; then \
			if cmp -s "$$target" "$(SRC_FILE)"; then \
				ln -sfn "$(SRC_FILE)" "$$target"; \
			else \
				backup="$${target}.bak-$$(date +%Y%m%d%H%M%S)"; \
				mv "$$target" "$$backup"; \
				echo "[Notice] Backed up existing $$target to $$backup"; \
				ln -sfn "$(SRC_FILE)" "$$target"; \
			fi; \
		else \
			ln -sfn "$(SRC_FILE)" "$$target"; \
		fi; \
	done
	@if [ -d "$(HOME)/.gemini" ]; then \
		mkdir -p $(HOME)/.gemini/config; \
		target="$(GEMINI_TARGET)"; \
		if [ -L "$$target" ]; then \
			ln -sfn "$(SRC_FILE)" "$$target"; \
		elif [ -f "$$target" ]; then \
			if cmp -s "$$target" "$(SRC_FILE)"; then \
				ln -sfn "$(SRC_FILE)" "$$target"; \
			else \
				backup="$${target}.bak-$$(date +%Y%m%d%H%M%S)"; \
				mv "$$target" "$$backup"; \
				echo "[Notice] Backed up existing $$target to $$backup"; \
				ln -sfn "$(SRC_FILE)" "$$target"; \
			fi; \
		else \
			ln -sfn "$(SRC_FILE)" "$$target"; \
		fi; \
	else \
		echo "[Notice] $(HOME)/.gemini not found, skipping Antigravity symlink."; \
	fi

clean:
	@for target in $(CLAUDE_TARGETS) $(GEMINI_TARGET); do \
		if [ -L "$$target" ]; then \
			target_dest=$$(readlink "$$target"); \
			case "$$target_dest" in \
				"$(CURDIR)"/*) \
					rm -f "$$target"; \
					;; \
			esac; \
		fi; \
	done
