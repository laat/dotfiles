#!/bin/sh
# galley runs on nrkbeta, reached through its own Tailscale node, galley, with
# tailscale serve in front of 127.0.0.1:24823 there. The CLI and galley.app on every
# machine, nrkbeta included, use it; with GALLEY_URL set, nothing starts a local one.
export GALLEY_URL=https://galley.fluffy-mirfak.ts.net

# A galley server started on this machine reads npm's settings for its reviews from
# safehouse's read-only token (safehouse/setup/npm-readonly-token) in place of
# ~/.npmrc, where that token exists.
if [ -f "$HOME/.config/safehouse/npmrc" ]; then
  export GALLEY_NPMRC="$HOME/.config/safehouse/npmrc"
fi
