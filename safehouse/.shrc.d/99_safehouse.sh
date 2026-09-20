# Coding agents run sandboxed by default; <agent>-unsafe is the bare binary.
# Loads after the agents' own 00_*.sh so it overrides cc, co and oc.
# The sandbox is the permission boundary, so claude and codex skip their own
# prompts. opencode has no such flag; its permissions live in its config.
if command -v safehouse >/dev/null 2>&1; then
  alias claude-unsafe='command claude'
  alias claude='claude-safe --dangerously-skip-permissions'
  alias cc='claude-safe --dangerously-skip-permissions'

  alias codex-unsafe='command codex'
  alias codex='codex-safe --dangerously-bypass-approvals-and-sandbox'
  alias co='codex-safe --dangerously-bypass-approvals-and-sandbox'

  alias opencode-unsafe='command opencode'
  alias opencode='opencode-safe'
  alias oc='opencode-safe --port 0'
fi
