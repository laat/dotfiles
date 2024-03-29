autoload -U +X bashcompinit && bashcompinit
autoload -U +X compinit && compinit

if [ -d $HOME/.zshrc.d ]; then
    for file in $HOME/.zshrc.d/*.zsh; do
        [[ -f "$file" ]] && . "$file"
    done
    unset file
fi

[ -f $HOME/.shrc ] && . $HOME/.shrc
[ -f $HOME/.zshrc.local ] && . $HOME/.zshrc.local
