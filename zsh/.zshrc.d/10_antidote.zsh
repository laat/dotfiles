#!/bin/zsh
ANTIDOTE_FOLDER="$HOME/.antidote"
zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins

if [ ! -d "$ANTIDOTE_FOLDER" ] ; then
    git clone https://github.com/mattmc3/antidote.git $ANTIDOTE_FOLDER
fi

if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  (
    source "$ANTIDOTE_FOLDER/antidote.zsh"
    antidote bundle <${zsh_plugins}.txt >${zsh_plugins}.zsh
  )
fi
source ${zsh_plugins}.zsh
unset ANTIDOTE_FOLDER
