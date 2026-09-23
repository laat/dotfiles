# tmux

tmux plus [laatmux](https://github.com/laat/laatmux), which drives git
worktrees, coding agents and tmux sessions as one unit across hosts. The two
are bound together by keybindings and config, so they ship as one package.
The `workmux` branch of this repository has the workmux setup this replaced.

## Dependencies

```sh
brew install tmux sesh fzf
```

laatmux is built from its checkout; there is no release yet:

```sh
cd ~/code/laatmux && go build -ldflags "-X main.version=$(git describe --always)" -o ~/.local/bin/laatmux ./cmd/laatmux
```

Rerun the same command to upgrade. The local daemon is started by the first
command that needs it and keeps running; after an upgrade stop it so the next
command starts the new build: `kill $(jq .pid ~/.local/state/laatmux/runtime.json)`.
A remote host runs its own daemon from its own binary and config.

## Setup

```sh
stow --restow --no-folding tmux

# Install TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then inside tmux:

1. `C-b I` (capital I) — install plugins
2. `C-b r` — reload config

## Keybindings

| Key | Action |
|---|---|
| `C-b t` | Sesh session picker |
| `C-b r` | Reload config |
| `C-b \|` | Split horizontal (`laatmux split -h`: at the worktree root on its host in a workspace session) |
| `C-b -` | Split vertical (`laatmux split -v`) |
| `C-b c` | New window |
| `C-b C-t` | Toggle the laatmux sidebar on every window |
| `C-b C-s` | laatmux dashboard popup: Enter jumps, `a` adds, `x`/`X` removes, `s` settles, `S` shell |
| `C-b T` | New laatmux worktree for the repository of the current directory |

## laatmux

- `~/.config/laatmux/config.yaml` is personal and not in this repository:
  it names the known repositories. It holds the hosts with their `repos`
  and `worktrees` directories, the agents, the repository list and the
  sidebar; per-repo `copy` and `setup` steps live in the repository's
  committed `.laatmux.yaml`. The shape, with the paths this machine uses:

  ```yaml
  hosts:
    - name: mac
      repos: ~/code
      worktrees: ~/code/.worktrees
    - name: box
      ssh: box
      bin: ~/.local/bin/laatmux
      repos: ~/src
      worktrees: ~/src/worktrees
  tmux_servers: [laatmux, default]
  agents:
    claude:
      cmd: [claude]
    cc-safe:
      cmd: [claude-safe, --dangerously-skip-permissions]
  repos:
    - git@github.com:owner/repo.git
  sidebar:
    width: 35
    layout: tiles
  ```

- `.shrc.d/00_laatmux.sh` — `lm`, `lmd`, `lma`, `lms` aliases
- `cc-safe` agent in `config.yaml` — claude under sandbox-exec, see `safehouse/readme.md`

Worktrees stay under `~/code/.worktrees/<repo>/<branch>`, the layout workmux
used, so the ones it made are listed as they are.
