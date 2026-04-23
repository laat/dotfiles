# Dotfiles

## Stow

All stow commands must use `--no-folding` to avoid replacing real directories with symlinks.

```sh
stow --restow --no-folding <package>
```

Never run bare `stow <package>` without `--no-folding`.
