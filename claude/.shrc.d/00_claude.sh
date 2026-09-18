alias cc='claude'
alias ccr='claude -r'
alias ccp='claude-profile'

# Profiles are ~/.claude/profiles/<name>.json, not in git; settings.json is a
# symlink to the active one.
claude-profile() {
  local name="$1"
  if [ -z "$name" ]; then
    echo "Active: $(readlink ~/.claude/settings.json 2>/dev/null || echo none)"
    echo "Available: $(ls ~/.claude/profiles/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json$//' | tr '\n' ' ')"
  elif [ -f "$HOME/.claude/profiles/$name.json" ]; then
    ln -sf "profiles/$name.json" ~/.claude/settings.json && echo "Switched to $name"
  else
    echo "claude-profile: no ~/.claude/profiles/$name.json" >&2
    return 1
  fi
}
