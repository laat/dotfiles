if [ -d $HOME/.zshrc.d ]; then
    for file in $HOME/.zshrc.d/*; do
        [[ -f "$file" ]] && . "$file"
    done
    unset file
fi

[ -f $HOME/.shrc ] && . $HOME/.shrc
[ -f $HOME/.zshrc.local ] && . $HOME/.zshrc.local
