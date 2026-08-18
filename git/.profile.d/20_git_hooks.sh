#!/bin/sh
# Neuter auto-installed git hook managers.
# lefthook: installed hook script exits immediately when LEFTHOOK=0
# (https://lefthook.dev/usage/envs/LEFTHOOK.html)
export LEFTHOOK=0
# husky: same idea, hook script no-ops when HUSKY=0
export HUSKY=0
