#!/bin/sh
if [ -x "$HOME/.local/bin/mise" ]; then
  export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
fi
