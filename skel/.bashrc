#!/bin/bash
# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

# files located here at work.. enforced by employer...
[ -f /etc/shrc ] && . /etc/shrc

# source bashrc.d files
if [ -d $HOME/.bashrc.d ]; then
    for file in $HOME/.bashrc.d/*; do
        [[ -f "$file" ]] && . "$file"
    done
    unset file
fi


[[ -f $HOME/.shrc ]] && . "$HOME/.shrc"
[[ -f $HOME/.bashrc.local ]] && . "$HOME/.bashrc.local"
