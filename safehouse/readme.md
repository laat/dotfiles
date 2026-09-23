# safehouse

[agent-safehouse](https://agent-safehouse.dev/) runs coding agents under
macOS `sandbox-exec`: the worktree is read-write, toolchains and agent config
are readable, SSH keys, cloud credentials and the rest of `$HOME` are not.
Unlike a container sandbox it needs no Docker, keeps the keychain
(Claude login, `gh`), `~/.npmrc` and Homebrew tools working, and starts
instantly. It does not restrict the network and the agent can write git
hooks, so use a container for code you do not trust at all.

macOS only. Not in the default package list; stow it by hand.

```sh
brew install eugene1g/safehouse/agent-safehouse
dotfiles apply safehouse
```

## Files

- `.local/bin/safehouse-agent` — safehouse with the grants this setup needs
  (`~/.dotfiles` and any `~/.dotfiles-*` sibling repo read-only for the
  stow symlinks, `~/.local/bin` read-only so
  hooks find `laatmux`, `~/code` and `~/git` read-write because one session
  opens PRs in several repos, laatmux and workmux state dirs, the statusline's usage
  cache, tmux socket, `TMUX`/`TMUX_PANE`, safehouse's `1password` feature so
  `op-ssh-sign` can sign commits, its `shell-init` feature so interactive
  bash can read `~/.bashrc` without an error, its `clipboard` feature for
  `pbcopy`/`pbpaste`, git-tracked `.env` files
  readable, `GIT_SSH_COMMAND` so git over ssh authenticates through the
  1Password agent with its own connection instead of the host's
  pre-authenticated ControlMaster, mise shims appended to `PATH` so
  mise-only tools like `terraform` resolve once `~/bin` is hidden)
- `.local/bin/{claude,codex,opencode}-safe` — symlinks to it, agent from the name
- `.config/safehouse/agents.sb` — appended policy: tmux socket allow, the
  shell startup chain (`~/.shrc`, `~/.shrc.d`, `~/.profile.local` and the
  other `*.local` files) so aliases load inside, `*.local-secrets` deny
  (host tokens go in `~/.profile.local-secrets`, sourced from
  `~/.profile.local`), `.env` deny.
  The wrapper re-allows the `.env` files git tracks in the current repo,
  since a committed file is not a secret; gitignored ones stay hidden. A
  repo's `.safehouse` cannot do this itself because safehouse applies it
  before the CLI `--append-profile` files
- `.config/safehouse/npm.sb` — hides `~/.npmrc`; applied only when the read-only
  token file exists
- `setup/npm-readonly-token` — not stowed; creates a read-only npm granular
  token for the private scopes in `SCOPES=` (default in the script; public
  packages need none) plus an optional `read:packages` GitHub PAT, in
  `~/.config/safehouse/npmrc`. From then on npm and pnpm in the sandbox use
  that file and cannot see `~/.npmrc`. Re-run to rotate. Needs npm 11.7 or
  newer for the granular-token flags
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

laatmux uses the same wrapper through the `cc-safe` agent in
`tmux/.config/laatmux/config.yaml` (`lms`, `laatmux add --agent cc-safe`, or
the agent picker in the dashboard).
