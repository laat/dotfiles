alias co='codex'
alias cor='codex resume'
alias cop='codex-profile'

# Codex has no config key for a default profile, so remember the active one
# in ~/.codex/.active-profile and inject --profile on every invocation.
# Only runtime commands accept --profile; `login`, `doctor`, `update`, etc. reject it.
codex() {
  local profile
  profile="$(cat "$HOME/.codex/.active-profile" 2>/dev/null)"
  if [ -n "$profile" ] && [ -f "$HOME/.codex/$profile.config.toml" ]; then
    case "${1:--}" in
      -*|exec|e|review|resume|queue|archive|delete|unarchive|fork|mcp|sandbox)
        command codex --profile "$profile" "$@"
        return ;;
    esac
  fi
  command codex "$@"
}

# Profiles are ~/.codex/<name>.config.toml. `max` ships here; others can come
# from any other stow package.
codex-profile() {
  local name="$1"
  if [ -z "$name" ]; then
    echo "Active: $(cat ~/.codex/.active-profile 2>/dev/null || echo none)"
    echo "Available: $(ls ~/.codex/*.config.toml 2>/dev/null | xargs -n1 basename | sed 's/\.config\.toml$//' | tr '\n' ' ')"
  elif [ -f "$HOME/.codex/$name.config.toml" ]; then
    echo "$name" > ~/.codex/.active-profile && echo "Switched to $name"
  else
    echo "codex-profile: no ~/.codex/$name.config.toml" >&2
    return 1
  fi
}
