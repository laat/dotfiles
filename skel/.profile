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

# Source a local profile
if [ -f "$HOME/.profile.local" ]; then
    . $HOME/.profile.local
fi
