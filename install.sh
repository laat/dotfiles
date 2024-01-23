#!/bin/bash

# Codespaces install script

sudo apt-get -q -y update
sudo apt-get install -q -y --no-install-recommends stow
pip install thefuck

function stow() {
  /usr/bin/stow -t "$HOME" --restow --no-folding "$@" \
    2> >(grep -v 'BUG in find_stowed_path? Absolute/relative mismatch' 1>&2)
}

mv ~/.profile{,.bak}
mv ~/.bashrc{,.bak}
mv ~/.zprofile{,.bak}
mv ~/.zshrc{,.bak}

stow stow
stow --stow skel
stow --stow git pnpm npm codespaces zsh
