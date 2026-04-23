_tv_channels() {
  local channels=(${(f)"$(tv list-channels 2>/dev/null)"})
  compadd -a channels
}

eval "$(tv init zsh | sed "s/'::channel -- Which channel shall we watch?:_default'/'::channel -- Which channel shall we watch?:_tv_channels'/")"
