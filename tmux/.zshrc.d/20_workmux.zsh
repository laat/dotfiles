#! /bin/zsh
# workmux completions (compinit already ran in .zshrc)
if command -v workmux &>/dev/null; then
  eval "$(workmux completions zsh)"
fi
