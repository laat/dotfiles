# Dotfiles

## Layout

This repo is organised as stow packages, one per topic (`git/`, `nvim/`, `zsh/`, `osx/`, ...). Topic-specific shell config — aliases, functions, env vars — lives in that topic's own `.shrc.d/` directory, e.g.:

- Git aliases → `git/.shrc.d/git.sh`
- Kubectl aliases → `k8s/.shrc.d/kubectl.sh`
- macOS-only aliases → `osx/.shrc.d/00_osx_aliases.sh`

`skel/.shrc.d/` is for generic, topic-less shell setup only (colours, `ll`, `..`). **Do not** put topic-specific aliases in `skel/` — they belong in the matching package so they're only present when that package is stowed.

When adding a new alias or function, locate the matching package first and edit its `.shrc.d/*.sh`. Only create a new file there if none exists for the topic.

## Stow

All stow commands must use `--no-folding` to avoid replacing real directories with symlinks.

```sh
stow --restow --no-folding <package>
```

Never run bare `stow <package>` without `--no-folding`.
