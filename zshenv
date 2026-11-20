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
    # gh: fail immediately instead of opening interactive selection prompts or a pager
    export GH_PROMPT_DISABLED=1 GH_PAGER=
    # brew: skip auto-update (blocks for tens of seconds), analytics and hints
    export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1
    # ssh: never prompt (host key, passphrase); ssh-agent auth still works
    export GIT_SSH_COMMAND="ssh -o BatchMode=yes"
    # Suppress update notices, version checks and color codes that waste output tokens
    export NPM_CONFIG_UPDATE_NOTIFIER=false PIP_DISABLE_PIP_VERSION_CHECK=1 NO_COLOR=1

    # Strip inherited mise/installs/* entries and prefer shims so non-interactive
    # zsh -c shells resolve per-project tool versions instead of inherited global bins.
    _mise_data_dir="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}"
    path=(${path:#${_mise_data_dir}/installs/*})
    if [[ -d "${_mise_data_dir}/shims" ]]; then
        path=("${_mise_data_dir}/shims" ${path:#${_mise_data_dir}/shims})
    fi
    unset _mise_data_dir

    if [[ -n "${__MISE_DIFF:-}" ]]; then
        unset MISE_SHELL __MISE_DIFF __MISE_SESSION __MISE_ZSH_PRECMD_RUN __MISE_ZSH_CHPWD_RAN __MISE_ZSH_ACTIVATE_PATH __MISE_ZSH_ACTIVATE_ENV __MISE_ORIG_PATH GOBIN GOROOT
    fi
fi
