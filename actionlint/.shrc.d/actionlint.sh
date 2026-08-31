# actionlint has no global config discovery; fall back to a local
# ~/.config/actionlint/actionlint.yaml (machine-local, not in dotfiles —
# it may hold employer-private runner labels) when the repo doesn't ship
# its own config (-config-file would otherwise silently override it).
actionlint() {
  if [ -f .github/actionlint.yaml ] || [ -f .github/actionlint.yml ] ||
     [ ! -f ~/.config/actionlint/actionlint.yaml ]; then
    command actionlint "$@"
  else
    command actionlint -config-file ~/.config/actionlint/actionlint.yaml "$@"
  fi
}
