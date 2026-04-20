#!/bin/bash
set -e

sudo chown -R vscode:vscode \
  ~/.ssh \
  ~/.claude \
  ~/.zsh_history_dir

if [ ! -f ~/.zsh_history_dir/.zsh_history ]; then
  touch ~/.zsh_history_dir/.zsh_history
fi
ln -sf ~/.zsh_history_dir/.zsh_history ~/.zsh_history

# Fix DevPod's broken SSH signing wrapper
if git config --global --get gpg.ssh.program &>/dev/null; then
  git config --global --unset gpg.ssh.program
fi

if ! grep -q "gpg.ssh.program" ~/.zshrc.local 2>/dev/null; then
  echo 'git config --global --unset gpg.ssh.program 2>/dev/null || true' >> ~/.zshrc.local
fi

if git config --global user.signingkey &>/dev/null; then
  git config --global gpg.format ssh
  git config --global commit.gpgsign true
fi

# Claude Code config persistence
if [ ! -f ~/.claude/.claude.json ]; then
  echo "{}" > ~/.claude/.claude.json
fi
if [ ! -f ~/.claude/.mcp.json ]; then
  echo "{}" > ~/.claude/.mcp.json
fi
[ -e ~/.claude.json ] || ln -s ~/.claude/.claude.json ~/.claude.json
[ -e ~/.mcp.json ] || ln -s ~/.claude/.mcp.json ~/.mcp.json

echo "✓ dev workspace ready"
