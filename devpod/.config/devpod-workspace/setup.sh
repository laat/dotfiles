#!/bin/bash
set -e

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

echo "✓ dev workspace ready"
