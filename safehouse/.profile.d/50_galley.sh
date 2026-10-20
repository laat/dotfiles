#!/bin/sh
# galley's reviews read npm's settings from this .npmrc in place of ~/.npmrc: the
# dependency install before a review gets the read-only token (setup/npm-readonly-token)
# for private packages, not the one that can publish. In the login profile, so the
# server sees it also when galley.app starts it (the app reads a login shell's env).
if [ -f "$HOME/.config/safehouse/npmrc" ]; then
  export GALLEY_NPMRC="$HOME/.config/safehouse/npmrc"
fi
