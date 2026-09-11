#! /bin/zsh
# herdr completions (compinit already ran in .zshrc)
if command -v herdr &>/dev/null; then
  eval "$(herdr completion zsh)"
fi
