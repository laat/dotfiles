# Dotfiles

## Installation
```sh
stow --restow --no-folding stow
stow --restow --no-folding --stow skel

# then applications
stow --restow --no-folding --stow git emacs vim
```

## Skeleton (`skel`)

The `skel` package provides the base shell framework. Each shell sources a `.d` directory for modular config, so other stow packages can drop files in without editing the core rc files.

### Sourcing order

```
Login shell
├── .profile              → sources ~/.profile.d/*
│   └── .bash_profile     → sources .profile, then .bashrc (if interactive)
│
Interactive shell
├── .bashrc               → sources ~/.bashrc.d/*.bash, then .shrc
├── .zshrc                → sources ~/.zshrc.d/*.zsh, then .shrc
└── .shrc                 → sources ~/.shrc.d/* (POSIX-portable)
```

### Plugin directories

| Directory | Sourced by | Use for |
|---|---|---|
| `~/.profile.d/` | Login shells | PATH, env vars |
| `~/.bashrc.d/` | Bash (interactive) | Bash-specific config |
| `~/.zshrc.d/` | Zsh (interactive) | Zsh-specific config |
| `~/.shrc.d/` | All interactive shells | Portable aliases, functions |
| `~/.xprofile.d/` | X11 login | X-specific profile config |
| `~/.Xresources.d/` | X11 (`xrdb`) | X resources |

Files are numbered to control load order (e.g. `00_paths.sh`, `10_antidote.zsh`).

### Local overrides (not managed by git)

* `~/.profile.local`
* `~/.bashrc.local`
* `~/.zshrc.local`
* `~/.shrc.local`
* `~/.xprofile.local`
* `~/.gitconfig.local`
