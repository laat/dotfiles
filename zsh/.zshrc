autoload -U +X bashcompinit && bashcompinit
autoload -U +X compinit
# Only regenerate completion cache once per day
if [[ -n $ZDOTDIR/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

if [[ -d ~/.zshrc.d ]]; then
    for file in ~/.zshrc.d/*.zsh; do
        [[ -f "$file" ]] && . "$file"
    done
    unset file
fi

[[ -f ~/.shrc ]] && . ~/.shrc
[[ -f ~/.zshrc.local ]] && . ~/.zshrc.local

# pnpm
export PNPM_HOME="/Users/sigurd.fosseng/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
