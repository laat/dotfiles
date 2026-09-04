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

codex-profile() {
  case "$1" in
    work) echo work > ~/.codex/.active-profile && echo "Switched to work (LiteLLM)" ;;
    max)  echo max > ~/.codex/.active-profile && echo "Switched to max (personal)" ;;
    "")   echo "Active: $(cat ~/.codex/.active-profile 2>/dev/null || echo none)" ;;
    *)    echo "Usage: codex-profile [work|max]" ;;
  esac
}
