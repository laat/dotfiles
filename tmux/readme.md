# tmux

tmux plus [workmux](https://github.com/raine/workmux), which drives git
worktrees and tmux sessions as one unit. The two are bound together by
keybindings, hooks and helper scripts, so they ship as one package.

## Dependencies

```sh
brew install tmux sesh fzf
cargo install workmux
```

## Setup

```sh
stow --restow --no-folding tmux

# Install TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then inside tmux:

1. `C-a I` (capital I) — install plugins
2. `C-a r` — reload config

## Keybindings

| Key | Action |
|---|---|
| `C-a t` | Sesh session picker |
| `C-a r` | Reload config |
| `C-a \|` | Split horizontal |
| `C-a -` | Split vertical |
| `C-a c` | New window |
| `C-a T` | New workmux worktree (`wm-add`) |
| `C-a W` | Remove current workmux worktree (`wm-rm-window`) |

## workmux

- `.config/workmux/config.yaml` — global config; per-repo overrides in `.workmux.yaml`
- `.local/bin/wm-add` — `workmux add` after a fetch, so branches start at fresh `origin/HEAD`
- `.local/bin/wm-rm-window` — `workmux rm` for the worktree behind a tmux window, found from its panes' paths
- `.local/bin/tmux-close-lone-sidebar` — closes a sidebar left alone in its window
- `.shrc.d/00_workmux.sh` — `wm`, `wmd`, `wma`, `wmw`, `wms` aliases
- `cc-safe` agent in `config.yaml` — claude under sandbox-exec, see `safehouse/readme.md`
- `.zshrc.d/20_workmux.zsh` — zsh completions
