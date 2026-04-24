#!/bin/bash
set -euo pipefail

# Codespaces install script

backup_if_present() {
  local target="$1"

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$target.bak"
  fi
}

sudo apt-get -q -y update
sudo apt-get install -q -y --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  fd-find \
  fzf \
  git \
  golang-go \
  make \
  ncurses-term \
  neovim \
  nodejs \
  npm \
  ripgrep \
  stow \
  tmux \
  unzip \
  xz-utils \
  zoxide

case "$(uname -m)" in
  aarch64 | arm64) nvim_arch="arm64" ;;
  x86_64 | amd64) nvim_arch="x86_64" ;;
  *) echo "unsupported architecture for Neovim release: $(uname -m)" >&2; exit 1 ;;
esac

nvim_archive="nvim-linux-${nvim_arch}.tar.gz"
curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/${nvim_archive}" -o "/tmp/${nvim_archive}"
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf "/tmp/${nvim_archive}"
sudo ln -sf "/opt/nvim-linux-${nvim_arch}/bin/nvim" /usr/local/bin/nvim

mkdir -p "$HOME/bin"
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
  ln -sf "$(command -v fdfind)" "$HOME/bin/fd"
fi
GOBIN="$HOME/bin" go install github.com/joshmedeski/sesh/v2@latest
npm install --global --prefix "$HOME" @anthropic-ai/claude-code opencode-ai

if command -v uv &>/dev/null; then
  uv tool install thefuck
else
  echo "warning: uv not found, skipping thefuck install" >&2
fi

backup_if_present "$HOME/.profile"
backup_if_present "$HOME/.bashrc"
backup_if_present "$HOME/.zprofile"
backup_if_present "$HOME/.zshrc"
backup_if_present "$HOME/.gitconfig"
backup_if_present "$HOME/.gitignore_global"

stow -t "$HOME" --restow --no-folding stow
stow -t "$HOME" --restow --no-folding --stow skel
stow -t "$HOME" --restow --no-folding --stow git pnpm npm codespaces zsh direnv nvim tmux zoxide claude opencode devpod pi

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# pi agent: install sandbox extension dependencies
if [ -d "$HOME/.pi/agent/extensions/sandbox" ]; then
  (cd "$HOME/.pi/agent/extensions/sandbox" && npm install)
fi
