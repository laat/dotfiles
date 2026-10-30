# Coding agents run sandboxed by default; <agent>-unsafe (ccu, cou, ocu) is the bare binary.
# Loads after the agents' own 00_*.sh so it overrides cc and oc, and the
# _codex_exec that the codex function in 00_codex.sh runs. codex is not an
# alias here: an alias would shadow that function and drop the --profile it
# adds from ~/.codex/.active-profile.
# The sandbox is the permission boundary, so claude and codex skip their own
# prompts. opencode has no such flag; its permissions live in its config.
# codex needs --no-daemon since 0.157: its shared app-server records itself with
# /bin/ps, which is setuid, and the sandbox denies exec of setuid binaries
# (forbidden-exec-sugid), so startup fails with "failed to invoke ps".
if command -v safehouse >/dev/null 2>&1; then
  alias claude-unsafe='command claude'
  alias ccu='command claude'
  alias claude='claude-safe --dangerously-skip-permissions'
  alias cc='claude-safe --dangerously-skip-permissions'

  alias codex-unsafe='command codex'
  alias cou='command codex'
  _codex_exec() {
    codex-safe --dangerously-bypass-approvals-and-sandbox --no-daemon "$@"
  }

  alias opencode-unsafe='command opencode'
  alias ocu='command opencode'
  alias opencode='opencode-safe'
  alias oc='opencode-safe --port 0'
fi
