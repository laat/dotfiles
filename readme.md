# Dotfiles

## Installation
```sh
stow --restow --no-folding stow
stow --restow --no-folding --stow skel

# then applications
stow --restow --no-folding --stow git emacs vim
```

## Skeleton(s)

I have decided to provide "plugin" support in my dotfiles.

Folders:

* `~/.profile.d` files sourced by login shells.
* `~/.bashrc.d` bash specific configurations sourced when bash is interactive
* `~/.shrc.d` shell agnostic configurations sourced when the shell is interactive
* `~/.zshrc.d` zsh specific configurations shourced when zsh is interactive
* `~/.xprofile.d` X specific profile configurations.
* `~/.Xresouces.d` X resources merged by `xrdb` in `.xprofile`

Machine specific files (not managed by git):

* `.bashrc.local` interactive bash
* `.zshrc.local` interactive zsh
* `.xprofile.local` X11 profile
* `.gitconfig.local` git
sign this
sign this
sign this
sign this
sign this
sign this2
sign this2
sign this2
