# Coding agents drive the shell with cd; zoxide's fuzzy matching confuses them.
# OpenCode sources .bashrc from a non-interactive `bash -l -c`; Claude Code and
# Codex snapshot an interactive shell but mark it with an env var.
[[ $- == *i* ]] || return
[[ -n "$CLAUDECODE" || -n "$CODEX_THREAD_ID" ]] && return
export _ZO_DOCTOR=0
eval "$(zoxide init bash --cmd cd)"
