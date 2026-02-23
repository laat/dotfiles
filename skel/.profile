#!/bin/sh
# This file is not read by bash, if ~/.bash_profile or ~/.bash_login
# exists.

if [ -d "$HOME/.profile.d" ]; then
    for file in "$HOME/.profile.d"/*; do
        [ -f "$file" ] && . "$file"
    done
    unset file
fi

[ -f "$HOME/.profile.local" ] && . "$HOME/.profile.local"
