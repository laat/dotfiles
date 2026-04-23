#!/bin/zsh
if command -v uv &>/dev/null; then
  eval "$(uv generate-shell-completion zsh)"
fi
