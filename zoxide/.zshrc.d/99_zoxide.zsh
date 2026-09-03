# Coding agents drive the shell with cd; zoxide's fuzzy matching confuses them.
# OpenCode sources .zshrc from a non-interactive `zsh -l -c`; Claude Code and
# Codex snapshot an interactive shell but mark it with an env var.
[[ -o interactive ]] || return
[[ -n "$CLAUDECODE" || -n "$CODEX_THREAD_ID" ]] && return
export _ZO_DOCTOR=0
eval "$(zoxide init zsh --cmd cd)"
