#!/bin/bash
# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

if [[ -d ~/.bashrc.d ]]; then
    for file in ~/.bashrc.d/*.bash; do
        [[ -f "$file" ]] && . "$file"
    done
    unset file
fi

[[ -f ~/.shrc ]] && . ~/.shrc
[[ -f ~/.bashrc.local ]] && . ~/.bashrc.local
