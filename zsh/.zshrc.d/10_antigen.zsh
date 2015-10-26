#!/bin/zsh
ANTIGEN_FOLDER=$HOME/.antigen
if [ ! -d "$ANTIGEN_FOLDER" ] ; then
    git clone  https://github.com/zsh-users/antigen.git $ANTIGEN_FOLDER
fi
source $ANTIGEN_FOLDER/antigen.zsh
unset ANTIGEN_FOLDER

antigen use oh-my-zsh
antigen bundle command-not-found

antigen bundle zsh-users/zsh-syntax-highlighting
antigen apply
