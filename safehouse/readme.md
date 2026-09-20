# safehouse

[agent-safehouse](https://agent-safehouse.dev/) runs coding agents under
macOS `sandbox-exec`: the worktree is read-write, toolchains and agent config
are readable, SSH keys, cloud credentials and the rest of `$HOME` are not.
Unlike workmux's container sandbox it needs no Docker, keeps the keychain
(Claude login, `gh`), `~/.npmrc` and Homebrew tools working, and starts
instantly. It does not restrict the network and the agent can write git
hooks, so use `workmux add -S` for code you do not trust at all.

macOS only. Not in the default package list; stow it by hand.

```sh
brew install eugene1g/safehouse/agent-safehouse
dotfiles apply safehouse
```

## Files

- `.local/bin/safehouse-agent` — safehouse with the grants this setup needs
  (`~/.dotfiles` read-only for the stow symlinks, workmux state dirs, tmux
  socket, `TMUX`/`TMUX_PANE`)
- `.local/bin/{claude,codex,opencode}-safe` — symlinks to it, agent from the name
- `.config/safehouse/agents.sb` — appended policy: tmux socket allow, `.env` deny
- `.shrc.d/99_safehouse.sh` — `claude`, `cc`, `codex`, `co`, `opencode`, `oc`
  become the sandboxed wrappers, with claude and codex skipping their own
  permission prompts; `<agent>-unsafe` runs the bare binary with prompts
- `roadmap.md` — planned hardening: read-only npm token, read-only cloud identity
- `.agents/skills/safehouse/` — agent-invoked skill: what safehouse is, where
  its files and docs are, how to read a denial. `.claude/skills/safehouse` is
  the symlink Claude Code needs

Policy files are write-denied inside the sandbox, so edit this package from
`claude-unsafe`.

workmux uses the same wrapper through the `cc-safe` agent in
`tmux/.config/workmux/config.yaml` (`wms`, or `agent: cc-safe` in a repo's
`.workmux.yaml`).
