autoload -U +X bashcompinit && bashcompinit
autoload -U +X compinit && compinit

if [[ -d ~/.zshrc.d ]]; then
    for file in ~/.zshrc.d/*.zsh; do
        [[ -f "$file" ]] && . "$file"
    done
    unset file
fi

[[ -f ~/.shrc ]] && . ~/.shrc
[[ -f ~/.zshrc.local ]] && . ~/.zshrc.local
