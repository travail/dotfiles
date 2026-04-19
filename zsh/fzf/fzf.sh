export FZF_DEFAULT_OPTS="--exact"
export FZF_CTRL_T_OPTS="--multi"

# cdr でディレクトリ移動
fzf-cdr() {
    local selected_dir
    selected_dir=$(cdr -l | sed 's/^[0-9]* *//' | fzf --prompt="cdr> " --query "$LBUFFER")
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
}
zle -N fzf-cdr

# git ブランチ切り替え
fzf-git-checkout() {
    local branch
    branch=$(git branch -a | fzf --prompt="branch> " | tr -d ' ')
    if [ -n "$branch" ]; then
        if [[ "$branch" =~ "remotes/" ]]; then
            local b
            b=$(echo $branch | awk -F '/' '{print $3}')
            BUFFER="git checkout -b '${b}' ${branch}"
        else
            BUFFER="git checkout '${branch}'"
        fi
        zle accept-line
    fi
}
zle -N fzf-git-checkout

# git log 検索してコミットハッシュを挿入
fzf-git-log() {
    local hash
    hash=$(git log --oneline --decorate | fzf --prompt="git log> " | awk '{print $1}')
    if [ -n "$hash" ]; then
        BUFFER="${BUFFER}${hash}"
        CURSOR=$#BUFFER
        zle redisplay
    fi
}
zle -N fzf-git-log

# プロセス ID を挿入
fzf-pid() {
    local pid
    pid=$(ps aux | fzf --prompt="pid> " --header-lines=1 | awk '{print $2}')
    if [ -n "$pid" ]; then
        BUFFER="${BUFFER}${pid}"
        CURSOR=$#BUFFER
        zle redisplay
    fi
}
zle -N fzf-pid
