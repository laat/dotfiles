# tmux

tmux plus [laatmux](https://github.com/laat/laatmux), which drives git
worktrees, coding agents and tmux sessions as one unit across hosts. The two
are bound together by keybindings and config, so they ship as one package.
The `workmux` branch of this repository has the workmux setup this replaced.

## Dependencies

```sh
brew install tmux sesh fzf
```

laatmux is built from its checkout; there is no release yet. The installed
binary builds, installs and restarts the daemon per host:

```sh
cd ~/code/laatmux && go build -o ~/.local/bin/laatmux ./cmd/laatmux   # first time only
~/.local/bin/laatmux upgrade mac vm                                     # from the checkout, later
```

`upgrade` builds for each host's platform, installs over ssh for a remote one
and restarts its daemon; `laatmux hosts` marks daemons that differ from the
binary. Run it as `~/.local/bin/laatmux`, not `go run`: the latter would
install into Go's build cache. The local daemon is started by the first
command that needs it; `laatmux stop` ends it.

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
| `C-b C-s` | laatmux dashboard popup: Enter jumps, `Tab` switches agent/tree view, `v` layout, `/` filter, `1`..`9` jump to the nth row, `s` folds, `z` settles, `a` opens the task form, `x`/`X` removes, `S` shell; on a task's row `p` delivers its prompt, `x` dismisses it |
| `C-b T` | laatmux task form: repository, host, agent, prompt, branch; the add runs in the background and shows as a row until its worktree takes over |
| `C-b S` | laatmux shell: a window at the worktree root on its host in the workspace session, selected again on a second press |
| `C-b W` | Remove the workspace this session is: its worktree, managed session and this session, after a confirm |

The sidebar pane takes the same keys as the dashboard (`j`/`k`, `Tab`, `v`,
`/`, `s`, `z`, `F` cycles the scope all/session/project, `q` closes the pane);
`laatmux sidebar next | prev | jump N | view | scope` drive it from a binding.

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
  default_agent: claude
  copy: ["**/.envrc.cache.enc"]
  repos:
    - git@github.com:owner/repo.git
  sidebar:
    width: 35
    layout: tiles
  ```

- `.shrc.d/00_laatmux.sh` — `lm`, `lmd`, `lma`, `lms`, `lmt` aliases
- `cc-safe` agent in `config.yaml` — claude under sandbox-exec, see `safehouse/readme.md`

Worktrees stay under `~/code/.worktrees/<repo>/<branch>`, the layout workmux
used, so the ones it made are listed as they are.
