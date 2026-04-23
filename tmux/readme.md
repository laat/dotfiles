# tmux

## Dependencies

```sh
brew install tmux sesh fzf
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
