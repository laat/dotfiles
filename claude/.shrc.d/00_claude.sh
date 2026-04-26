alias cc='claude'
alias ccr='claude -r'

claude-profile() {
  case "$1" in
    work) cp ~/.claude/profiles/work.json ~/.claude/settings.json && echo "Switched to work (LiteLLM)" ;;
    max)  cp ~/.claude/profiles/max.json ~/.claude/settings.json && echo "Switched to max (personal)" ;;
    *)    echo "Usage: claude-profile [work|max]" ;;
  esac
}
