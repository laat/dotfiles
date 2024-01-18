#!/bin/bash

# Codespaces.

sudo apt-get -q -y update
sudo apt-get install -q -y --no-install-recommends stow
pip install thefuck

function stow() {
  /usr/bin/stow -t "$HOME" --restow --no-folding "$@" \
    2> >(grep -v 'BUG in find_stowed_path? Absolute/relative mismatch' 1>&2)
}

rm -f ~/.profile ~/.bashrc ~/.zprofile ~/.zshrc

stow stow
stow --stow skel
stow --stow git pnpm npm codespaces zsh
