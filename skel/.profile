#!/bin/bash
# This file is not read by bash, if ~/.bash_profile or ~/.bash_login
# exists.

# source my profile.d
if [ -d $HOME/.profile.d ]; then
    for file in $HOME/.profile.d/*; do
        if [ -f $file ]; then
            . $file
        fi
    done
    unset file
fi

# when running interactive bash, source .bashrc
if [ "$BASH" ] && [ "$BASH" != "/bin/sh" ] && [ -n "$PS1" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# Source a local profile
if [ -f "$HOME/.profile.local" ]; then
    . $HOME/.profile.local
fi
