#!/bin/bash
set -euo pipefail

# Codespaces install script

backup_if_present() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$target.bak"
  fi
}

# Minimal apt dependencies — system tools only, runtimes handled by mise
sudo apt-get -q -y update
sudo apt-get install -q -y --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  git \
  make \
  ncurses-term \
  stow \
  unzip \
  xz-utils

# mise: install and activate
curl -fsSL https://mise.run | sh
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# Trust and install tools from .mise.toml
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
"$HOME/.local/bin/mise" trust "$DOTFILES_DIR/.mise.toml"
# Pass GITHUB_TOKEN if available so mise uses authenticated API requests
GITHUB_TOKEN="${GITHUB_TOKEN:-}" \
  MISE_CONFIG_FILE="$DOTFILES_DIR/.mise.toml" \
  "$HOME/.local/bin/mise" install --yes


# WezTerm AppImage (x86_64 only — for native wezterm ssh multiplexing)
mkdir -p "$HOME/bin"
if [ "$(uname -m)" = "x86_64" ]; then
  curl -fsSL "https://github.com/wez/wezterm/releases/download/20240203-110809-5046fc22/WezTerm-20240203-110809-5046fc22-Ubuntu20.04.AppImage" \
    -o "$HOME/bin/wezterm"
  chmod +x "$HOME/bin/wezterm"
else
  echo "warning: WezTerm AppImage only available for x86_64, skipping" >&2
fi

# npm auth config (for private registry tools)
if [ -e "$HOME/.npmrc" ]; then
  echo "warning: $HOME/.npmrc already exists, leaving it unchanged" >&2
else
  cat >"$HOME/.npmrc" <<'EOF'
//registry.npmjs.org/:_authToken=${NODE_AUTH_TOKEN}
registry=https://registry.npmjs.org/
always-auth=true
EOF
fi

# Backup existing shell config files before stowing
backup_if_present "$HOME/.profile"
backup_if_present "$HOME/.bashrc"
backup_if_present "$HOME/.zprofile"
backup_if_present "$HOME/.zshrc"
backup_if_present "$HOME/.gitconfig"
backup_if_present "$HOME/.gitignore_global"

"$DOTFILES_DIR/stow/bin/dotfiles" apply

# pi agent: install sandbox extension dependencies
if [ -d "$HOME/.pi/agent/extensions/sandbox" ]; then
  (cd "$HOME/.pi/agent/extensions/sandbox" && mise exec node -- npm install)
fi
