# -*- mode: Shell-script -*-

is_human() {
    [[ -t 0 && -t 1 ]] || return 1
    [[ -z $CLAUDECODE$CODEX_SANDBOX$GEMINI_CLI$CURSOR_AGENT$AI_AGENT$ANTIGRAVITY_APP_DATA_DIR ]]
}

if ! is_human; then
    # Fail fast for non-human / AI agents: avoid blocking on editors, pagers, or prompts
    export EDITOR=true VISUAL=true GIT_EDITOR=true GIT_SEQUENCE_EDITOR=true
    export PAGER=cat GIT_PAGER=cat MANPAGER=cat
    export GIT_TERMINAL_PROMPT=0
fi
