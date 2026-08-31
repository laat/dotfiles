alias cc='claude'
alias ccr='claude -r'
alias ccp='claude-profile'

claude-profile() {
  case "$1" in
    work) ln -sf profiles/work.json ~/.claude/settings.json && echo "Switched to work (LiteLLM)" ;;
    max)  ln -sf profiles/max.json ~/.claude/settings.json && echo "Switched to max (personal)" ;;
    *)    echo "Usage: claude-profile [work|max]" ;;
  esac
}
