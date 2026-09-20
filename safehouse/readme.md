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
  (`~/.dotfiles` read-only for the stow symlinks, `~/.local/bin` read-only so
  hooks find `workmux`, `~/code` and `~/git` read-write because one session
  opens PRs in several repos, workmux state dirs, the statusline's usage
  cache, tmux socket, `TMUX`/`TMUX_PANE`, safehouse's `1password` feature so
  `op-ssh-sign` can sign commits)
- `.local/bin/{claude,codex,opencode}-safe` — symlinks to it, agent from the name
- `.config/safehouse/agents.sb` — appended policy: tmux socket allow, `.env` deny
- `.config/safehouse/npm.sb` — hides `~/.npmrc`; applied only when the read-only
  token file exists
- `setup/npm-readonly-token` — not stowed; creates a read-only npm granular
  token for the `@nrk` scope (`SCOPES=` for others; public packages need
  none) plus an optional `read:packages` GitHub PAT, in
  `~/.config/safehouse/npmrc`. From then on npm and pnpm in the sandbox use
  that file and cannot see `~/.npmrc`. Re-run to rotate
- `.shrc.d/99_safehouse.sh` — `claude`, `cc`, `codex`, `co`, `opencode`, `oc`
  become the sandboxed wrappers, with claude and codex skipping their own
  permission prompts; `<agent>-unsafe` (short: `ccu`, `cou`, `ocu`) runs the
  bare binary with prompts
- `roadmap.md` — planned hardening: read-only npm token, read-only cloud identity
- `.agents/skills/safehouse/` — agent-invoked skill: what safehouse is, where
  its files and docs are, how to read a denial. `.claude/skills/safehouse` is
  the symlink Claude Code needs

Policy files are write-denied inside the sandbox, so edit this package from
`claude-unsafe`.

workmux uses the same wrapper through the `cc-safe` agent in
`tmux/.config/workmux/config.yaml` (`wms`, or `agent: cc-safe` in a repo's
`.workmux.yaml`).
