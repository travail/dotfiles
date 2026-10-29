# -*- mode: Shell-script -*-
# Completion wrapper for `go run` to allow normal file completion for program arguments.
# By default, zsh-completions' _golang treats all arguments after `go run` as Go packages
# (_path_files -/ -g '*.go'), which hides non-.go files (e.g. .txt, .yaml) and only completes directories.
_go_wrapper() {
    if [[ $words[2] == "run" && $CURRENT -gt 3 ]]; then
        _files
    else
        _golang "$@"
    fi
}
compdef _go_wrapper go
