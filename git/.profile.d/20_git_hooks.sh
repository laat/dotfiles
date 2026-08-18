#!/bin/sh
# Neuter auto-installed git hook managers.
# Override per-invocation when you actually want hooks, e.g. LEFTHOOK=1 git commit

# lefthook: installed hook script exits immediately when LEFTHOOK=0
export LEFTHOOK=0
# husky: skips both `husky` install (prepare script) and the hook runner
export HUSKY=0
# simple-git-hooks: skip running hooks + skip postinstall
export SKIP_SIMPLE_GIT_HOOKS=1
export SKIP_INSTALL_SIMPLE_GIT_HOOKS=1
# overcommit (ruby)
export OVERCOMMIT_DISABLE=1

# pre-commit (python) has no global kill-switch, only SKIP=<hook-id,...>;
# use `git commit --no-verify` there.
